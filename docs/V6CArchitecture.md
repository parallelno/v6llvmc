# V6C Target Architecture

## CPU

| Property | Value |
|----------|-------|
| CPU | Intel 8080 (KR580VM80A) |
| Clock | 3 MHz |
| Memory | 64 KB flat address space |
| Endianness | Little-endian |
| Word size | 8-bit ALU, 16-bit address bus |
| Registers | A, B, C, D, E, H, L (8-bit); BC, DE, HL, SP (16-bit pairs) |
| Stack | Grows downward, full-descending |

## Data Layout

```
e-p:16:8-i1:8-i8:8-i16:8-i32:8-i64:8-n8:16-S8
```

- Pointers are 16-bit, byte-aligned
- Native integer widths: 8 and 16 bits
- No hardware alignment requirements

## Default Memory Map

The canonical layout is set by `clang/lib/Driver/ToolChains/V6C/v6c.ld`,
which clang passes to `ld.lld` automatically. Sections are emitted in
the order `.text`, `.rodata`, `.data`, `.bss`. The linker also defines
the symbols `__bss_start`, `__bss_end`, and `__stack_top = 0x0000`.

```
0x0000 ┌──────────────────┐  ← __stack_top (first PUSH wraps SP to 0xFFFE)
       │  (reserved)      │
0x0100 ├──────────────────┤  ← Default load address (`. = 0x0100;` in v6c.ld)
       │  .text._start    │  ← crt0 / entry pinned by KEEP(*(.text._start))
       │  .text           │
       │  .rodata         │
       │  .data           │
       │  .bss            │  ← __bss_start ... __bss_end (zero-initialized
       │                  │     by crt0)
       │  (heap ↑)        │
       │       ...        │
       │  (stack ↓)       │  ← grows downward from 0xFFFE
0x8000 ├──────────────────┤
       │  Video RAM       │
0xFFFF └──────────────────┘
```

To relocate `.text` to a different base, override the script base via
`-Wl,-Ttext=0xNNNN` or pass a custom script with `-Wl,-T,my.ld`.

## Supported Type Widths

| C Type | Width | LLVM Type | Support |
|--------|-------|-----------|---------|
| `char` / `unsigned char` | 8-bit | `i8` | Native (8080 ALU) |
| `short` / `unsigned short` | 16-bit | `i16` | Register pairs (BC, DE, HL); pseudo-instructions expand to 8-bit sequences |
| `int` / `unsigned int` | 16-bit | `i16` | Same as `short` |
| `long` / `unsigned long` | 32-bit | `i32` | Expanded to pairs of `i16` |
| `void *` / pointers | 16-bit | `i16` | Native 16-bit address bus |

**Limitations:**
- `long long` (64-bit): Not supported. Diagnostic warning emitted.
- `float` / `double`: Not supported (no FPU). Diagnostic warning emitted.
- `char` is **unsigned** by default (`__CHAR_UNSIGNED__`).
- No hardware alignment requirements — all types are byte-aligned.
- Maximum addressable memory: 64 KB.

## Calling Convention Summary

All registers are **caller-saved** (no callee-saved registers).

| Argument # | i8 | i16 |
|------------|-----|------|
| 1st | `A` | `HL` |
| 2nd | `E` | `DE` |
| 3rd | `C` | `BC` |
| 4th+ | Stack | Stack |

Returns: `i8` → `A`, `i16` → `HL`, `i32` → `DE:HL`.

See [V6CCallingConvention.md](V6CCallingConvention.md) for full details.

## Runtime Library

The V6C runtime library (`compiler-rt/lib/builtins/v6c/`) provides functions for operations the 8080 CPU cannot perform natively. All functions follow the V6C calling convention.

### Startup

| File | Symbol | Description |
|------|--------|-------------|
| `crt0.s` | `_start` | Sets `SP = __stack_top` (default `0x0000` → first PUSH wraps to `0xFFFE`), zeros `[__bss_start, __bss_end)`, calls `main`, then `HLT`. Placed in `.text._start` so the linker script (`v6c.ld`) pins it at `0x0100`. |

### Arithmetic

| File | Symbol | Signature | Description |
|------|--------|-----------|-------------|
| `mulhi3.s` | `__mulhi3` | `i16(HL) × i16(DE) → i16(HL)` | 16×16→16 unsigned multiply (left-shift-and-add) |
| `mulsi3.s` | `__mulsi3` | `i16(HL) × i16(DE) → i32(DE:HL)` | 16×16→32 full multiply (right-shift with 32-bit accumulator) |
| `divhi3.s` | `__divhi3` | `i16(HL) ÷ i16(DE) → i16(HL)` | Signed 16-bit division (wraps `__udivmod16` with sign handling) |
| `divhi3.s` | `__modhi3` | `i16(HL) % i16(DE) → i16(HL)` | Signed 16-bit modulo |
| `udivhi3.s` | `__udivhi3` | `i16(HL) ÷ i16(DE) → i16(HL)` | Unsigned 16-bit division (restoring division) |
| `udivhi3.s` | `__umodhi3` | `i16(HL) % i16(DE) → i16(HL)` | Unsigned 16-bit modulo |

### Shifts

| File | Symbol | Signature | Description |
|------|--------|-----------|-------------|
| `shift.s` | `__ashlhi3` | `i16(HL) << i16(DE) → i16(HL)` | Variable-count left shift (DAD H loop) |
| `shift.s` | `__lshrhi3` | `i16(HL) >> i16(DE) → i16(HL)` | Variable-count logical right shift |
| `shift.s` | `__ashrhi3` | `i16(HL) >> i16(DE) → i16(HL)` | Variable-count arithmetic right shift (sign-preserving) |

### Memory

| File | Symbol | Signature | Description |
|------|--------|-----------|-------------|
| `memory.s` | `memcpy` | `memcpy(HL=dst, DE=src, BC=n) → HL` | Forward byte-by-byte copy, returns dst |
| `memory.s` | `memset` | `memset(HL=dst, DE=val, BC=n) → HL` | Byte-by-byte fill (val in E), returns dst |
| `memory.s` | `memmove` | `memmove(HL=dst, DE=src, BC=n) → HL` | Overlap-safe copy (backward when dst > src) |

### Backend Integration

- i8 arithmetic (`MUL`, `SDIV`, `UDIV`, `SREM`, `UREM`) is promoted to i16, so all operations use the i16 libcalls.
- i8 variable shifts are promoted to i16 with appropriate zero/sign extension.
- i16 variable shifts emit libcalls directly.
- Constant shifts are unrolled inline (no libcall).

## ELF Object Format

V6C object files (`.o` produced by `clang -c` / `llc -filetype=obj`) and
linked images use the standard ELF32 little-endian container with a private,
unassigned `e_machine` value:

| Field | Value |
|-------|-------|
| `e_ident[EI_CLASS]` | `ELFCLASS32` |
| `e_ident[EI_DATA]`  | `ELFDATA2LSB` |
| `e_ident[EI_OSABI]` | `ELFOSABI_STANDALONE` (no hosted runtime) |
| `e_machine`         | `EM_V6C = 0x8080` |

`EM_V6C = 0x8080` is **not** registered with the official ELF e_machine
registry. The value was chosen to mirror the i8080 CPU number and is local to
this toolchain. It is defined once in `llvm/include/llvm/BinaryFormat/ELF.h`
and consumed by:

- `llvm/lib/Target/V6C/MCTargetDesc/V6CAsmBackend.cpp` — emits objects with
  this `e_machine`.
- `lld/ELF/Arch/V6C.cpp` + `lld/ELF/Target.cpp` — `ld.lld` dispatches to the
  V6C relocation backend on this `e_machine`.

### Relocations

V6C is purely absolute (no PC-relative addressing on the 8080). Four
relocation types are defined; their numeric values are stable and shared
between `V6CAsmBackend` (writer) and `lld` (consumer):

| Type | Value | Width | Description |
|------|-------|-------|-------------|
| `R_V6C_NONE` | 0 | — | No relocation |
| `R_V6C_8`    | 1 | 1 byte  | 8-bit absolute value |
| `R_V6C_16`   | 2 | 2 bytes | 16-bit absolute address (little-endian) |
| `R_V6C_LO8`  | 3 | 1 byte  | Low byte of a 16-bit absolute (`lo8(expr)`) |
| `R_V6C_HI8`  | 4 | 1 byte  | High byte of a 16-bit absolute (`hi8(expr)`) |

`R_V6C_8` and `R_V6C_16` perform overflow checks (the value must fit in a
signed or unsigned 8/16-bit field). `R_V6C_LO8` / `R_V6C_HI8` are byte
extractions and never overflow.
