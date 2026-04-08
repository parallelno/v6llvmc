# V6C LLVM Backend — Overview

## Project Goals

This project implements an LLVM backend targeting the **Vector 06c** home computer,
which uses an **Intel 8080**-compatible CPU (KR580VM80A) running at 3 MHz with
64 KB of RAM.

The goal is a complete C compilation pipeline:
**C source → Clang → LLVM IR → V6C backend → flat binary → Vector 06c**

## Target Architecture

| Property | Value |
|----------|-------|
| CPU | Intel 8080 (KR580VM80A) |
| Clock | 3 MHz |
| Memory | 64 KB flat address space |
| Endianness | Little-endian |
| Word size | 8-bit ALU, 16-bit address bus |
| Registers | A, B, C, D, E, H, L (8-bit); BC, DE, HL, SP (16-bit pairs) |
| Stack | Grows downward, full-descending |

### Data Layout

```
e-p:16:8-i1:8-i8:8-i16:8-i32:8-i64:8-n8:16-S8
```

- Pointers are 16-bit, byte-aligned
- Native integer widths: 8 and 16 bits
- No hardware alignment requirements

### Default Memory Map

```
0x0000 ┌──────────────────┐
       │  (reserved/ROM)  │
0x0100 ├──────────────────┤  ← Default start address
       │  .text           │
       │  .rodata         │
       │  .data           │
       │  .bss            │
       │  (heap ↑)        │
       │       ...        │
       │  (stack ↓)       │
0xFFFF └──────────────────┘
```

## Tool Dependencies

| Tool | Location | Purpose |
|------|----------|---------|
| LLVM | `llvm/` (pinned release) | Compiler infrastructure |
| v6emul | `tools/v6emul/` | CLI Vector 06c emulator — execution, register/memory inspection, cycle counting |
| v6asm | `tools/v6asm/` | CLI 8080 assembler — reference assembly, ASM→ROM conversion |
| CMake ≥ 3.20 | System | Build system |
| Ninja | System | Build executor |
| Python 3 | System | Test runner |

## Building

### Prerequisites

- CMake ≥ 3.20
- Ninja build system
- C++17 compiler (GCC 11+, Clang 14+, or MSVC 2022+)
- Python 3.8+ (for test runner)

### Build LLVM with V6C Target

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

### Running Tests

```bash
# Golden test suite (emulator trust baseline)
python tests/run_golden_tests.py

# With verbose output
python tests/run_golden_tests.py -v
```

## Project Structure

```
v6llvmc/
├── llvm/lib/Target/V6C/          # LLVM backend source
│   ├── CMakeLists.txt            # Build configuration
│   ├── V6C.td                    # Top-level TableGen
│   ├── MCTargetDesc/             # MC layer (assembly/binary emission)
│   └── TargetInfo/               # Target registration
├── clang/lib/Basic/Targets/      # Clang frontend integration
├── compiler-rt/lib/builtins/v6c/ # Runtime library
├── lld/V6C/                      # Linker
├── tests/
│   ├── golden/                   # Emulator trust baseline (15 programs)
│   ├── lit/                      # LLVM FileCheck tests
│   ├── unit/                     # Standalone C unit tests
│   ├── integration/              # End-to-end C→binary→emulator tests
│   ├── runtime/                  # Runtime library standalone tests
│   └── benchmarks/               # Performance measurements
├── docs/                         # Documentation
├── tools/
│   ├── v6asm/                    # 8080 assembler
│   └── v6emul/                   # Vector 06c emulator
└── design/                       # Design & implementation plan
```

## Current Status

- **M0 (Project Bootstrap)**: Complete
  - v6emul and v6asm validated
  - Golden test suite: 15 tests, all passing
  - Project directory structure created
- **M1 (Target Registration & Skeleton)**: Complete
  - `i8080` architecture added to LLVM Triple
  - V6C registered as experimental target (`llc -march=v6c` works)
  - V6CTargetMachine, V6CSubtarget, MCTargetDesc implemented
  - Data layout: `e-p:16:8-i1:8-i8:8-i16:8-i32:8-i64:8-n8:16-S8`
  - TableGen processes V6C.td (minimal registers + NOP instruction)
- **M2 (TableGen: Registers & Core Instructions)**: Complete
  - All 8080 registers defined: A, B, C, D, E, H, L, FLAGS, SP + pairs BC, DE, HL, PSW
  - 9 register classes: GR8, GR8NoA, Acc, GR16, GR16Ptr, GR16Idx, GR16SP, GR16All, FlagReg
  - Complete 8080 instruction set (80+ instructions) with correct encoding formats
  - Scheduling model: in-order, single-issue, 11 SchedWrite resources with cycle costs
  - V6CRegisterInfo, V6CInstrInfo, V6CFrameLowering implemented
  - All 154 instruction encodings validated against v6asm reference output

## References

- [Design Document](../design/design.md) — authoritative architecture specification
- [Implementation Plan](../design/plan.md) — milestone-driven development sequence
- [Golden Tests](../tests/golden/README.md) — emulator trust baseline
