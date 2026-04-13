# O29. Cross-BB Immediate Value Propagation

*Identified from analysis of temp/compare/07/v6llvmc.c output.*
*Extension of O13 (register value tracking) across basic block boundaries.*

## Problem

The existing `V6CLoadImmCombine` (O13) and `V6CAccumulatorPlanning` (M8)
passes track register values within a single basic block. When
`V6C_BR_CC16_IMM` splits an MBB into two blocks for the high-byte
comparison, the second block starts with no knowledge of register values
from the first block. This causes redundant immediate loads.

### Example: comparing i16 against 0 (NE condition)

```asm
; BB0 (original MBB):
    MVI  A, 0           ; 7cc, 2B — A is now known to be 0
    CMP  L              ; 4cc, 1B — CMP does NOT modify A
    JNZ  Target         ; 10cc, 3B

; BB1 (CompareHiMBB, created by MBB split):
    MVI  A, 0           ; 7cc, 2B — REDUNDANT! A is still 0 from BB0
    CMP  H              ; 4cc, 1B
    JNZ  Target         ; 10cc, 3B
    JMP  Fallthrough    ; 10cc, 3B
```

The second `MVI A, 0` is redundant because:
1. `CMP` does not modify the accumulator (only FLAGS)
2. `JNZ` does not modify any registers
3. BB1 has exactly one predecessor (BB0)
4. A is known to hold 0 at the end of BB0

### After optimization:
```asm
; BB0:
    MVI  A, 0           ; 7cc, 2B
    CMP  L              ; 4cc, 1B
    JNZ  Target         ; 10cc, 3B

; BB1 (CompareHiMBB):
    ; (MVI A, 0 removed — A already holds 0)
    CMP  H              ; 4cc, 1B
    JNZ  Target         ; 10cc, 3B
    JMP  Fallthrough    ; 10cc, 3B
```

Saves **1B + 7cc** per instance.

### Broader applicability

This pattern appears beyond just BR_CC16_IMM zero comparisons:

1. **BR_CC16_IMM with any repeated immediate**: When lo8 == hi8 (e.g.,
   comparing against 0x0101, 0x4242), the second MVI is redundant.
2. **Sequential basic blocks with known accumulator value**: Any case where
   a single-predecessor block starts with `MVI A, imm` and the predecessor
   exits with A holding that same value.
3. **Loop headers**: A loop body ending with A=const, and the loop header
   starting with `MVI A, const`.

## Implementation

### Approach: Extend V6CLoadImmCombine with cross-BB propagation

Add an optional cross-BB propagation pass to `V6CLoadImmCombine.cpp`:

```cpp
/// For blocks with a single predecessor, initialize KnownVal[] from
/// the predecessor's exit state (if available).
void V6CLoadImmCombine::initFromPredecessor(MachineBasicBlock &MBB) {
  if (MBB.pred_size() != 1)
    return;  // Only single-predecessor blocks (safe, conservative)

  MachineBasicBlock *Pred = *MBB.pred_begin();

  // Walk backward from end of Pred to determine known register values.
  // Stop at the first instruction that makes a value unknown.
  // This is a simplified version of the forward scan — we only look
  // at the last few instructions before the terminator.

  // Reset all values to unknown.
  resetKnownValues();

  // Forward-scan the predecessor to compute exit state.
  for (MachineInstr &MI : *Pred) {
    updateKnownValues(MI);  // existing tracking logic
  }

  // Now KnownVal[] reflects the predecessor's exit register state.
  // The per-BB forward scan in the current block will use these as
  // initial values and can eliminate redundant MVIs.
}
```

### Alternative: Fix at the source (V6C_BR_CC16_IMM expansion)

Instead of general cross-BB propagation, the expansion code in
`V6CInstrInfo.cpp` that creates CompareHiMBB could check whether lo8 == hi8
and skip the second MVI:

```cpp
// In V6C_BR_CC16_IMM expansion, NE path:
{
  auto MIB = BuildMI(CompareHiMBB, DL, get(V6C::MVIr), V6C::A);
  addImmHi(MIB);
}

// Could become:
if (lo8 != hi8) {
  auto MIB = BuildMI(CompareHiMBB, DL, get(V6C::MVIr), V6C::A);
  addImmHi(MIB);
}
// When lo8 == hi8, A already holds the correct value from BB0.
```

This is simpler but less general. The first approach (cross-BB propagation)
handles more cases.

### Recommended approach

Implement both:
1. **Quick fix**: Check lo8 == hi8 in BR_CC16_IMM expansion (~5 lines)
2. **General**: Cross-BB propagation in LoadImmCombine for single-predecessor
   blocks (~30-40 lines)

### Note on O27 interaction

If O27 (i16 zero-test) is implemented first, the main motivating case
(comparing against 0) is eliminated entirely — there's no MBB split and
no second MVI at all. O29 remains valuable for:
- Non-zero immediate comparisons where lo8 == hi8
- Other cross-BB patterns unrelated to comparisons
- Comparisons against global addresses (where MBB split still occurs)

## Benefit

- **1B + 7cc** per eliminated MVI
- **Frequency**: Medium — fires for BR_CC16_IMM when lo8(rhs) == hi8(rhs),
  and for other cross-BB patterns with known accumulator values
- Partially subsumed by O27 for the zero case

## Complexity

Low (quick fix in expansion: ~5 lines) to Medium (general cross-BB
propagation: ~30-40 lines in LoadImmCombine).

## Risk

Low. The quick fix is trivially correct (CMP doesn't modify A). The general
approach is conservative: only propagates through single-predecessor edges,
using the same value-tracking logic already proven in O13.

## Dependencies

- O13 (Load-Immediate Combining) — already complete; provides the tracking
  infrastructure to extend.
- O27 (i16 zero-test) — if implemented, subsumes the main motivating case
  but O29 remains useful for non-zero comparisons.
