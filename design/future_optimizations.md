# Future Optimizations — V6C Backend

Reference test case throughout: `temp/compare/05/v6llvmc.c`
```c
char a = *(volatile char*)0x0;
char b = *(volatile char*)0x1;
char c = *(volatile char*)0x2;
return a + b + c;
```

Current v6llvmc output (after INX/DCX peephole fix):
```asm
LXI  HL, 0       ; 10cc
MOV  A, M         ;  8cc   a = *(0)
MVI  E, 0         ;  8cc
MOV  B, E         ;  8cc   BC.hi = 0
MOV  C, A         ;  8cc   BC = zext(a)
LXI  HL, 1       ; 10cc
MOV  A, M         ;  8cc   b = *(1)
MOV  H, E         ;  8cc
MOV  L, A         ;  8cc   HL = zext(b)
MOV  A, L         ;  8cc   ← redundant, A already == b
ADD  C            ;  4cc
MOV  C, A         ;  8cc
MOV  A, H         ;  8cc
ADC  B            ;  4cc
MOV  B, A         ;  8cc   BC = a + b
LXI  HL, 2       ; 10cc
MOV  A, M         ;  8cc   c = *(2)
MOV  H, E         ;  8cc
MOV  L, A         ;  8cc   HL = zext(c)
DAD  BC           ; 12cc
RET               ; 12cc
; Total: ~174cc, 20 instructions, 20 bytes
```

Ideal hand-written output:
```asm
LXI  HL, 0       ; 10cc
MOV  A, M         ;  8cc   a
INX  HL           ;  6cc
ADD  M            ;  8cc   a + b
INX  HL           ;  6cc
ADD  M            ;  8cc   a + b + c
MOV  L, A         ;  8cc
MVI  H, 0         ;  8cc
RET               ; 12cc
; Total: 74cc, 9 instructions, 12 bytes
```

For comparison, c8080 output: 344cc, 47 bytes (uses memory temporaries + library call for sign-extend).

---

## O1. Redundant MOV Elimination after BUILD_PAIR + ADD16

### Problem

`V6C_ADD16` expansion emits `MOV A, LhsLo` unconditionally. When the
preceding `V6C_BUILD_PAIR` just did `MOV L, A`, the accumulator already
holds the value. The resulting `MOV A, L` is a no-op.

### Before → After

```asm
; Before                          ; After
MOV  H, E      ;  8cc            MOV  H, E      ;  8cc
MOV  L, A      ;  8cc            MOV  L, A      ;  8cc
MOV  A, L      ;  8cc  ← dead    ADD  C         ;  4cc
ADD  C          ;  4cc            MOV  C, A      ;  8cc
MOV  C, A       ;  8cc           ...
```

### Implementation

Extend `V6CPeephole::eliminateRedundantMov()` to catch the pattern:
`MOV dst, A` followed (with no A/dst clobber in between) by `MOV A, dst`
→ remove the second MOV.

The existing peephole already handles `MOV A, X; MOV A, X` (duplicate
loads into A). This extends it to the symmetric `MOV X, A; ... MOV A, X`
case when neither A nor X is modified between them.

### Benefit

- **Savings per instance**: 8cc, 1 instruction, 1 byte
- **Frequency**: Very common — every `zext i8 → i16` + `add i16` pair
- **Test case savings**: 16cc (two instances)

### Complexity

Low. ~20 lines added to the existing peephole pass. Pattern is local
(within a basic block, bounded scan window).

### Risk

Low. Only removes provably redundant copies. The existing `eliminateRedundantMov`
infrastructure already handles the safety checks (no clobber between).

---

## O2. Sequential Address Reuse (LXI → INX Folding)

### Problem

When loading from consecutive addresses, the compiler materializes each
address with a full `LXI HL, imm16` (10cc, 3 bytes). After `MOV A, M` the
HL register still holds the same address, so `INX HL` (6cc, 1 byte) suffices
for the next address.

### Before → After

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

### Implementation

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

### Benefit

- **Savings per instance**: 4cc + 2 bytes per replaced LXI
- **Frequency**: Common in array traversals, struct field access, sequential
  volatile reads
- **Test case savings**: 8cc (two LXI → INX replacements)

### Complexity

- Option A: Medium. ~50 lines in peephole. Must track HL state carefully.
- Option B: Medium-high. Changes ISel pseudo semantics. Needs thorough
  regression testing.

### Risk

- Option A: Low-medium. Only affects code after the peephole; wrong HL
  tracking produces wrong code. Bounded blast radius.
- Option B: Medium. Changing `Defs` affects register allocation globally.
  Must verify no HL liveness bugs in complex control flow.

---

## O3. Narrow-Type Arithmetic (i8 Chain Instead of i16)

### Problem

The LLVM IR frontend emits `zext i8 → i16` before every arithmetic
operation, even when all operands are `i8` and the result only needs
widening at the final use (e.g., return value). This forces the backend
to generate 16-bit add chains (6 instructions, ~40cc each) when a single
8-bit `ADD r` (4cc) would suffice.

### Before → After (Ideal)

```asm
; Before (current: 3 zext + 2 ADD16)  ; After (narrow chain + 1 zext)
LXI  HL, 0                            LXI  HL, 0       ; 10cc
MOV  A, M                             MOV  A, M         ;  8cc
MVI  E, 0                             INX  HL           ;  6cc
MOV  B, E                             ADD  M            ;  8cc  ← 8-bit add
MOV  C, A                             INX  HL           ;  6cc
LXI  HL, 1                            ADD  M            ;  8cc  ← 8-bit add
MOV  A, M                             MOV  L, A         ;  8cc
MOV  H, E                             MVI  H, 0         ;  8cc  ← single zext
MOV  L, A                             RET               ; 12cc
MOV  A, L                             ; Total: 74cc
ADD  C
MOV  C, A
MOV  A, H
ADC  B
MOV  B, A
LXI  HL, 2
MOV  A, M
MOV  H, E
MOV  L, A
DAD  BC
RET
; Total: 174cc
```

### Implementation

**Approach: Custom DAGCombine to sink `zext` past `add`.**

In `V6CISelLowering::PerformDAGCombine`, match the pattern:
```
(add (zext i8:$a), (zext i8:$b))  →  (zext (add i8:$a, i8:$b))
```

This is valid when the `add` has `nuw` (no unsigned wrap) or when the
result is only used in further additions/stores (not in comparisons that
depend on the full 16-bit range). For the general case, it's valid when
the wider add has `nuw nsw` flags (which Clang emits for small unsigned
values).

Upstream LLVM has `ReduceWidth` and `TruncInstCombine` passes but they
operate on LLVM IR and often miss target-specific opportunities. A
DAGCombine is more reliable for the V6C case.

### Benefit

- **Savings**: Replaces 16-bit arithmetic (6 insns, ~40cc) with 8-bit
  (1 insn, 4-8cc) per operation. Eliminates intermediate `zext` materialization.
- **Frequency**: Extremely common in `uint8_t` array processing, character
  manipulation, sensor data aggregation.
- **Test case savings**: ~100cc (from 174cc to ~74cc)

### Complexity

High. Requires careful handling of:
- `nuw`/`nsw` flag propagation
- Multi-use values (if a zext result is used elsewhere, can't eliminate it)
- Carry semantics (8-bit add wraps at 256, 16-bit doesn't)
- Interaction with existing BUILD_PAIR / ADD16 patterns

### Risk

Medium-high. Incorrect narrowing can silently produce wrong results for
values that overflow 8 bits. Needs extensive test coverage with boundary
values (127, 128, 255, 256).

---

## O4. ADD M / SUB M Direct Memory Operand

### Problem

When adding a value loaded from memory, the compiler emits `MOV A, M` into
A followed by `ADD r` (or materializes into a register first). The 8080 has
`ADD M` (8cc) which adds `[HL]` directly to A, saving the intermediate
register load.

### Before → After

```asm
; Before                          ; After
MOV  A, M      ;  8cc            ADD  M         ;  8cc  (skips MOV, uses M directly)
ADD  C          ;  4cc = 12cc
```

### Implementation

Requires ISel patterns or a post-RA peephole to detect:
- `V6C_LOAD8_P` into register X, followed immediately by `ADD/SUB X`
  where X is dead after → replace with `ADD M` / `SUB M`

This only works when the address is already in HL (no extra copy needed)
and the loaded value has a single use.

### Benefit

- **Savings per instance**: 4-8cc + 1 byte
- **Frequency**: Common in reduction loops, accumulation patterns
- **Test case savings**: ~16cc (two load+add pairs)

### Complexity

Medium. Need to ensure HL setup is already complete and no intervening
instructions modify HL or need the loaded value separately.

### Risk

Low-medium. The transformation is local and only applies when the load
result is single-use. Wrong liveness analysis can drop needed values.

---

## O5. BUILD_PAIR(x, 0) + ADD16 Fusion

### Problem

Zero-extending `i8` to `i16` generates `BUILD_PAIR(val, 0)` which becomes
`MOV hi, 0; MOV lo, val`. The subsequent `ADD16` then does a full 6-instruction
chain including `ADC hi` which is just `ADC 0` (carry propagation only).

### Before → After

```asm
; Before (BUILD_PAIR + ADD16)     ; After (fused)
MOV  H, E      ;  8cc (H = 0)    ADD  C         ;  4cc
MOV  L, A      ;  8cc             MOV  C, A      ;  8cc
MOV  A, L      ;  8cc             MOV  A, B      ;  8cc
ADD  C          ;  4cc             ACI  0         ;  8cc  (or ADC E if E==0)
MOV  C, A       ;  8cc            MOV  B, A      ;  8cc
MOV  A, H       ;  8cc            ; Total: 36cc
ADC  B          ;  4cc
MOV  B, A       ;  8cc
; Total: 56cc
```

Or better, when the high byte of one operand is known-zero:
```asm
ADD  C          ;  4cc            ; low add
MOV  C, A       ;  8cc
MVI  A, 0       ;  8cc            ; high = 0 + B + carry
ADC  B          ;  4cc
MOV  B, A       ;  8cc
; Total: 32cc
```

### Implementation

In `expandPostRAPseudo` for `V6C_ADD16`, detect when one operand's high
sub-register was defined by `MVI reg, 0` (scan backward, similar to
`findDefiningLXI`). If so, emit a shorter sequence that skips the high
byte load (use `MVI A, 0; ADC hi` instead of `MOV A, hi; ADC hi`).

### Benefit

- **Savings per instance**: 16-24cc
- **Frequency**: Every `zext i8 → i16` followed by 16-bit arithmetic
- **Test case savings**: ~32cc

### Complexity

Medium. Similar to the existing INX/DCX constant detection. ~30 lines
in the ADD16 expansion.

### Risk

Low-medium. Must correctly identify the zero high byte. False positives
if the MVI 0 was overwritten. Use same TRI-aware scanning as the
`findDefiningLXI` fix.

---

## O6. LDA/STA for Absolute Address Loads

### Problem

Loading from a known constant address currently generates `LXI HL, addr`
(10cc, 3 bytes) + `MOV A, M` (8cc, 1 byte) = 18cc, 4 bytes.
The 8080 has `LDA addr` (16cc, 3 bytes) which loads directly from a
16-bit address into A — fewer bytes and comparable speed.

### Before → After

```asm
; Before                          ; After
LXI  HL, 0     ; 10cc, 3B        LDA  0         ; 16cc, 3B
MOV  A, M      ;  8cc, 1B        ; saves 1 byte, 2cc slower
; Total: 18cc, 4B                 ; Total: 16cc, 3B  ← actually FASTER
```

Note: on standard i8080, LDA is 13cc and LXI+MOV is 17cc. On Vector 06c
the timings differ (LDA = 16cc, LXI = 10cc, MOV r,M = 8cc = 18cc total).
So LDA saves 2cc AND 1 byte.

### Implementation

ISel pattern: when loading `i8` from a constant address into A, select
`LDA` instead of `LXI` + `V6C_LOAD8_P`. Similarly `STA` for stores.

### Benefit

- **Savings per instance**: 2cc + 1 byte
- **Frequency**: Common in memory-mapped I/O, global variable access
- **Test case savings**: 6cc (three absolute loads)

### Complexity

Low. Simple ISel pattern addition.

### Risk

Low. LDA/STA are well-defined 8080 instructions. Only affects loads/stores
where dest/src is A and address is a constant.

---

## O7. Loop Strength Reduction via TargetTransformInfo

### Problem

The V6C backend generates `base + i` address recomputation on every loop
iteration instead of maintaining and incrementing a pointer. For a simple
array copy:

```c
for (uint8_t i = 0; i < 100; i++)
    array2[i] = array1[i];
```

Each `base + i` costs at minimum 24cc (`LXI` + `DAD`). With two arrays, the
loop body pays ~48cc for address computation alone, plus ~100cc+ of spill
overhead to manage intermediate values.

### Before → After

```asm
; Before (per iteration)               ; After (per iteration)
LXI  HL, array1     ; 12cc            MOV  A, M          ;  8cc  load via HL
; ... extend i to 16-bit ...           XCHG                ;  4cc
DAD  HL              ; 12cc            MOV  M, A          ;  8cc  store via HL (was DE)
MOV  A, M            ;  8cc            XCHG                ;  4cc
; ... spill, reload, recompute ...     INX  HL            ;  8cc  advance ptr1
LXI  HL, array2     ; 12cc            INX  DE            ;  8cc  advance ptr2
; ... extend i again ...               ; ... compare & branch ...
DAD  HL              ; 12cc
MOV  M, A            ;  8cc
; ~200cc+ with spills                  ; ~40cc
```

### Root Cause

LLVM has a built-in Loop Strength Reduction pass (`-loop-reduce`), but it
makes cost decisions through `TargetTransformInfo` (TTI) hooks. V6C has
**no TTI implementation** — it falls back to defaults that assume reg+reg
addressing is free and the target has 32-bit registers. These defaults prevent
LSR from making correct transformations for the 8080.

### Implementation

Implement `V6CTargetTransformInfo` class with key hooks:

| Hook | V6C Value |
|------|-----------|
| `isLegalAddressingMode()` | Only reg indirect, no offset |
| `getAddressComputationCost()` | Non-zero (initial: 2) |
| `getNumberOfRegisters()` | 3 (register pairs) |
| `getRegisterBitWidth()` | 16 bits |
| `isNumRegsMajorCostOfLSR()` | `true` |
| `isLSRCostLess()` | Prioritize fewer regs over fewer insns |

This teaches LLVM's existing LSR pass about the 8080's constraints without
writing a custom loop optimization pass.

**Detailed plan**: [plan_loop_strength_reduction.md](plan_loop_strength_reduction.md)

### Benefit

- **Savings per iteration**: ~120-160cc for dual-array loops
- **Frequency**: Every loop with array/pointer indexing
- **Loop body speedup**: ~3-7× depending on spill pressure

### Complexity

Medium. Creates 4 new files (header, cpp, CMake addition, target machine
registration). The logic is declarative cost tuning, not a new pass.

### Risk

Medium. Incorrect cost parameters can cause LSR to make worse decisions
(e.g., using too many pointers → more spills). Requires tuning with
representative benchmarks (Step 3.9 in plan).

---

## O8. Spill Optimization (Tier 1/2 Strategy)

### Problem

Stack-relative addressing on the 8080 costs **~52cc per spill or reload**
(104cc per pair, 16 bytes) because there are no stack-relative load/store
instructions. Every stack access requires:

```asm
PUSH HL               ; save scratch pair
LXI  HL, offset       ; load stack offset
DAD  SP               ; HL = SP + offset
MOV  M, lo / MOV lo,M ; store/load low byte
INX  HL               ; advance pointer
MOV  M, hi / MOV hi,M ; store/load high byte
POP  HL               ; restore scratch pair
```

This dominates inner loops whenever two 16-bit pointers are live simultaneously.

### Tiered Approach

| Tier | Mechanism | Cost | Constraints |
|------|-----------|------|-------------|
| **T1** | PUSH/POP | 28cc/pair | Same-BB, LIFO nesting, no intervening branches/calls |
| **T2** | SHLD/LHLD or STA/LDA (global bss slots) | 40cc/pair | Non-reentrant, same-BB or cross-BB |
| **T3** | Current stack-relative (fallback) | 104cc/pair | Always safe |

Selection priority: T1 → T2 → T3. Each tier's constraints checked statically.

### Implementation

A new `V6CSpillOpt` MachineFunction pass running **before** `eliminateFrameIndex()`:

1. **Inventory**: Scan for SPILL/RELOAD pseudos, classify by slot
2. **LIFO analysis**: Check bracket nesting for T1 eligibility
3. **Safety checks**: FLAGS liveness (for PUSH PSW), intervening control flow,
   stack mutations
4. **Rewrite**: Convert eligible slots to PUSH/POP (T1) or global symbols (T2),
   erase original pseudos
5. **Integration**: Mark converted slots so frame lowering skips stack allocation

**Detailed design**: [design_improve_spilling.md](design_improve_spilling.md)

### Benefit

- **T1 savings**: 28cc vs 104cc per pair = **3.7× faster** spill-reload
- **T2 savings**: 40cc vs 104cc per pair = **2.6× faster**
- **Cascading**: Freed stack space → smaller frame → fewer prologue/epilogue cycles
- **Frequency**: Very high in any code with >1 live pointer (loops, struct access)

### Complexity

High. Requires LIFO verification algorithm, global symbol management,
integration with frame lowering pipeline (`MachineFrameInfo` slot marking,
prologue size adjustment).

### Risk

Medium-high. T1 is dangerous if LIFO nesting is violated (silent corruption).
T2 breaks reentrancy. Both require careful analysis and extensive testing.

---

## O9. Inline Assembly Completion (MC Asm Parser)

### Problem

Inline assembly (`asm()` / `__asm__`) works at the LLVM IR level — constraint
resolution (`getConstraintType`, `getRegForInlineAsmConstraint`) is implemented
and `-emit-llvm` verifies it. However, **assembly emission fails** because V6C
has no MC asm parser. The error is:

> "Inline asm not supported by this streamer because we don't have an asm
> parser for this target"

### Implementation

Implement a V6C MC asm parser that:
1. Parses 8080 mnemonics (`MOV`, `LXI`, `ADD`, etc.) from inline asm strings
2. Converts them to `MCInst` objects
3. Integrates with `AsmPrinter` for inline asm directive emission

This is essentially a mini-assembler within the MC layer.

**Reference**: [future_plans/inline_assembly.md](future_plans/inline_assembly.md)

### Benefit

- Enables inline 8080 assembly in C code for timing-critical sequences,
  I/O port handling, and custom instruction patterns
- Required for porting existing 8080 assembly libraries to the V6C C toolchain

### Complexity

High. An MC asm parser is a milestone-scale effort: lexer, parser, operand
matching, encoding, directive handling. Comparable to M3 (MC layer) in
original plan scope.

### Risk

Low (isolated). The parser is a new component with no impact on existing
codegen. Failures are compile-time errors, not silent miscompilation.

---

## Summary Table

| ID | Optimization | Savings/instance | Frequency | Complexity | Risk | Dependencies |
|----|-------------|-----------------|-----------|------------|------|-------------|
| O1 | Redundant MOV elimination | 8cc, 1B | Very high | Low | Low | None |
| O2 | Sequential LXI → INX | 4cc, 2B | High | Medium | Low-Med | None |
| O3 | Narrow-type arithmetic | 30-100cc | Very high | High | Med-High | None |
| O4 | ADD M / SUB M direct | 4-8cc, 1B | High | Medium | Low-Med | O2 helps |
| O5 | BUILD_PAIR(x,0)+ADD16 | 16-24cc | Very high | Medium | Low-Med | None |
| O6 | LDA/STA absolute addr | 2cc, 1B | Medium | Low | Low | None |
| O7 | Loop Strength Reduction (TTI) | 120-160cc/iter | High (loops) | Medium | Medium | None |
| O8 | Spill Optimization (T1/T2) | 64-76cc/pair | Very high | High | Med-High | None |
| O9 | Inline Assembly (MC parser) | N/A (feature) | N/A | High | Low | None |

### Recommended order

1. **O1** — trivial peephole, immediate benefit, no risk
2. **O6** — simple ISel pattern, standalone
3. **O5** — medium effort, high payoff on zext+add patterns
4. **O2** — medium effort, helps sequential access
5. **O4** — builds on O2 (HL already set up)
6. **O7** — medium effort, massive loop speedups, existing LLVM pass just needs cost info
7. **O3** — highest per-instance payoff but highest complexity
8. **O8** — high payoff for spill-heavy code, but complex pipeline integration
9. **O9** — feature enablement, milestone-scale effort, do when inline asm is needed

### Comparison with AVR

AVR's LLVM backend benefits from 32 GPRs, 3 pointer pairs (X/Y/Z), and
post-increment addressing (`LD r, Z+`). The i8080 has 7 registers, 1
pointer pair for general memory access (HL), and no auto-increment.

This means:
- **Register pressure** is the dominant bottleneck on V6C. AVR rarely spills;
  V6C spills often. Optimizations that reduce live ranges (O3, O5) have
  outsized impact.
- **Address setup cost** dominates on V6C. AVR's `LD r, Z+` is 2cc; V6C
  needs `INX HL` (6cc) or `LXI HL` (10cc). O2 and O4 directly address this.
- **Accumulator bottleneck** has no AVR equivalent. AVR's ALU works on any
  register. V6C funnels everything through A. O1 (eliminating redundant MOV
  through A) is V6C-specific and high impact.

### Reference: llvm-mos (6502)

The **llvm-mos** project (https://github.com/llvm-mos/llvm-mos) targets the
MOS 6502 — the closest architectural match to i8080 among LLVM backends.
It is accumulator-only with even fewer registers (A, X, Y; no register pairs).
Their backend solves many of the same problems we face:

- **Accumulator traffic reduction** — aggressive peephole passes to eliminate
  redundant LDA/STA (analogous to our O1)
- **Narrow-type optimization** — custom DAG combines to keep arithmetic in i8
  and defer widening (analogous to our O3)
- **Zero-page addressing** — exploits cheaper addressing modes for frequently
  accessed values (analogous to our O6 with LDA/STA)
- **Pseudo expansion with constant folding** — detects known-zero/known-constant
  operands during expansion to emit shorter sequences (analogous to our O5)

When implementing any optimization from this list, **check llvm-mos for prior
art first** — their solutions are battle-tested on a similarly constrained
architecture and can often be adapted directly.
