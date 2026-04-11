# O2. Sequential Address Reuse (LXI → INX Folding)

## Problem

When loading from consecutive addresses, the compiler materializes each
address with a full `LXI HL, imm16` (10cc, 3 bytes). After `MOV A, M` the
HL register still holds the same address, so `INX HL` (6cc, 1 byte) suffices
for the next address.

## Before → After

```asm
; Before                          ; After
LXI  HL, 0     ; 10cc            LXI  HL, 0     ; 10cc
MOV  A, M      ;  8cc            MOV  A, M      ;  8cc
...                               ...
LXI  HL, 1     ; 10cc  ← costly  INX  HL        ;  6cc
MOV  A, M      ;  8cc            MOV  A, M      ;  8cc
...                               ...
LXI  HL, 2     ; 10cc  ← costly  INX  HL        ;  6cc
MOV  A, M      ;  8cc            MOV  A, M      ;  8cc
```

## Implementation

**Option A — Post-RA peephole** (recommended first step):
Scan for `LXI HL, N` where a preceding `LXI HL, M` (with `M < N`, `N - M ≤ 3`)
is visible and HL was not modified between the two LXIs. Replace with
`(N - M)` × `INX HL`. Similarly for decrements with DCX.

Challenge: HL is clobbered by `V6C_LOAD8_P` (declared `Defs = [HL]`).
After expansion, the actual `MOVrM` does NOT clobber HL, but the register
allocator has already treated it as dead. The peephole must track actual
physical HL state post-expansion, not rely on pre-RA liveness.

**Option B — Remove `Defs = [HL]` for HL-addressed loads**:
When `V6C_LOAD8_P` addr operand is already HL, the expansion is just
`MOV dst, M` — HL is preserved. An implicit-def of HL is only needed when
address is in BC/DE (copy to HL clobbers it). This would let the register
allocator know HL is still live, enabling natural sequential reuse.

Requires splitting V6C_LOAD8_P into two variants or adding a dynamic
implicit-def during ISel.

## Benefit

- **Savings per instance**: 4cc + 2 bytes per replaced LXI
- **Frequency**: Common in array traversals, struct field access, sequential
  volatile reads
- **Test case savings**: 8cc (two LXI → INX replacements)

## Complexity

- Option A: Medium. ~50 lines in peephole. Must track HL state carefully.
- Option B: Medium-high. Changes ISel pseudo semantics. Needs thorough
  regression testing.

## Risk

- Option A: Low-medium. Only affects code after the peephole; wrong HL
  tracking produces wrong code. Bounded blast radius.
- Option B: Medium. Changing `Defs` affects register allocation globally.
  Must verify no HL liveness bugs in complex control flow.
