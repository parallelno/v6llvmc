# V6C LLVM Backend — Documentation

An LLVM backend targeting the **Vector 06c** home computer (Intel 8080 / KR580VM80A, 3 MHz, 64 KB RAM).

Goal: **C source → Clang → LLVM IR → V6C backend → flat binary → Vector 06c**

## Table of Contents

### Getting Started

| Document | Description |
|----------|-------------|
| [V6CBuildGuide.md](V6CBuildGuide.md) | Prerequisites, build commands, mirror sync workflow, running tests |
| [V6CProjectStructure.md](V6CProjectStructure.md) | Directory layout and key paths |

### Architecture & Design

| Document | Description |
|----------|-------------|
| [V6CArchitecture.md](V6CArchitecture.md) | Target CPU, data layout, memory map |
| [V6CInstructionTimings.md](V6CInstructionTimings.md) | Intel 8080 instruction cycle costs, TableGen `SchedWriteRes` cross-reference |
| [V6CIPRA.md](V6CIPRA.md) | Interprocedural Register Allocation on V6C, default behavior, safety model, and disable flags |
| [V6CStaticStackAlloc.md](V6CStaticStackAlloc.md) | Static stack allocation for non-reentrant functions (O10): eligibility, interrupt attribute, BFS analysis |
| [Design Document](../design/design.md) | Authoritative architecture specification (registers, instructions, calling convention) |
| [Implementation Plan](../design/plan.md) | Milestone-driven development sequence with steps, tests, and status markers |

### Quick Links

- **Build instructions**: [V6CBuildGuide.md](V6CBuildGuide.md)
- **Mirror sync**: [sync_llvm_mirror.ps1](../scripts/sync_llvm_mirror.ps1) — run after every build ([details](V6CBuildGuide.md#syncing-the-mirror))
- **V6C backend source**: [llvm/lib/Target/V6C/](../llvm/lib/Target/V6C/) — git-tracked mirror
- **Golden tests**: [tests/golden/](../tests/golden/) — emulator trust baseline
- **Vector 06c CPU timings**: [Vector_06c_instruction_timings.md](Vector_06c_instruction_timings.md)

## Milestone Status

| Milestone | Description | Status |
|-----------|-------------|--------|
| M0 | Project Bootstrap & Tool Validation | Complete |
| M1 | Target Registration & Skeleton | Complete |
| M2 | TableGen: Registers & Core Instructions | Complete |
| M3 | MC Layer: Assembly Emission | Complete |
| M4 | ISel: i8 Operations & Basic Lowering | Complete |
| M5 | Frame Lowering & Calling Convention | Complete |
| M6 | MC Layer: Binary Emission | Complete |
| M7 | ISel: i16 & i32 Operations | Complete |
| M8 | Optimization Passes | Complete |
| M9 | Clang Frontend Integration | Complete |
| M10 | Linker & Multi-File Compilation | Complete |
| M11 | Runtime Library | Complete |
| M12 | End-to-End Validation & Performance | Complete |
