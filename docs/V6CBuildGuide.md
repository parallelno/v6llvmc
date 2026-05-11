# V6C Build Guide

Build and tooling pipeline for the V6C LLVM backend: prerequisites,
configuration, mirror sync workflow, running tests, invoking `llc`, and
producing flat-binary ROMs.

For C-language and inline-asm reference, see
[V6CClangUsage.md](V6CClangUsage.md). For backend tuning and debugging
flags, see [V6CCompilerOptions.md](V6CCompilerOptions.md). For release
cutting, see [V6CRelease.md](V6CRelease.md).

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

```powershell
# From the project root (PowerShell / pwsh on Windows, MSVC dev shell)
cmake -G Ninja -S llvm-project\llvm -B llvm-build `
  -DCMAKE_BUILD_TYPE=Release `
  -DLLVM_TARGETS_TO_BUILD=X86 `
  -DLLVM_EXPERIMENTAL_TARGETS_TO_BUILD=V6C `
  "-DLLVM_ENABLE_PROJECTS=clang;lld"

ninja -C llvm-build clang lld llc opt llvm-objcopy llvm-tblgen
```

> Note: in PowerShell the `;` in `clang;lld` is a statement separator, so
> the value **must be quoted** as shown (`"-DLLVM_ENABLE_PROJECTS=clang;lld"`).
> In `cmd.exe` use `^` line continuations and no quoting is needed.

The `lld` project provides `ld.lld`, the native ELF linker used by the V6C
toolchain (replaces the legacy Python `scripts/v6c_link.py`, now stubbed).
See plan [design/plan_O_LLD_native_linker.md](../design/plan_O_LLD_native_linker.md).

Verify the target is registered:

```bash
llvm-build/bin/llc --version
# Should list: v6c    - Vector 06c (Intel 8080)
```

## Syncing the Mirror

`llvm-project/` is a large cloned repo (pinned to `llvmorg-18.1.0`) and is **gitignored**.
All V6C source code and tests are git-tracked under `llvm/`, `clang/`, and `tests/lit/`, which serve as mirrors.

After every successful build (or any edit to files inside `llvm-project/`), run:

```powershell
powershell -ExecutionPolicy Bypass -File scripts\sync_llvm_mirror.ps1
```

The script handles three categories:

1. **V6C target directory** (`llvm-project/llvm/lib/Target/V6C/` → `llvm/lib/Target/V6C/`) — full directory mirror via `robocopy /MIR`.
2. **Lit tests** (`llvm-project/{llvm,clang}/test/.../V6C/` → `tests/lit/`) — full directory mirror excluding `Output/`.
3. **Modified upstream LLVM files** (e.g. `Triple.h`, `Triple.cpp`) — individual file copies via `xcopy`.

When a new milestone modifies additional upstream files, add `xcopy` lines to `scripts\sync_llvm_mirror.ps1`.

## Populating llvm-project/ (New Contributors)

After cloning the repo and the LLVM monorepo, run the populate script to copy all V6C code and tests into `llvm-project/`:

```powershell
git clone --depth 1 --branch llvmorg-18.1.0 https://github.com/llvm/llvm-project.git llvm-project
powershell -ExecutionPolicy Bypass -File scripts\populate_llvm_project.ps1
```

This is the reverse of `sync_llvm_mirror.ps1` — it copies from git-tracked mirrors into `llvm-project/` so it's ready to build.

## Running Tests

```bash
# Full suite (golden + lit)
python tests/run_all.py

# Golden test suite (emulator trust baseline)
python tests/run_golden_tests.py

# With verbose output
python tests/run_golden_tests.py -v
```

Lit tests are authored in `llvm-project/` (source of truth) and mirrored to `tests/lit/` by `sync_llvm_mirror.ps1`.

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

## Binary Emission

The clang driver runs `ld.lld` and `llvm-objcopy` automatically. The
output extension determines the format: `.elf` keeps the linked ELF;
anything else (e.g. `.rom`, `.bin`) is converted to a flat binary via
`llvm-objcopy -O binary`.

```bash
# C source -> flat binary ROM (single command)
llvm-build/bin/clang -target i8080-unknown-v6c -O2 input.c -o output.rom

# C source -> ELF (no objcopy step)
llvm-build/bin/clang -target i8080-unknown-v6c -O2 input.c -o output.elf
```

For lower-level control (e.g. linking multiple objects with a custom
linker script):

```bash
# Step 1: Compile each translation unit to ELF object
llvm-build/bin/clang -target i8080-unknown-v6c -O2 -c a.c -o a.o
llvm-build/bin/clang -target i8080-unknown-v6c -O2 -c b.c -o b.o

# Step 2: Link with ld.lld using the V6C linker script
llvm-build/bin/ld.lld -m elf32v6c \
    -T clang/lib/Driver/ToolChains/V6C/v6c.ld \
    a.o b.o -o out.elf

# Step 3: Convert to flat binary
llvm-build/bin/llvm-objcopy -O binary out.elf out.rom
```

### Start Address

The default load address is `0x0100`, set by the `v6c.ld` linker script
(`. = 0x0100;` at the start of `.text`). To override, either:

1. **Pass a custom linker script** via `-Wl,-T,my-script.ld` to clang, or
2. **Use `-Wl,-Ttext=0xNNNN`** to override the text base while keeping
   the rest of the layout. Example:
   ```bash
   llvm-build/bin/clang -target i8080-unknown-v6c -O2 \
       -Wl,-Ttext=0x8000 input.c -o output.rom
   ```

Note: when relocating to a non-default base, the V6C runtime
(`__stack_top = 0x0000`) and crt0 entry stay the same; only the code/data
addresses change. The legal range is `0x0000`–`0xFFFF`.

### Intel HEX Format

Standalone conversion from flat binary to Intel HEX:
```bash
python scripts/bin2hex.py output.bin -o output.hex --base 0x0100
```

### Running in the Emulator

```bash
tools/v6emul/v6emul.exe --rom output.bin --load-addr 0x0100 --halt-exit --dump-cpu
```

## Further Reading

| Topic | Document |
|-------|----------|
| C language model, builtins, attributes, inline asm | [V6CClangUsage.md](V6CClangUsage.md) |
| Backend tuning and debugging flags | [V6CCompilerOptions.md](V6CCompilerOptions.md) |
| Math runtime (`v6c_arith.h`) and asm interop contract | [V6CRuntimeAndInlineAsm.md](V6CRuntimeAndInlineAsm.md) |
| Optimization passes and design notes | [V6COptimization.md](V6COptimization.md) |
| Cutting a tagged release | [V6CRelease.md](V6CRelease.md) |
