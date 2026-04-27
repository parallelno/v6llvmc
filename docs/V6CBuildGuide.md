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
  -DLLVM_EXPERIMENTAL_TARGETS_TO_BUILD=V6C ^
  -DLLVM_ENABLE_PROJECTS=clang;lld

ninja -C llvm-build llc clang ld.lld lld llvm-objcopy llvm-tblgen
```

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

## Clang Frontend (C Compiler)

### Building with Clang

To build Clang alongside the V6C backend, add `-DLLVM_ENABLE_PROJECTS=clang`:

```bash
cmake -G Ninja -S llvm-project\llvm -B llvm-build ^
  -DCMAKE_BUILD_TYPE=Release ^
  -DLLVM_TARGETS_TO_BUILD=X86 ^
  -DLLVM_EXPERIMENTAL_TARGETS_TO_BUILD=V6C ^
  -DLLVM_ENABLE_PROJECTS=clang;lld

ninja -C llvm-build clang llc ld.lld llvm-objcopy
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


## V6C Resource-Dir Headers

The V6C driver auto-injects `<resource-dir>/lib/v6c/include/` ahead of
Clang's stock freestanding directory, so the following headers resolve
without any `-I` flag:

| Header | Provides |
|--------|----------|
| `<string.h>` | `memcpy`, `memset`, `memmove`, `strlen`, `strcmp`, `strcpy` |
| `<stdlib.h>` | `EXIT_SUCCESS` / `EXIT_FAILURE`, `abort()`, `exit(int)` (both `noreturn`, expand to `HLT` loop) |
| `<v6c.h>` | `__v6c_in`, `__v6c_out`, `__v6c_di`, `__v6c_ei`, `__v6c_hlt`, `__v6c_nop` thin inline wrappers around the `__builtin_v6c_*` family |

The headers are header-only inline-`__asm__` wrappers — there is no
`libv6c-builtins.a` archive. Tiny constant-N cases inline directly;
larger calls reference per-routine `.o` files (`memcpy.o` etc.) under
`<resource-dir>/lib/v6c/` that the V6C driver picks up via
`--gc-sections`.

The driver also passes `-ffunction-sections` by default so per-function
ELF sections are emitted. Pass `-Wl,--gc-sections` at the link step to
prune unreferenced helper functions transitively. Override the
per-function sections with `-fno-function-sections` if needed.

The V6C include directory is injected only by the V6C toolchain;
cross-host compiles for x86 and other targets are unaffected.

## Inline Assembly Patterns

Two idiomatic styles are supported by the V6C inline-asm flow:

### Style A — Inlined Body (single instruction sequence)

The compiler interleaves the asm with surrounding code. Use for short
sequences where the cost of a `CALL` would dominate.

```c
static inline __attribute__((always_inline))
void out_port(unsigned char port, unsigned char val) {
    __asm__ volatile (
        "MVI A, %1\n"
        "OUT %0\n"
        : : "i"(port), "r"(val)
        : "A"
    );
}
```

The clobber list (`"A"` here) is honored exactly: only the accumulator
is treated as live-out across the asm block. Pair registers `B`/`D`/`H`
and pair halves `C`/`E`/`L` are not spilled unless explicitly listed.

### Style B — CALL Extern (per-routine `.o`)

The asm is a single `CALL helper` with a strict clobber list; the
helper lives in a separately assembled `.s`/`.o` file. Pruning by
`ld.lld --gc-sections` works transitively across the asm/C boundary
because `CALL helper` emits a normal `R_V6C_16` relocation the
linker can see.

```c
static inline __attribute__((always_inline))
void external_helper(void) {
    __asm__ volatile ("CALL helper" : : : "A", "memory");
}
```

GCC register names used in clobber lists are case-sensitive: spell
single regs uppercase (`"A"`, `"B"`, `"C"`, `"D"`, `"E"`, `"H"`, `"L"`).

## Computed Jumps and `--gc-sections`

`ld.lld --gc-sections` walks relocations in **all** reachable
sections, including `.rodata` jump tables. Authors must encode
addresses through the assembler's symbol machinery so a relocation is
emitted; otherwise the target may be GC'd:

| Form | Relocation | Status |
|------|------------|--------|
| `.word target` | `R_V6C_16` | Safe |
| `.byte target@lo` / `.byte target@hi` | `R_V6C_8_LO` / `R_V6C_8_HI` | Safe |
| Hand-computed `.byte 0xC3, 0x34, 0x12` literal | none | **Unsafe** — linker can't see the reference |

Forced-live escapes when the relocation route is impractical:

- `__attribute__((used))` on a C wrapper that references the target.
- `KEEP(*(.text.func))` in the linker script.
- Group all jump-table targets in a single `KEEP`'d section.

## End-to-End Example

```bash
# Single-command build of a C program for V6C.
# The driver finds crt0.o under <resource-dir>/lib/v6c/ (or the
# compiler-rt dev tree), runs ld.lld with v6c.ld, and converts the
# linked ELF to a flat ROM via llvm-objcopy.
llvm-build/bin/clang -target i8080-unknown-v6c -O2 \
    main.c -Wl,--gc-sections -o out.rom
```

No `-nostartfiles`, `-nodefaultlibs`, or `-Wl,--defsym=_start=main`
workaround is needed. `crt0.s` is assembled by the V6C MC AsmParser
(Phase 3 of the asm-interop overhaul), and `_start` is the canonical
entry point declared in `crt0.s`.
