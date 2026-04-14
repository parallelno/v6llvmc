# V6C Calling Convention

## Overview

The V6C calling convention (`V6C_CConv`) is designed for the extreme register scarcity of the Intel 8080/KR580VM80A. With only 7 general-purpose 8-bit registers (A, B, C, D, E, H, L) and 3 register pairs (BC, DE, HL), every register is caller-saved.

## Argument Passing

Arguments are assigned by position to fixed registers:

| Argument # | i8 Register | i16 Register | Notes |
|------------|-------------|--------------|-------|
| 1st | `A` | `HL` | Cheapest access |
| 2nd | `E` | `DE` | Secondary pair |
| 3rd | `C` | `BC` | Tertiary pair |
| 4th+ | Stack | Stack | Right-to-left, caller cleans |

Stack arguments are pushed right-to-left (cdecl-style). The caller is responsible for cleaning up the stack after the call.

### Examples

```c
void f(uint8_t a);           // a → A
void g(uint16_t p);          // p → HL
void h(uint8_t a, uint8_t b); // a → A, b → E
void k(uint16_t x, uint16_t y, uint16_t z); // x → HL, y → DE, z → BC
void m(uint8_t a, uint8_t b, uint8_t c, uint8_t d); // a → A, b → E, c → C, d → stack
```

## Return Values

| Type | Register(s) |
|------|-------------|
| `i8` | `A` |
| `i16` | `HL` |
| `i32` | `DE:HL` (DE = high 16 bits, HL = low 16 bits) |
| Struct (>4B) | `sret` pointer in `HL` |

## Callee-Saved Registers

**None.** All registers are caller-saved. With only 7 GPRs, callee-save obligations would force excessive spilling. Leaf functions benefit from full register availability; the call-graph optimizer can inline aggressively.

At optimized levels, V6C also enables LLVM IPRA by default. This does **not**
change the ABI: registers remain caller-saved at the calling-convention level.
It only allows the compiler to prove that a particular direct callee leaves a
subset of caller-saved registers untouched, reducing spill/reload traffic at
that specific call site.

## Stack Frame Layout

```
High addresses
  ┌──────────────────┐
  │  Arg N (caller)  │   ← Pushed right-to-left
  │  ...             │
  │  Arg 4 (caller)  │
  │  Return Address  │   ← CALL pushes 16-bit PC
  │  [Saved regs]    │   ← Optional (if convention overridden)
  │  Local var 1     │
  │  Local var 2     │
  │  ...             │
  │  [Spill slots]   │
  └──────────────────┘
Low addresses          ← SP points here
```

## Prologue / Epilogue

**Prologue** (allocate N bytes of stack):
```asm
  LXI  H, -N       ; 12cc — load negative frame size
  DAD  SP           ; 12cc — HL = SP - N
  SPHL              ;  8cc — SP = HL
```

**Epilogue** (deallocate and return):
```asm
  LXI  H, N        ; 12cc — load frame size
  DAD  SP           ; 12cc — HL = SP + N
  SPHL              ;  8cc — SP = HL
  RET               ; 12cc
```

Leaf functions with no local variables omit the prologue/epilogue entirely (shrink-wrapping).

## Frame Pointer

The 8080 has no dedicated frame pointer register. By default, frame pointers are **omitted** at all optimization levels — the V6C target returns `false` from `useFramePointerForTargetByDefault()` in `CommonArgs.cpp`, matching other register-constrained targets (xcore, wasm, msp430). For functions requiring a frame pointer (e.g., `alloca`, variable-length arrays, or `-fno-omit-frame-pointer`), `BC` is reserved as the frame pointer. This reduces allocatable register pairs from 3 to 2.

## Stack Slot Access

Accessing a stack slot at offset N from SP costs 32 cycles:
```asm
  LXI  H, N        ; 12cc — load offset
  DAD  SP           ; 12cc — HL = SP + N
  MOV  A, M         ;  8cc — load byte from [HL]
```

This high cost motivates aggressive register allocation, rematerialization (MVIr/LXI at 8–12cc vs 64cc+ spill round-trip), and the accumulator planning optimization pass.

## Implementation

- Return value assignment: `V6CCallingConv.td` (`RetCC_V6C`)
- Argument passing: `V6CISelLowering.cpp` (`LowerFormalArguments`, `LowerCall`) — implemented in C++ due to position-based complexity
- Frame lowering: `V6CFrameLowering.cpp`
