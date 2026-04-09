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
