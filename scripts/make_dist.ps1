<#
.SYNOPSIS
    Stage and package a V6C distributable for Windows x64.

.DESCRIPTION
    Builds a self-contained release tree from an existing llvm-build/ tree
    and packages it as a single .zip. The staged layout matches the
    "Installed" search branches of the clang V6C driver
    (clang/lib/Driver/ToolChains/V6C.cpp), so the shipped clang.exe locates
    v6c.ld, crt0.o, and the runtime builtins via its ResourceDir.

    Layout produced:
      v6c-<ver>-windows-x64/
        bin/                              # clang, lld, llc, llvm-*, v6asm, v6emul
        lib/clang/<llvm-ver>/v6c/v6c.ld
        lib/clang/<llvm-ver>/lib/v6c/{crt0,mulhi3,mulsi3,udivhi3,
                                       divhi3,shift,memory}.o
        lib/clang/<llvm-ver>/lib/v6c/include/   (placeholder)
        share/v6c/samples/                # curated .c samples
        share/v6c/docs/                   # docs/ tree
        LICENSE
        README.md

.PARAMETER Version
    Version string embedded in the archive name (e.g. "2026.04.27").

.PARAMETER BuildDir
    Path to the existing llvm-build/ tree. Default: <repo>/llvm-build.

.PARAMETER OutDir
    Output directory for the staged tree and the .zip. Default: <repo>/dist.

.EXAMPLE
    pwsh scripts/make_dist.ps1 -Version 2026.04.27
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Version,

    [string]$BuildDir,
    [string]$OutDir
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$repoRoot = Split-Path -Parent $PSScriptRoot
if (-not $BuildDir) { $BuildDir = Join-Path $repoRoot 'llvm-build' }
if (-not $OutDir)   { $OutDir   = Join-Path $repoRoot 'dist' }

$BuildBin = Join-Path $BuildDir 'bin'
if (-not (Test-Path $BuildBin)) {
    throw "Build bin directory not found: $BuildBin (run a Release build first)"
}

$Clang = Join-Path $BuildBin 'clang.exe'
if (-not (Test-Path $Clang)) {
    throw "clang.exe not found in $BuildBin"
}

# Discover the clang resource-dir version segment (e.g. "18" or "18.1.0")
# so the staged layout matches what clang.exe will look up at runtime.
$resDir = & $Clang -print-resource-dir
if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($resDir)) {
    throw 'Failed to query clang -print-resource-dir'
}
$resDir = $resDir.Trim()
$ClangVer = Split-Path -Leaf $resDir
Write-Host "Clang resource-dir version: $ClangVer"

$DistName = "v6c-$Version-windows-x64"
$Stage    = Join-Path $OutDir $DistName

if (Test-Path $Stage) {
    Write-Host "Removing previous stage: $Stage"
    Remove-Item $Stage -Recurse -Force
}
New-Item -ItemType Directory -Force -Path $Stage | Out-Null

# ---------------------------------------------------------------- bin/
$StageBin = Join-Path $Stage 'bin'
New-Item -ItemType Directory -Force -Path $StageBin | Out-Null

$LlvmExes = @(
    'clang.exe', 'clang++.exe',
    'lld.exe', 'ld.lld.exe',
    'llc.exe',
    'llvm-objcopy.exe', 'llvm-readelf.exe', 'llvm-objdump.exe',
    'llvm-ar.exe', 'llvm-mc.exe', 'llvm-nm.exe'
)
foreach ($exe in $LlvmExes) {
    $src = Join-Path $BuildBin $exe
    if (Test-Path $src) {
        Copy-Item $src -Destination $StageBin
    } else {
        Write-Warning "Skipping missing binary: $exe"
    }
}

# Pre-built reference tools (v6asm + v6emul + v6fdd ship as-is)
$ToolsCopies = @(
    @{ Src = 'tools\v6asm\v6asm.exe';  Dst = 'v6asm.exe'  },
    @{ Src = 'tools\v6asm\v6fdd.exe';  Dst = 'v6fdd.exe'  },
    @{ Src = 'tools\v6emul\v6emul.exe'; Dst = 'v6emul.exe' }
)
foreach ($c in $ToolsCopies) {
    $src = Join-Path $repoRoot $c.Src
    if (Test-Path $src) {
        Copy-Item $src -Destination (Join-Path $StageBin $c.Dst)
    } else {
        Write-Warning "Skipping missing tool: $($c.Src)"
    }
}

# ------------------------------------------- lib/clang/<ver>/v6c/v6c.ld
$StageDriverDir = Join-Path $Stage "lib\clang\$ClangVer\v6c"
New-Item -ItemType Directory -Force -Path $StageDriverDir | Out-Null
Copy-Item (Join-Path $repoRoot 'clang\lib\Driver\ToolChains\V6C\v6c.ld') `
    -Destination (Join-Path $StageDriverDir 'v6c.ld')

# ------------------------- lib/clang/<ver>/include  (freestanding headers)
# Clang resolves <stdint.h>, <stddef.h>, etc. from <ResourceDir>/include.
$BuildResInclude = Join-Path $BuildDir "lib\clang\$ClangVer\include"
$StageResInclude = Join-Path $Stage    "lib\clang\$ClangVer\include"
if (Test-Path $BuildResInclude) {
    New-Item -ItemType Directory -Force -Path $StageResInclude | Out-Null
    Copy-Item -Recurse (Join-Path $BuildResInclude '*') -Destination $StageResInclude
} else {
    Write-Warning "Clang freestanding headers not found at $BuildResInclude"
}

# ----------------------- lib/clang/<ver>/lib/v6c/{*.o, include/}
$StageRtDir      = Join-Path $Stage "lib\clang\$ClangVer\lib\v6c"
$StageRtIncDir   = Join-Path $StageRtDir 'include'
New-Item -ItemType Directory -Force -Path $StageRtDir    | Out-Null
New-Item -ItemType Directory -Force -Path $StageRtIncDir | Out-Null

$RtSrcDir = Join-Path $repoRoot 'compiler-rt\lib\builtins\v6c'
# O80: all integer-math and mem* helpers are now header-only inline-asm
# routines emitted per-TU. Only crt0 still needs to ship as an object.
# crt0.o is produced out-of-band by scripts/build_v6c_runtime.ps1 (which
# build_release.ps1 invokes right after ninja). make_dist.ps1 itself just
# copies the prebuilt object — building it here would mask a broken or
# missing runtime build step.
$RtObjects = @('crt0.o')

foreach ($o in $RtObjects) {
    $srcPath = Join-Path $RtSrcDir $o
    if (-not (Test-Path $srcPath)) {
        throw "V6C runtime object '$o' not found at $srcPath. " +
              "Run scripts/build_v6c_runtime.ps1 first " +
              "(it is invoked automatically by scripts/build_release.ps1)."
    }
    $dstPath = Join-Path $StageRtDir $o
    Write-Host "Copying runtime $o"
    Copy-Item -Force $srcPath -Destination $dstPath
}

# O80: ship the header-only V6C runtime (v6c_arith.h, v6c_rt_macros.h,
# string.h, ...). The driver's findV6CRuntimeIncludeDir looks for these
# under <ResourceDir>/lib/v6c/include.
$RtIncSrcDir = Join-Path $RtSrcDir 'include'
if (Test-Path $RtIncSrcDir) {
    Copy-Item -Recurse -Force (Join-Path $RtIncSrcDir '*') -Destination $StageRtIncDir
} else {
    Write-Warning "V6C runtime include dir not found at $RtIncSrcDir"
}

# ---------------------------------------------------- share/v6c/samples
$StageSamples = Join-Path $Stage 'share\v6c\samples'
New-Item -ItemType Directory -Force -Path $StageSamples | Out-Null

$SampleSources = @(
    'tests\features\o_lld_bsort.c'
)
foreach ($f in $SampleSources) {
    $src = Join-Path $repoRoot $f
    if (Test-Path $src) {
        Copy-Item $src -Destination $StageSamples
    }
}

# Hello sample (synthesized so the dist always contains a trivial example).
$Hello = @'
// hello.c -- minimal V6C ROM. Build with:
//   clang -target i8080-unknown-v6c -O2 hello.c -o hello.rom
// Run in the bundled emulator:
//   v6emul --rom hello.rom --load-addr 0x0100 --halt-exit --dump-cpu
#include <stdint.h>

int main(void) {
    __builtin_v6c_out(0xED, 0x42);  // emit 0x42 on debug port
    __builtin_v6c_hlt();
    return 0;
}
'@
$Hello | Set-Content -Path (Join-Path $StageSamples 'hello.c') -NoNewline

# ------------------------------------------------------- share/v6c/docs
$StageDocs = Join-Path $Stage 'share\v6c\docs'
New-Item -ItemType Directory -Force -Path $StageDocs | Out-Null
Copy-Item -Recurse (Join-Path $repoRoot 'docs\*') -Destination $StageDocs

# Top-level files
Copy-Item (Join-Path $repoRoot 'LICENSE')   -Destination $Stage
Copy-Item (Join-Path $repoRoot 'README.md') -Destination $Stage

# ---------------------------------------------------------------- pack
$ZipPath = Join-Path $OutDir "$DistName.zip"
if (Test-Path $ZipPath) { Remove-Item $ZipPath -Force }
Write-Host "Packing $ZipPath ..."
Compress-Archive -Path (Join-Path $Stage '*') -DestinationPath $ZipPath -CompressionLevel Optimal

$zipBytes = (Get-Item $ZipPath).Length
$zipMB    = [Math]::Round($zipBytes / 1MB, 1)
Write-Host ""
Write-Host "Done."
Write-Host "  Stage : $Stage"
Write-Host "  Zip   : $ZipPath ($zipMB MB)"
