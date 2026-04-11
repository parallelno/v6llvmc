# O12. Global Copy Optimization (Cross-BB)

*Inspired by llvm-mos `MOSCopyOpt`.*
*Detailed analysis: [llvm_mos_analysis.md](llvm_mos_analysis.md) §S3.*

## Problem

V6C's current peephole (`V6CPeephole.cpp`) only analyzes within a single
basic block. Copy chains that span basic blocks — common after register
allocation when values flow through multiple blocks via copies — are missed.

## How llvm-mos Does It

`MOSCopyOpt` performs three inter-BB optimizations on COPY instructions:

1. **Copy forwarding**: For `COPY dst, src`, finds all reaching definitions
   of `src` across BBs. If all are `COPY src, newSrc` with the same `newSrc`,
   rewrites to `COPY dst, newSrc` (when `copyCost(dst, newSrc) ≤ copyCost(dst, src)`).
2. **Load-immediate rematerialization**: If all reaching defs of a COPY source
   are the same `MoveImmediate`, rematerializes the immediate at the use site.
3. **Dead copy elimination**: Removes copies with dead destinations, then
   recomputes basic block liveness.

Uses `findReachingDefs()` — backward walk through predecessor blocks with
visited-set tracking — and `isClobbered()` — forward walk from each reaching
def to verify the new source isn't modified along any path.

## V6C Adaptation

- Replace the COPY-centric logic with `MOV`-centric logic for V6C physical
  registers (post-RA, all registers are physical).
- Use `V6CInstrCost` ([O11](O11_dual_cost_model.md)) for copy cost comparisons.
- The reaching-def infrastructure translates directly — `modifiesRegister()`
  with TRI works the same way.
- **Supersedes O1** (single-BB redundant MOV elimination) — O12 catches
  everything O1 catches plus cross-BB patterns and immediate rematerialization.

## Before → After

```asm
; BB1:                              ; BB1:
  MOV  A, M      ;  8cc              MOV  A, M      ;  8cc
  MOV  C, A       ;  8cc             MOV  C, A       ;  8cc
  JNZ  BB2                           JNZ  BB2
; BB2:                              ; BB2:
  MOV  A, C       ;  8cc  ← elim    ADD  E          ;  4cc  (A already == C's value)
  ADD  E          ;  4cc
```

## Benefit

- **Savings per instance**: 8cc + 1 byte per eliminated copy
- **Frequency**: Very high — copy chains after regalloc are pervasive
- **Compound effect**: Fewer live ranges → less register pressure → fewer spills

## Complexity

Medium. ~200 lines. Inter-BB analysis requires careful handling of loop
back-edges and entry block boundaries.

## Risk

Low. Only rewrites when provably cheaper and not clobbered along any path.
