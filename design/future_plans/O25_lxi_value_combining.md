# O25. LXI 16-bit Value Combining

*From plan_load_immediate_combining.md Future Enhancements.*
*Extension of O13 (8-bit register value tracking) to 16-bit register pairs.*

## Problem

O13 tracks 8-bit register values and replaces redundant `MVI r, imm` with
`MOV r, r'` or `INR/DCR`. However, it does not track 16-bit register pair
values. Redundant `LXI rp, imm` instructions appear when:

- A loop re-initializes a register pair to the same constant each iteration
- Multiple basic blocks load the same constant into the same pair
- After a function call, the compiler reloads a constant that was in a
  callee-saved pair

### Example:
```asm
    LXI  DE, 1000         ; 10cc, 3B
    ; ... use DE ...
    LXI  DE, 1000         ; 10cc, 3B  ← redundant, DE still holds 1000
```

### After optimization:
```asm
    LXI  DE, 1000         ; 10cc, 3B
    ; ... use DE ...
    ; (second LXI removed)
```

### Cross-pair combining:
```asm
    LXI  HL, 1000         ; 10cc, 3B
    ; ... HL used and still holds 1000 ...
    LXI  DE, 1000         ; 10cc, 3B  ← can become MOV D,H; MOV E,L (16cc, 2B)
```

When both pairs hold the same value, `MOV D,H; MOV E,L` (16cc, 2B) saves
1B vs `LXI DE, 1000` (10cc, 3B). **This trades 6cc for 1B** — beneficial
in size-optimized builds (-Os/-Oz) per the O11 dual cost model.

## Implementation

Extend `V6CLoadImmCombine.cpp` to track 16-bit pair values alongside
existing 8-bit tracking:

### Value tracking additions
```cpp
// Existing: int8 KnownVal[7] for A, B, C, D, E, H, L
// New: add pair-level tracking
std::optional<uint16_t> PairVal[3]; // BC=0, DE=1, HL=2

// LXI sets both sub-regs AND the pair value
case V6C::LXIrp:
  PairVal[pairIdx] = Imm;
  KnownVal[hiIdx] = (Imm >> 8) & 0xFF;
  KnownVal[loIdx] = Imm & 0xFF;
  break;

// Any write to a sub-reg invalidates the pair
// (unless both sub-regs are known and match)
```

### Combining rules
1. **LXI elimination**: If `PairVal[rp] == imm`, remove the `LXI`
2. **Cross-pair LXI→MOV pair**: If another pair holds the same 16-bit value,
   replace `LXI rp, imm` with two MOVs (saves 1B, costs +6cc) — only in
   Size mode per O11
3. **LXI→INX/DCX**: If `PairVal[rp] == imm ± 1`, replace `LXI rp, imm`
   with `INX/DCX rp` (saves 4cc + 2B)

### Invalidation
- LXI: sets pair value
- INX/DCX: if pair value known, update ±1; else invalidate
- MOV to sub-reg: invalidate pair (unless resulting pair can be computed)
- XCHG: swap DE and HL pair values
- CALL, POP, LHLD: invalidate affected pair
- Any indirect write (MOV M, r): does not affect pair tracking

## Benefit

- **LXI elimination**: 10cc + 3B per instance
- **LXI→INX/DCX**: 4cc + 2B per instance
- **Frequency**: Medium — sequential address computations and loop constants
- **Indirect**: Reduced code size → fewer cache-like effects on V6C's
  small memory

## Complexity

Low-Medium. ~30-40 lines added to existing `V6CLoadImmCombine.cpp`.
The 8-bit tracking infrastructure already exists — just needs pair overlay.

## Risk

Very Low. Same forward-scan algorithm as O13. Conservative invalidation
ensures correctness.

## Dependencies

O13 (Load-Immediate Combining) — already complete. This extends it.
O11 (Dual Cost Model) — already complete. Used for size-vs-speed decisions.

## Testing

1. New lit test: `lxi-combining.ll` — elimination, cross-pair, INX/DCX cases
2. Golden test regression check
