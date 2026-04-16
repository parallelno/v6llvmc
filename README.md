# V6C — LLVM Backend for Vector 06c

An LLVM compiler backend and Clang frontend targeting the **Vector 06c** home computer (Intel 8080 / KR580VM80A CPU, 3 MHz, 64 KB RAM).

**Full pipeline**: C source → Clang → LLVM IR → V6C backend → flat binary → Vector 06c

## Quick Start

### Prerequisites

- CMake ≥ 3.20, Ninja, MSVC 2022+ (or GCC 11+ / Clang 14+)
- Python 3.8+

### Build

```bash
cmake -G Ninja -S llvm-project\llvm -B llvm-build ^
  -DCMAKE_BUILD_TYPE=Release ^
  -DLLVM_TARGETS_TO_BUILD=X86 ^
  -DLLVM_EXPERIMENTAL_TARGETS_TO_BUILD=V6C ^
  -DLLVM_ENABLE_PROJECTS=clang

ninja -C llvm-build clang llc
```

### Compile a C Program

```bash
# C → assembly
llvm-build/bin/clang -target i8080-unknown-v6c -S hello.c -o hello.s

# C → ELF object → flat binary
llvm-build/bin/clang -target i8080-unknown-v6c -c hello.c -o hello.o
python scripts/elf2bin.py hello.o -o hello.bin --base 0x0100

# Run in emulator
tools/v6emul/v6emul.exe --rom hello.bin --load-addr 0x0100 --halt-exit --dump-cpu
```

### Run Tests

```bash
python tests/run_all.py          # Full suite (golden + lit)
python tests/run_golden_tests.py # Emulator trust baseline (15 tests)
```

## Supported C Subset

- **Types**: `char` (unsigned, 1B), `short` / `int` (2B), `long` (4B), pointers (2B)
- **Operations**: All integer arithmetic, bitwise, shifts, comparisons, control flow
- **Functions**: Full calling convention with register + stack argument passing
- **Globals**: Initialized and uninitialized data, `const` → `.rodata`
- **Multi-file**: Cross-file linking via `scripts/v6c_link.py`
- **Intrinsics**: `__builtin_v6c_in`, `__builtin_v6c_out`, `__builtin_v6c_di`, `__builtin_v6c_ei`, `__builtin_v6c_hlt`, `__builtin_v6c_nop`
- **Inline assembly**: `asm volatile("NOP")` (IR-level constraints)

### Limitations

- No standard C library (freestanding only)
- `long long` / `float` / `double` compile but are very expensive (warning emitted)
- No hardware floating-point
- Maximum binary size: 64 KB

## Project Structure

| Path | Description |
|------|-------------|
| `llvm-project/` | LLVM monorepo (pinned `llvmorg-18.1.0`, gitignored) |
| `llvm/` | Git-tracked mirror of V6C backend + modified upstream files |
| `clang/` | Git-tracked mirror of Clang V6C integration |
| `compiler-rt/` | Runtime library (crt0, multiply, divide, shift, memory) |
| `scripts/` | Mirror sync, linker, ELF→binary converter |
| `tools/v6asm/` | Reference 8080 assembler |
| `tools/v6emul/` | Vector 06c emulator |
| `tests/` | Golden, lit (mirror), integration, runtime, and benchmark tests |
| `docs/` | [Documentation index](docs/README.md) |
| `design/` | [Architecture design](design/design.md) and [implementation plan](design/plan.md) |

## Documentation

See [docs/README.md](docs/README.md) for the full documentation index, including:

- [Build Guide](docs/V6CBuildGuide.md) — detailed build instructions, mirror sync, binary emission
- [Architecture](docs/V6CArchitecture.md) — CPU, data layout, memory map, runtime library
- [Calling Convention](docs/V6CCallingConvention.md) — register/stack argument passing, frame layout
- [Optimization Passes](docs/V6COptimization.md) — 8 custom passes with toggle flags
- [Instruction Timings](docs/V6CInstructionTimings.md) — cycle costs for all 8080 instructions

## License

See [LICENSE](LICENSE).
