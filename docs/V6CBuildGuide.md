# V6C Build Guide

## Prerequisites

- CMake ≥ 3.20
- Ninja build system
- C++17 compiler (GCC 11+, Clang 14+, or MSVC 2022+)
- Python 3.8+ (for test runner)

## Tool Dependencies

| Tool | Location | Purpose |
|------|----------|---------|
| LLVM | `llvm-project/` (pinned `llvmorg-18.1.0`) | Compiler infrastructure (gitignored, build source) |
| v6emul | `tools/v6emul/` | CLI Vector 06c emulator — execution, register/memory inspection, cycle counting |
| v6asm | `tools/v6asm/` | CLI 8080 assembler — reference assembly, ASM→ROM conversion |
| CMake ≥ 3.20 | System | Build system |
| Ninja | System | Build executor |
| Python 3 | System | Test runner |

## Build LLVM with V6C Target

```bash
# From the project root (using MSVC on Windows)
cmake -G Ninja -S llvm-project\llvm -B llvm-build ^
  -DCMAKE_BUILD_TYPE=Release ^
  -DLLVM_TARGETS_TO_BUILD=X86 ^
  -DLLVM_EXPERIMENTAL_TARGETS_TO_BUILD=V6C

ninja -C llvm-build llc llvm-tblgen
```

Verify the target is registered:

```bash
llvm-build/bin/llc --version
# Should list: v6c    - Vector 06c (Intel 8080)
```

## Syncing the Mirror

`llvm-project/` is a large cloned repo (pinned to `llvmorg-18.1.0`) and is **gitignored**.
All V6C source code is git-tracked under `llvm/`, which serves as a mirror.

After every successful build (or any edit to files inside `llvm-project/`), run:

```powershell
powershell -ExecutionPolicy Bypass -File scripts\sync_llvm_mirror.ps1
```

The script handles two categories:

1. **V6C target directory** (`llvm-project/llvm/lib/Target/V6C/` → `llvm/lib/Target/V6C/`) — full directory mirror via `robocopy /MIR`.
2. **Modified upstream LLVM files** (e.g. `Triple.h`, `Triple.cpp`) — individual file copies via `xcopy`.

When a new milestone modifies additional upstream files, add `xcopy` lines to `scripts\sync_llvm_mirror.ps1`.

> **Important**: If `llvm-project/` is re-cloned from scratch, the mirror under `llvm/` is the
> authoritative source. Copy files back from `llvm/` into `llvm-project/` before building.

## Running Tests

```bash
# Golden test suite (emulator trust baseline)
python tests/run_golden_tests.py

# With verbose output
python tests/run_golden_tests.py -v
```

## Using llc for Assembly Output

Once built, `llc` can compile LLVM IR to 8080 assembly:

```bash
# Emit assembly to stdout
llvm-build/bin/llc -march=v6c -o - input.ll

# Emit assembly to file
llvm-build/bin/llc -march=v6c -o output.s input.ll
```

Example trivial IR (`trivial.ll`):
```llvm
target datalayout = "e-p:16:8-i1:8-i8:8-i16:8-i32:8-i64:8-n8:16-S8"
target triple = "i8080-unknown-v6c"

define void @empty() {
  ret void
}
```

Running `llc -march=v6c -o - trivial.ll` produces:
```asm
        .text
        .globl  empty
empty:
        RET
```
