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
0x8000 ├──────────────────┤  ← Default stack init (grows downward)
       │  Video RAM       │
0xFFFF └──────────────────┘
```

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
| `crt0.s` | `_start` | Sets SP to 0xFFFF, zeros `.bss`, calls `_main`, then `HLT` |

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
