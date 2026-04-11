# O4. ADD M / SUB M Direct Memory Operand

## Problem

When adding a value loaded from memory, the compiler emits `MOV A, M` into
A followed by `ADD r` (or materializes into a register first). The 8080 has
`ADD M` (8cc) which adds `[HL]` directly to A, saving the intermediate
register load.

## Before → After

```asm
; Before                          ; After
MOV  A, M      ;  8cc            ADD  M         ;  8cc  (skips MOV, uses M directly)
ADD  C          ;  4cc = 12cc
```

## Implementation

Requires ISel patterns or a post-RA peephole to detect:
- `V6C_LOAD8_P` into register X, followed immediately by `ADD/SUB X`
  where X is dead after → replace with `ADD M` / `SUB M`

This only works when the address is already in HL (no extra copy needed)
and the loaded value has a single use.

## Benefit

- **Savings per instance**: 4-8cc + 1 byte
- **Frequency**: Common in reduction loops, accumulation patterns
- **Test case savings**: ~16cc (two load+add pairs)

## Complexity

Medium. Need to ensure HL setup is already complete and no intervening
instructions modify HL or need the loaded value separately.

## Risk

Low-medium. The transformation is local and only applies when the load
result is single-use. Wrong liveness analysis can drop needed values.
