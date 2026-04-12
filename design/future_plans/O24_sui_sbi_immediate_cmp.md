# O24. SUI/SBI Immediate Unsigned Comparison

*From plan_immediate_cmp.md Future Enhancements.*
*Extends the immediate CMP optimization to unsigned less-than/greater-equal.*

## Problem

The current V6C_BR_CC16_IMM pseudo handles EQ/NE comparisons with
immediate RHS using `MVI A, lo8; CMP reg` (12cc per byte). For unsigned
ordering comparisons (SETULT, SETUGE), the backend uses SUB/SBB with
register operands, requiring the constant to be materialized in a register
pair via LXI:

### Current output (unsigned i16 compare with constant):
```asm
; if (x < 1000) ...
    LXI  DE, 1000         ; 10cc, 3B  ← constant in register pair
    MOV  A, L             ;  8cc, 1B
    SUB  E                ;  4cc, 1B
    MOV  A, H             ;  8cc, 1B
    SBB  D                ;  4cc, 1B
    JC   .Ltrue           ; 12cc, 3B
; Total: 46cc, 10B
```

### Expected output (SUI/SBI immediate):
```asm
; if (x < 1000) ...
    MOV  A, L             ;  8cc, 1B
    SUI  <(1000)          ;  8cc, 2B  ← immediate subtract
    MOV  A, H             ;  8cc, 1B
    SBI  >(1000)          ;  8cc, 2B  ← immediate subtract with borrow
    JC   .Ltrue           ; 12cc, 3B
; Total: 44cc, 9B
```

**Savings**: 2cc + 1B per instance. More importantly, **frees the register
pair** (DE in the example) which was only holding the constant. This reduces
register pressure, potentially avoiding spills elsewhere.

## Implementation

### Option A: New pseudo V6C_BR_CC16_IMM_ULT

Add a new pseudo for unsigned ordering comparison with immediate:

```tablegen
let isBranch = 1, isTerminator = 1, Defs = [A, FLAGS] in
def V6C_BR_CC16_IMM_ULT : V6CPseudo<(outs),
    (ins GR16:$lhs, imm16:$rhs, i8imm:$cc, brtarget:$dst),
    "# BR_CC16_IMM_ULT $lhs, $rhs, $cc, $dst", []>;
```

Expansion in `V6CInstrInfo.cpp`:
```cpp
// MOV A, LhsLo; SUI lo8(rhs); MOV A, LhsHi; SBI hi8(rhs); JC/JNC dst
```

### Option B: Extend V6C_BR_CC16_IMM expansion

Reuse the existing pseudo but expand differently for ULT/UGE conditions
versus EQ/NE conditions. The pseudo already has a `$cc` operand.

### ISel matching

In `V6CISelLowering.cpp` `LowerBR_CC()`, match `SETULT`/`SETUGE` with
`ConstantSDNode` or `V6CISD::Wrapper` RHS → emit `V6C_BR_CC16_IMM` (or
the new pseudo) instead of the register-based SUB/SBB path.

## Benefit

- **Savings**: 2cc + 1B per instance (direct instruction savings)
- **Register pressure**: Frees one register pair per comparison — this
  is the primary benefit on the register-starved 8080
- **Frequency**: Medium-High — unsigned comparisons with constants are
  common in array bounds checks, loop limits, and protocol parsing

## Complexity

Medium. ISel matching (~20 lines) + expansion (~15 lines) + lo8/hi8
MCExpr already exists from the immediate CMP work.

## Risk

Low. SUI/SBI are standard 8080 instructions with well-defined semantics.
The carry flag behavior for unsigned comparison is identical to SUB/SBB.

## Dependencies

None. lo8/hi8 MCExpr infrastructure already exists.

## Testing

1. New lit test: `br-cc16-imm-ult.ll` — unsigned less-than with constant
2. Golden test regression check
