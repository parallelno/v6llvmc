# O55. Additional Peepholes (CMA, XRA A, Idempotent ALU)

*Inspired by llvm-z80 `Z80LateOptimization` peephole collection.*
*Detailed analysis: [llvm_z80_analysis.md](llvm_z80_analysis.md) §S8.*

## Problem

Several byte-saving peephole patterns exist on the 8080 that are not
currently handled by any V6C optimization pass.

## Patterns

### Pattern 1: XRI 0FFH → CMA

`XRI 0FFH` (XOR A with 0xFF = bitwise complement) costs 8cc and 2 bytes.
`CMA` (complement A) costs 4cc and 1 byte. They produce the same result in A.

**Key difference**: `XRI` sets flags (S, Z, P, CY=0, AC); `CMA` does **not**
affect any flags. This means the replacement is always safe — it preserves
more state, not less.

```asm
; Before              ; After
XRI  0FFH  ; 8cc, 2B  CMA     ; 4cc, 1B
```

### Pattern 2: MVI A, 0 → XRA A (when flags dead)

`MVI A, 0` costs 8cc and 2 bytes. `XRA A` costs 4cc and 1 byte and also
sets A to 0. However, `XRA A` sets flags (Z=1, S=0, P=1, CY=0, AC=0),
so this replacement is only valid when flags are dead after the instruction.

```asm
; Before                ; After (if flags dead)
MVI  A, 0   ; 8cc, 2B   XRA  A    ; 4cc, 1B
```

### Pattern 3: Idempotent ALU elimination

Consecutive identical ALU-immediate instructions are redundant:
- `ANI n; ANI n` → `ANI n` (second is no-op: A AND n AND n = A AND n)
- `ORI n; ORI n` → `ORI n` (A OR n OR n = A OR n)

```asm
; Before              ; After
ANI  0FH   ; 8cc, 2B  ANI  0FH   ; 8cc, 2B
ANI  0FH   ; 8cc, 2B  ; (deleted)
```

## Implementation

Add to the existing `V6CPeephole` pass:

```cpp
// Pattern 1: XRI 0FFH → CMA
if (MI.getOpcode() == V6C::XRI && MI.getOperand(0).getImm() == 0xFF) {
  MI.setDesc(TII->get(V6C::CMA));
  MI.removeOperand(0);  // Remove immediate operand
  Changed = true;
}

// Pattern 2: MVI A, 0 → XRA A (when flags dead)
if (MI.getOpcode() == V6C::MVI_A && MI.getOperand(0).getImm() == 0 &&
    !isLiveAfter(V6C::FLAGS, MI)) {
  MI.setDesc(TII->get(V6C::XRA));
  MI.removeOperand(0);
  MachineInstrBuilder(MF, MI).addReg(V6C::A);  // XRA A
  Changed = true;
}

// Pattern 3: Idempotent ALU
if (isALUImm(MI) && NextMI && MI.isIdenticalTo(*NextMI)) {
  NextMI->eraseFromParent();
  Changed = true;
}
```

## Benefit

- **Pattern 1 (CMA)**: 4cc + 1B per instance. Unconditionally safe.
- **Pattern 2 (XRA A)**: 4cc + 1B per instance. Requires flag liveness check.
- **Pattern 3 (idempotent)**: 8cc + 2B per instance. Rare but free to check.
- **Combined frequency**: Medium — CMA pattern is uncommon, XRA A is moderate,
  idempotent is rare

## Complexity

Very Low. ~20 lines added to existing peephole pass.

## Risk

Very Low. Pattern 1 is unconditionally correct. Pattern 2 requires flag
liveness (already available in peephole infrastructure). Pattern 3 is
trivially correct for idempotent operations.

## Dependencies

None. Can integrate with O53 (enhanced value tracking) for more accurate
flag liveness, but works standalone with existing liveness queries.
