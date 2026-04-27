<#
.SYNOPSIS
    Smoke-test a staged V6C distributable.

.DESCRIPTION
    Compiles a tiny C program with the staged clang.exe (no -nostartfiles,
    no -T override, no --defsym workaround), runs it through the staged
    v6emul.exe, and asserts the expected output. This proves clang
    resolves v6c.ld + crt0.o + freestanding headers via the "Installed"
    branch of its driver lookup (ResourceDir-relative), not the dev-tree
    fallback, AND that crt0 auto-linkage delivers a working _start that
    calls main.

.PARAMETER Stage
    Path to the staged distribution root (the directory containing bin/).
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Stage
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$Clang  = Join-Path $Stage 'bin\clang.exe'
$Emul   = Join-Path $Stage 'bin\v6emul.exe'
foreach ($p in @($Clang, $Emul)) {
    if (-not (Test-Path $p)) { throw "Missing in stage: $p" }
}

$Tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("v6c-dist-smoke-" + [guid]::NewGuid())
New-Item -ItemType Directory -Force -Path $Tmp | Out-Null
try {
    $Src = Join-Path $Tmp 'smoke.c'
    @'
#include <stdint.h>
int main(void) {
    __builtin_v6c_out(0xED, 0x42);
    __builtin_v6c_hlt();
    return 0;
}
'@ | Set-Content -Path $Src -NoNewline

    $Rom = Join-Path $Tmp 'smoke.rom'

    # Full default flow: clang locates v6c.ld + crt0.o entirely via
    # ResourceDir, ld.lld links, llvm-objcopy emits the flat ROM.
    Write-Host "Compiling smoke.c with staged clang ..."
    & $Clang --target=i8080-unknown-v6c -O2 $Src -o $Rom
    if ($LASTEXITCODE -ne 0) { throw 'Staged clang failed to compile smoke.c' }
    if (-not (Test-Path $Rom)) { throw 'Staged clang did not produce smoke.rom' }

    Write-Host "Running smoke.rom in staged v6emul ..."
    $out = & $Emul --rom $Rom --load-addr 0x0100 --halt-exit --dump-cpu 2>&1 | Out-String
    Write-Host $out

    if ($out -notmatch 'TEST_OUT\s+port=0xED\s+value=0x42') {
        throw "Smoke test failed: expected TEST_OUT port=0xED value=0x42 in emulator output"
    }
    if ($out -notmatch 'HALT') {
        throw 'Smoke test failed: emulator did not reach HALT'
    }
    # crt0 sets SP = __stack_top (0x0000); first CALL into main wraps to 0xFFFE.
    # If crt0 did not run, SP would still be 0x0000 at HALT.
    if ($out -notmatch 'SP=FFFE') {
        throw 'Smoke test failed: SP not at 0xFFFE; crt0 did not initialize stack'
    }

    # Sanity-check that v6c.ld and crt0.o are actually present where
    # clang expects them via -print-resource-dir.
    $resDir = (& $Clang -print-resource-dir).Trim()
    $expectedScript = Join-Path $resDir 'v6c\v6c.ld'
    $expectedCrt0   = Join-Path $resDir 'lib\v6c\crt0.o'
    if (-not (Test-Path $expectedScript)) {
        throw "Linker script not at expected install path: $expectedScript"
    }
    if (-not (Test-Path $expectedCrt0)) {
        throw "crt0.o not at expected install path: $expectedCrt0"
    }

    Write-Host ''
    Write-Host 'Smoke test PASSED.'
}
finally {
    Remove-Item -Recurse -Force $Tmp -ErrorAction SilentlyContinue
}
