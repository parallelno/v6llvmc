<#
.SYNOPSIS
    Build the V6C toolchain: sync mirror, cmake configure, ninja, crt0.o, tests.

.DESCRIPTION
    Day-to-day build script. Activates the MSVC toolchain environment on
    Windows automatically (no Developer Shell required). Requires cmake,
    ninja, python on PATH.

    For cutting a release (packaging + git tag + push), use scripts/publish.ps1.

.PARAMETER SkipTests
    Skip tests/run_all.py. Use for rapid iteration.

.PARAMETER SkipBuild
    Skip cmake configure + ninja build (reuse existing llvm-build/).

.PARAMETER V6AsmPath
    Path to the separately installed v6asm executable. Overrides V6ASM.

.PARAMETER V6EmulPath
    Path to the separately installed v6emul executable. Overrides V6EMUL.

.EXAMPLE
    pwsh scripts\build.ps1
    pwsh scripts\build.ps1 -SkipTests
    pwsh scripts\build.ps1 -SkipBuild
#>
[CmdletBinding()]
param(
    [switch]$SkipTests,
    [switch]$SkipBuild,
    [string]$V6AsmPath,
    [string]$V6EmulPath
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# On Windows, activate the MSVC toolchain environment if not already active.
# Use Test-Path instead of $IsWindows so this works on both PS 5.1 and PS Core.
$vsDevCmd = 'C:\Program Files\Microsoft Visual Studio\2022\Community\Common7\Tools\VsDevCmd.bat'
if (-not $env:VCINSTALLDIR -and (Test-Path $vsDevCmd)) {
    $envDump = cmd /c "`"$vsDevCmd`" -arch=amd64 >nul 2>&1 && set"
    foreach ($line in $envDump) {
        if ($line -match '^([^=]+)=(.*)$') {
            [System.Environment]::SetEnvironmentVariable($Matches[1], $Matches[2], 'Process')
        }
    }
    Write-Host '--- MSVC environment activated ---'
}

$repoRoot = Split-Path -Parent $PSScriptRoot
Set-Location $repoRoot

$BuildDir = Join-Path $repoRoot 'llvm-build'

if ($V6AsmPath) {
    $env:V6ASM = $V6AsmPath
}
if ($V6EmulPath) {
    $env:V6EMUL = $V6EmulPath
}

if (-not $SkipTests) {
    $requiredTools = @(
        @{ Name = 'V6ASM'; Value = $env:V6ASM; Parameter = '-V6AsmPath' },
        @{ Name = 'V6EMUL'; Value = $env:V6EMUL; Parameter = '-V6EmulPath' },
        @{ Name = 'C8080'; Value = $env:C8080; Parameter = '' }
    )
    foreach ($tool in $requiredTools) {
        if (-not $tool.Value) {
            $override = if ($tool.Parameter) { " or pass $($tool.Parameter)" } else { '' }
            throw "$($tool.Name) is required to run the full test suite. Set it to the separately installed executable$override."
        }
        if (-not (Test-Path -LiteralPath $tool.Value -PathType Leaf)) {
            throw "Tool not found at $($tool.Name): $($tool.Value)"
        }
    }
}

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
        FileCheck not
    if ($LASTEXITCODE -ne 0) { throw 'ninja build failed' }

    # crt0.o is not built by ninja (compiler-rt is not configured for i8080).
    # Assemble it now using the just-built clang so the dev tree, tests, and
    # downstream make_dist.ps1 all see an up-to-date object next to crt0.s.
    Write-Host '--- Assemble V6C runtime (crt0.o) ---'
    & (Join-Path $PSScriptRoot 'build_v6c_runtime.ps1') -BuildDir $BuildDir
    if ($LASTEXITCODE -ne 0) { throw 'build_v6c_runtime.ps1 failed' }
}

if (-not $SkipTests) {
    Write-Host '--- Tests ---'
    python (Join-Path $repoRoot 'tests\run_all.py')
    if ($LASTEXITCODE -ne 0) { throw 'tests/run_all.py FAILED' }
}
