<#
.SYNOPSIS
    Build the V6C toolchain and produce a release .zip end to end.

.DESCRIPTION
    Local mirror of the GitHub Actions release workflow:
        1. Sync the llvm-project mirror (scripts/sync_llvm_mirror.ps1).
        2. Configure llvm-build via cmake (Ninja, Release).
        3. Build clang, lld, llc, llvm-* tools.
        4. Run tests/run_all.py as a release gate (skip with -SkipTests).
        5. Stage and zip via scripts/make_dist.ps1.
        6. Smoke-test the staged tree via scripts/validate_dist.ps1.

    Must be run from a developer shell with MSVC env activated (or the
    -InvokeVsDevCmd switch will activate it inline). Requires cmake, ninja,
    python on PATH.

.PARAMETER Version
    Version string for the archive name. Defaults to today's UTC date
    formatted as YYYY.MM.DD.

.PARAMETER SkipTests
    Skip tests/run_all.py. Use only for local iteration.

.PARAMETER SkipBuild
    Skip cmake configure + ninja build (use existing llvm-build/).

.EXAMPLE
    pwsh scripts/build_release.ps1
    pwsh scripts/build_release.ps1 -Version 2026.04.27 -SkipTests
#>
[CmdletBinding()]
param(
    [string]$Version,
    [switch]$SkipTests,
    [switch]$SkipBuild
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$repoRoot = Split-Path -Parent $PSScriptRoot
Set-Location $repoRoot

if (-not $Version) {
    $Version = (Get-Date).ToUniversalTime().ToString('yyyy.MM.dd')
}
Write-Host "Release version: $Version"

$BuildDir = Join-Path $repoRoot 'llvm-build'

if (-not $SkipBuild) {
    Write-Host '--- Sync llvm-project mirror ---'
    & (Join-Path $PSScriptRoot 'sync_llvm_mirror.ps1')

    Write-Host '--- CMake configure ---'
    cmake -G Ninja `
          -S (Join-Path $repoRoot 'llvm-project\llvm') `
          -B $BuildDir `
          -DCMAKE_BUILD_TYPE=Release `
          -DLLVM_TARGETS_TO_BUILD=X86 `
          -DLLVM_EXPERIMENTAL_TARGETS_TO_BUILD=V6C `
          '-DLLVM_ENABLE_PROJECTS=clang;lld'
    if ($LASTEXITCODE -ne 0) { throw 'cmake configure failed' }

    Write-Host '--- Ninja build ---'
    ninja -C $BuildDir `
        clang lld llc `
        llvm-objcopy llvm-readelf llvm-objdump llvm-ar llvm-mc llvm-nm `
        FileCheck not llvm-lit
    if ($LASTEXITCODE -ne 0) { throw 'ninja build failed' }

    # crt0.o is not built by ninja (compiler-rt is not configured for i8080).
    # Assemble it now using the just-built clang so the dev tree, tests, and
    # downstream make_dist.ps1 all see an up-to-date object next to crt0.s.
    Write-Host '--- Assemble V6C runtime (crt0.o) ---'
    & (Join-Path $PSScriptRoot 'build_v6c_runtime.ps1') -BuildDir $BuildDir
    if ($LASTEXITCODE -ne 0) { throw 'build_v6c_runtime.ps1 failed' }
}

if (-not $SkipTests) {
    Write-Host '--- Test gate (tests/run_all.py) ---'
    python (Join-Path $repoRoot 'tests\run_all.py')
    if ($LASTEXITCODE -ne 0) { throw 'tests/run_all.py FAILED -- aborting release' }
}

Write-Host '--- Stage + package ---'
& (Join-Path $PSScriptRoot 'make_dist.ps1') -Version $Version

$Stage = Join-Path $repoRoot "dist\v6c-$Version-windows-x64"

Write-Host '--- Smoke test staged tree ---'
& (Join-Path $PSScriptRoot 'validate_dist.ps1') -Stage $Stage

Write-Host ''
Write-Host "Release artifact: dist\v6c-$Version-windows-x64.zip"
