# O54. Optimal Stack Adjustment Strategy

*Inspired by jacobly0 `Z80FrameLowering::getOptimalStackAdjustmentMethod()`.*
*Detailed analysis: [llvm_z80_analysis.md](llvm_z80_analysis.md) §S4.*

## Problem

V6C currently uses a fixed approach for stack pointer adjustment in function
prologues/epilogues: `LXI HL, -N; DAD SP; SPHL` (9 bytes, 32cc). For small
adjustments this is wasteful — there are cheaper alternatives.

## Strategy Table

| SP Adjustment | Current V6C | Optimal Method | Bytes | Cycles |
|---------------|-------------|----------------|-------|--------|
| +2 or -2 | LXI+DAD+SPHL (9B, 32cc) | `POP PSW` or `PUSH PSW` (1B, 12cc) | 1 | 12 |
| +4 | LXI+DAD+SPHL (9B, 32cc) | `POP PSW; POP PSW` (2B, 24cc) | 2 | 24 |
| +6 | LXI+DAD+SPHL (9B, 32cc) | `POP PSW; POP PSW; POP PSW` (3B, 36cc) | 3 | 36 |
| ≥8 | LXI+DAD+SPHL (9B, 32cc) | `LXI HL, N; DAD SP; SPHL` (9B, 32cc) | 9 | 32 |

For SP **increment** (deallocating stack space), `POP rr` increments SP by 2
using only 1 byte and 12cc. The register it pops into doesn't matter if that
register is dead. `POP PSW` (A + flags) is the safest choice assuming A and
flags are dead at the epilogue (they usually are before RET).

For SP **decrement**, `PUSH rr` decrements SP by 2 using 1 byte and 12cc.
Any dead register pair can be pushed — the value stored is garbage.

## Implementation

In `V6CFrameLowering::emitPrologue()` and `emitEpilogue()`:

```cpp
void adjustSP(MachineBasicBlock &MBB, MachineBasicBlock::iterator MBBI,
              int Amount, const DebugLoc &DL) {
  // Amount > 0 = increment SP (deallocate), Amount < 0 = decrement
  unsigned AbsAmount = std::abs(Amount);

  if (AbsAmount <= 6 && (AbsAmount % 2 == 0)) {
    // POP/PUSH strategy: 1B per 2 bytes adjusted
    unsigned Opc = (Amount > 0) ? V6C::POP_PSW : V6C::PUSH_PSW;
    for (unsigned i = 0; i < AbsAmount / 2; i++) {
      BuildMI(MBB, MBBI, DL, TII->get(Opc));
    }
  } else {
    // LXI+DAD+SPHL for large or odd adjustments
    BuildMI(MBB, MBBI, DL, TII->get(V6C::LXI), V6C::HL).addImm(Amount);
    BuildMI(MBB, MBBI, DL, TII->get(V6C::DAD), V6C::HL).addReg(V6C::SP);
    BuildMI(MBB, MBBI, DL, TII->get(V6C::SPHL));
  }
}
```

## Before → After

```asm
; Before: deallocate 4 bytes        ; After: deallocate 4 bytes
LXI  HL, 4      ; 12cc, 3B         POP  PSW    ; 12cc, 1B
DAD  SP          ; 12cc, 1B         POP  PSW    ; 12cc, 1B
SPHL             ;  8cc, 1B
; Total: 32cc, 5B                    ; Total: 24cc, 2B
```

## Benefit

- **Savings per instance**: 3-7B and 8-20cc for small frame adjustments
- **Frequency**: Medium — most functions have stack frames in the 2-6 byte range
- **Breakeven**: At 8+ bytes, POP strategy (4B, 48cc) is worse than LXI+DAD+SPHL
  (5B, 32cc) on cycles but still saves 1B; at 6 bytes they tie on bytes (3 vs 5B)

## Complexity

Low. ~30 lines in frame lowering. Decision logic is simple size comparison.

## Risk

Low. `POP PSW` clobbers A and flags, but both are dead at function epilogue
(before RET). For prologue (`PUSH PSW`), the pushed garbage value is
irrelevant — only the SP decrement matters. Must verify A/flags liveness
at adjustment points.

## Dependencies

None. Independent of all other optimizations. But interacts with O10 (static
stack) — functions using static stack don't have dynamic SP adjustments, so
this only benefits functions that still use the hardware stack.
