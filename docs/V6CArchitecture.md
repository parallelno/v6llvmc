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
