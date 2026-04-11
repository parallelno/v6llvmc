# O15. Conditional Call Optimization (Branch-over-Call → CC/CZ etc.)

*Inspired by jacobly0 Z80 `Z80MachineEarlyOptimization`.*
*Detailed analysis: [llvm_z80_analysis.md](llvm_z80_analysis.md) §S2.*

## Problem

The V6C backend emits branch-over-call patterns for conditional function calls:

```asm
  JZ  skip        ; 12cc, 3B  (branch if condition false)
  CALL target     ; 18cc, 3B
skip:
```

The 8080 has dedicated conditional call instructions (CC, CNC, CZ, CNZ, CP, CM,
CPE, CPO) that combine the test and call into one instruction — but V6C never
emits them.

## Before → After

```asm
; Before                          ; After
JZ   skip       ; 12cc, 3B       CNZ  target      ; 18cc, 3B (taken)
CALL target     ; 18cc, 3B                         ; 12cc, 3B (not taken)
skip:
; Total: 30cc taken, 12cc not     ; Total: 18cc taken, 12cc not taken
; 6 bytes                         ; 3 bytes
```

## Implementation

Pre-RA `MachineFunctionPass`:
1. Scan for conditional branch → fallthrough to block containing a single CALL
2. Verify the call block has only the CALL (+ optional result copies below a
   cost threshold)
3. Replace the branch + call with the corresponding conditional CALL opcode
4. Move result copies, preserve flag register across the transformation

Uses a cost threshold (`cond-call-threshold`) to avoid conversion when the
"then" block has too many non-call instructions that would all become
unconditional.

## Benefit

- **Savings per instance**: 3 bytes always; 12cc when call is taken
- **Frequency**: Medium — wrapper functions, error handling branches, dispatch
- **Side benefit**: Reduces basic block count → less branch overhead

## Complexity

Medium. ~80-100 lines. Requires analyzing the branch target block structure
and carefully handling result register COPYs.

## Risk

Low. Both `JNZ target / CALL fn / target:` and `CNZ fn` have identical
semantics. Only applies when the skipped block contains just the call.
