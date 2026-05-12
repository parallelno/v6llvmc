# V6C Clang Usage

C-frontend reference for the V6C target: compiling, type model, language
restrictions, function attributes, builtins, inline assembly, and the
auto-included header set.

For build/setup and tooling pipeline, see
[V6CBuildGuide.md](V6CBuildGuide.md). For backend tuning flags and
debugging output, see [V6CCompilerOptions.md](V6CCompilerOptions.md).
For the math runtime contract, see
[V6CRuntimeAndInlineAsm.md](V6CRuntimeAndInlineAsm.md).

## Building Clang

To build Clang alongside the V6C backend, add `-DLLVM_ENABLE_PROJECTS=clang`:

```bash
cmake -G Ninja -S llvm-project\llvm -B llvm-build ^
  -DCMAKE_BUILD_TYPE=Release ^
  -DLLVM_TARGETS_TO_BUILD=X86 ^
  -DLLVM_EXPERIMENTAL_TARGETS_TO_BUILD=V6C ^
  -DLLVM_ENABLE_PROJECTS=clang;lld

ninja -C llvm-build clang llc ld.lld llvm-objcopy
```

## Compiling C Code

```bash
# C source → LLVM IR
llvm-build/bin/clang -target i8080-unknown-v6c -S -emit-llvm hello.c -o hello.ll

# C source → V6C assembly
llvm-build/bin/clang -target i8080-unknown-v6c -S hello.c -o hello.s

# C source → object file
llvm-build/bin/clang -target i8080-unknown-v6c -c hello.c -o hello.o
```

The driver automatically forces `-ffreestanding` (no hosted C library).

## Type Sizes

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

## Built-in Macros

| Macro | Description |
|-------|-------------|
| `__V6C__` | Always defined for V6C targets |
| `__I8080__` | Always defined for i8080 |
| `__CHAR_UNSIGNED__` | Indicates `char` is unsigned |

## Language Restrictions

The V6C target emits warnings (controlled by `-Wv6c-expensive-type`) when using types that require expensive software emulation:

- **`long long`** (64-bit integer) — prohibitively expensive on 8-bit CPU
- **`float` / `double`** — no FPU, all operations are software-emulated

Suppress with `-Wno-v6c-expensive-type` if intentional.

## Function Attributes

| Attribute | Effect |
|-----------|--------|
| `__attribute__((leaf))` | Declares that the function does not call back into the current translation unit. Allows LLVM to infer `norecurse` on callers, enabling static stack allocation (O10). Use on external declarations. |
| `__attribute__((interrupt))` | Marks a function as an interrupt service routine. Excludes it and all its transitive callees from static stack allocation and SP-trick optimization. |
| `__attribute__((annotate("v6c-rt-helper")))` | Tags a function as a V6C runtime helper. The V6C `AsmPrinter` uses this tag to suppress the function from `.s` output by default; the object-file emission (`-c`/`-filetype=obj`) is unaffected. Used by the auto-included `v6c_arith.h` header. Toggle visibility with `-mllvm -mv6c-print-rt-helpers` (see [V6CCompilerOptions.md](V6CCompilerOptions.md#debugging)). |

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

## Built-in Functions (Intrinsics)

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

## Inline Assembly

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

## V6C Resource-Dir Headers

The V6C driver auto-injects `<resource-dir>/lib/v6c/include/` ahead of
Clang's stock freestanding directory, so the following headers resolve
without any `-I` flag:

| Header | Provides |
|--------|----------|
| `<string.h>` | `memcpy`, `memset`, `memmove`, `strlen`, `strcmp`, `strcpy` (header-only inline asm, opt-in via `#include`) |
| `<stdlib.h>` | `EXIT_SUCCESS` / `EXIT_FAILURE`, `abort()`, `exit(int)` (both `noreturn`, expand to `HLT` loop) |
| `<v6c.h>` | `__v6c_in`, `__v6c_out`, `__v6c_di`, `__v6c_ei`, `__v6c_hlt`, `__v6c_nop` thin inline wrappers around the `__builtin_v6c_*` family |
| `v6c_arith.h` | Math runtime (`__mulqi3`, `__mulhi3`, `__udivhi3`, `__divhi3`, `__ashlhi3`, ...). **Auto-included** via `-include v6c_arith.h` on V6C targets; suppress with `-fno-v6c-auto-include`. See [V6CRuntimeAndInlineAsm.md](V6CRuntimeAndInlineAsm.md). |

All runtime routines are header-only inline-`__asm__` helpers — there
is no `libv6c-builtins.a` archive. Each translation unit gets its own
per-TU static copy of every helper it actually calls; `--gc-sections`
(on by default for V6C in ld.lld) prunes the unreferenced ones.

The driver also passes `-ffunction-sections` by default so per-function
ELF sections are emitted. Pass `-Wl,--gc-sections` at the link step to
prune unreferenced helper functions transitively. Override the
per-function sections with `-fno-function-sections` if needed.

`<string.h>` and `v6c_arith.h` are shipped from
`compiler-rt/lib/builtins/v6c/include/` (dev tree) or
`<resource-dir>/lib/v6c/include/` (installed). `<stdlib.h>` and
`<v6c.h>` are shipped from `clang/lib/Driver/ToolChains/V6C/include/`
(dev tree) or `<resource-dir>/v6c/include/` (installed). Both
directories are added as `-internal-isystem`.

The V6C include directories are injected only by the V6C toolchain;
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
# compiler-rt dev tree), runs ld.lld with v6c.ld (and --gc-sections),
# and converts the linked ELF to a flat ROM via llvm-objcopy.
# Auto-includes v6c_arith.h for the math runtime (suppress with
# -fno-v6c-auto-include).
llvm-build/bin/clang -target i8080-unknown-v6c -O2 main.c -o out.rom
```

No `-nostartfiles`, `-nodefaultlibs`, or `-Wl,--defsym=_start=main`
workaround is needed. `crt0.s` is assembled by the V6C MC AsmParser
(Phase 3 of the asm-interop overhaul), and `_start` is the canonical
entry point declared in `crt0.s`.
