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

`llc` can emit ELF object files which are then converted to flat binary:

```bash
# Step 1: Compile to ELF object
llvm-build/bin/llc -march=v6c -mtriple=i8080-unknown-v6c -filetype=obj input.ll -o output.o

# Step 2: Convert to flat binary (base address 0x0100)
python scripts/elf2bin.py output.o -o output.bin --base 0x0100

# Step 2b: Also produce Intel HEX alongside binary
python scripts/elf2bin.py output.o -o output.bin --base 0x0100 --hex
```

### Start Address

The binary start address (default `0x0100`) is configured in two places:

1. **`-mv6c-start-address=<addr>`** — LLVM target option affecting code generation:
   ```bash
   llvm-build/bin/llc -march=v6c -mtriple=i8080-unknown-v6c -mv6c-start-address=0x8000 ...
   ```

2. **`--base <addr>`** — elf2bin.py parameter for relocation base:
   ```bash
   python scripts/elf2bin.py output.o -o output.bin --base 0x8000
   ```

Both must match. The accepted range is `0x0000`–`0xFFFF`.

### Intel HEX Format

Standalone conversion from flat binary to Intel HEX:
```bash
python scripts/bin2hex.py output.bin -o output.hex --base 0x0100
```

### Running in the Emulator

```bash
tools/v6emul/v6emul.exe --rom output.bin --load-addr 0x0100 --halt-exit --dump-cpu
```

## Clang Frontend (C Compiler)

### Building with Clang

To build Clang alongside the V6C backend, add `-DLLVM_ENABLE_PROJECTS=clang`:

```bash
cmake -G Ninja -S llvm-project\llvm -B llvm-build ^
  -DCMAKE_BUILD_TYPE=Release ^
  -DLLVM_TARGETS_TO_BUILD=X86 ^
  -DLLVM_EXPERIMENTAL_TARGETS_TO_BUILD=V6C ^
  -DLLVM_ENABLE_PROJECTS=clang

ninja -C llvm-build clang llc
```

### Compiling C Code

```bash
# C source → LLVM IR
llvm-build/bin/clang -target i8080-unknown-v6c -S -emit-llvm hello.c -o hello.ll

# C source → V6C assembly
llvm-build/bin/clang -target i8080-unknown-v6c -S hello.c -o hello.s

# C source → object file
llvm-build/bin/clang -target i8080-unknown-v6c -c hello.c -o hello.o
```

The driver automatically forces `-ffreestanding` (no hosted C library).

### Type Sizes

| C Type | Size | Notes |
|--------|------|-------|
| `char` | 1 byte | **Unsigned** by default |
| `short` | 2 bytes | |
| `int` | 2 bytes | Same as pointer width |
| `long` | 4 bytes | Software-emulated |
| `long long` | 8 bytes | Warning: very expensive |
| `float` | 4 bytes | Software-emulated (IEEE single) |
| `double` | 4 bytes | Mapped to `float` (no 64-bit FP) |
| `void *` | 2 bytes | 16-bit address space |

### Built-in Macros

| Macro | Description |
|-------|-------------|
| `__V6C__` | Always defined for V6C targets |
| `__I8080__` | Always defined for i8080 |
| `__CHAR_UNSIGNED__` | Indicates `char` is unsigned |

### Language Restrictions

The V6C target emits warnings (controlled by `-Wv6c-expensive-type`) when using types that require expensive software emulation:

- **`long long`** (64-bit integer) — prohibitively expensive on 8-bit CPU
- **`float` / `double`** — no FPU, all operations are software-emulated

Suppress with `-Wno-v6c-expensive-type` if intentional.

### Function Attributes

| Attribute | Effect |
|-----------|--------|
| `__attribute__((leaf))` | Declares that the function does not call back into the current translation unit. Allows LLVM to infer `norecurse` on callers, enabling static stack allocation (O10). Use on external declarations. |
| `__attribute__((interrupt))` | Marks a function as an interrupt service routine. Excludes it and all its transitive callees from static stack allocation and SP-trick optimization. |

Example:
```c
// External function that never calls back into user code.
// Without this attribute, callers cannot get static stack allocation.
__attribute__((leaf))
extern void uart_write(unsigned char c);

// The compiler can now prove this caller is non-reentrant
// and allocate its spill slots statically.
void send_message(const unsigned char *buf, unsigned int len) {
    for (unsigned int i = 0; i < len; i++)
        uart_write(buf[i]);
}
```

### Built-in Functions (Intrinsics)

Hardware-specific operations available as built-in functions:

| Intrinsic | Assembly | Purpose |
|-----------|----------|---------|
| `__builtin_v6c_in(port)` | `IN port` | Read I/O port (returns `unsigned char`) |
| `__builtin_v6c_out(port, val)` | `OUT port` | Write `val` to I/O port |
| `__builtin_v6c_di()` | `DI` | Disable interrupts |
| `__builtin_v6c_ei()` | `EI` | Enable interrupts |
| `__builtin_v6c_hlt()` | `HLT` | Halt processor |
| `__builtin_v6c_nop()` | `NOP` | No-operation |

Example:
```c
void write_port(unsigned char port, unsigned char val) {
    __builtin_v6c_out(port, val);
}

unsigned char read_port(unsigned char port) {
    return __builtin_v6c_in(port);
}

void critical_section(void) {
    __builtin_v6c_di();
    // ... critical code ...
    __builtin_v6c_ei();
}
```

### Inline Assembly

The V6C target supports GCC-style inline assembly with 8080 mnemonics:

```c
void nop_sled(void) {
    asm volatile("NOP");
    asm volatile("NOP");
}

unsigned char read_a(void) {
    unsigned char val;
    asm volatile("" : "=a"(val));  // read accumulator
    return val;
}
```

**Constraint letters:**

| Constraint | Meaning |
|------------|---------|
| `a` | Accumulator (A register) |
| `r` | Any 8-bit general register |
| `p` | Any 16-bit register pair (BC, DE, HL) |
| `I` | 8-bit unsigned immediate (0–255) |
| `J` | 16-bit unsigned immediate (0–65535) |

## LLVM Tuning Options

The V6C backend responds to several LLVM hidden options passed via `-mllvm`.
These control register allocation and spill behaviour, which matters on the
8080's tiny 3-register-pair file.

### Recommended

| Option | Effect |
|--------|--------|
| `-mllvm --enable-deferred-spilling` | Defers spill code insertion, giving the greedy RA a second chance to find a better coloring. Can eliminate spills entirely on register-starved loops. **Experimental** in upstream LLVM — test thoroughly. |

### Situationally Useful

| Option | Effect |
|--------|--------|
| `-mllvm --sink-insts-to-avoid-spills` | Pre-RA pass that sinks definitions closer to uses, freeing registers across the gap. Helps in straight-line code with high register pressure. |
| `-mllvm --split-spill-mode=size` | Tells SplitKit to prefer smaller spill code over faster. Alternative: `=speed`. Default: `=default`. |
| `-mllvm --enable-spill-copy-elim` | Eliminates redundant register-to-register copies introduced by spill code. Unlikely to help on V6C (spills use PUSH/POP and LHLD/SHLD, not copies). |
| `-mllvm -mv6c-spill-patched-reload` | V6C-specific. Enables O61: rewrite selected spill/reload pairs so the spill writes directly into a `LXI`/`MVI` immediate at the reload site (self-modifying code in `.text`). Requires static-stack (default-on) and assumes code is in RAM. Saves 6–22cc and 1–4B per patched reload. See [V6COptimization.md § O61](V6COptimization.md). |

### Not Recommended

| Option | Why |
|--------|-----|
| `-mllvm --regalloc=basic` | Replaces greedy RA with basic linear-scan. Worse code quality on V6C; may not terminate on complex functions. |

### Example: All Useful Options Combined

```bash
llvm-build/bin/clang -target i8080-unknown-v6c -O2 -S input.c -o output.s \
  -mllvm --enable-deferred-spilling \
  -mllvm -sink-insts-to-avoid-spills
```

### Debugging

| Option | Effect |
|--------|--------|
| `-mllvm -mv6c-annotate-pseudos` | Emits function header comments (C declaration + param→register map) and `;--- PSEUDO ---` comments before each pseudo expansion. Add `-fno-discard-value-names` to preserve original C parameter names. |
