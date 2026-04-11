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

## O10. Static Stack Allocation for Non-Reentrant Functions

*Inspired by llvm-mos `MOSNonReentrant` + `MOSStaticStackAlloc`.*
*Detailed analysis: [llvm_mos_analysis.md](llvm_mos_analysis.md) §S1.*

### Problem

Stack-relative addressing costs ~52cc per access (see O8). For functions
that are provably non-reentrant (at most one active invocation at any time),
the entire stack frame can be replaced with a statically-allocated global
memory region — turning every spill/reload into a direct `LDA`/`STA` or
`LHLD`/`SHLD` (16-20cc).

### How llvm-mos Does It

Two passes working together:
1. **NonReentrant analysis** (IR-level, `ModulePass`): Walks the call graph
   bottom-up via SCC iteration. Single-node SCCs that don't call themselves
   are marked `norecurse`. Functions reachable from interrupts are marked
   reentrant. All remaining `norecurse` functions get the `nonreentrant`
   attribute.
2. **StaticStackAlloc** (`ModulePass`, runs post-RA): Builds an SCC DAG from
   the call graph, assigns static stack offsets per SCC (callers lower,
   callees higher — enabling memory overlap for disjoint call paths). Creates
   a single global `static_stack` array and per-function aliases into it.
   Rewrites all `TargetIndex` operands to `GlobalAddress`.

### V6C Adaptation

- The NonReentrant analysis is **target-independent** — reusable as-is.
- StaticStackAlloc needs adaptation for V6C frame lowering (different pseudo
  names, `MachineFrameInfo` conventions), but the SCC offset algorithm is
  directly reusable.
- **Supersedes O8 T2** (ad-hoc global bss variables) with automatic,
  optimally-packed static allocation with overlap analysis.
- O8 T1 (PUSH/POP) remains orthogonal and complementary — T1 for LIFO-safe
  slots within a BB, static stack for everything else.
- **Requires whole-program visibility** (LTO or single-TU compilation, which
  is the norm for 8080 programs).

### Benefit

- **Savings**: 52cc → 16-20cc per spill/reload access = **3-5× faster**
- **Frequency**: Every function with a stack frame (most non-trivial functions)
- **Cascading**: Eliminated stack frames → no prologue/epilogue overhead →
  smaller code

### Complexity

Medium. Two new passes. Call graph analysis is robust (borrowed from llvm-mos
who have battle-tested it). Frame lowering integration is the main work.

### Risk

Medium. Must correctly identify reentrant functions (interrupt handlers,
recursive calls). Conservative fallback (T3 stack-relative) is always safe.

---

## O11. Dual Cost Model (Bytes + Cycles)

*Inspired by llvm-mos `MOSInstrCost`.*
*Detailed analysis: [llvm_mos_analysis.md](llvm_mos_analysis.md) §S8.*

### Problem

V6C optimization decisions (peephole replacements, pseudo expansion choices,
copy elimination) are currently ad-hoc — each pass uses hardcoded heuristics.
There is no unified way to express "prefer speed" vs "prefer size" vs
"balanced". This leads to inconsistent decisions and makes it hard to add
`-Os`/`-Oz` support.

### How llvm-mos Does It

A simple `MOSInstrCost` class with two `int32_t` fields (Bytes, Cycles).
The `value()` method composes them based on optimization mode:
- `-Oz`: `(Bytes << 32) + Cycles` — bytes dominate
- `-O2`: `(Cycles << 32) + Bytes` — cycles dominate
- Default: `Bytes + Cycles` — balanced

Used in `copyCost()` for register-to-register copy decisions, and throughout
the backend wherever optimization tradeoffs exist.

### V6C Adaptation

Create `V6CInstrCost` with identical interface. Populate from the existing
instruction timing tables in [V6CInstructionTimings.md](../docs/V6CInstructionTimings.md).
Use in:
- `V6CPeephole` decisions (is INX cheaper than LXI in this context?)
- `expandPostRAPseudo` choices (shorter ADD16 sequence selection)
- Future copy optimization pass (O12)
- Any new optimization pass

### Benefit

- **Prevents regressions** when adding new optimizations
- **Enables `-Os`/`-Oz`** support for size-constrained targets
- **Foundation** for cost-aware passes (O12, O13)

### Complexity

Low. ~40 lines: header with struct + 3 methods, one `.cpp` with `getModeFor()`.

### Risk

Very Low. Informational infrastructure — no code transformation by itself.

---

## O12. Global Copy Optimization (Cross-BB)

*Inspired by llvm-mos `MOSCopyOpt`.*
*Detailed analysis: [llvm_mos_analysis.md](llvm_mos_analysis.md) §S3.*

### Problem

V6C's current peephole (`V6CPeephole.cpp`) only analyzes within a single
basic block. Copy chains that span basic blocks — common after register
allocation when values flow through multiple blocks via copies — are missed.

### How llvm-mos Does It

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

### V6C Adaptation

- Replace the COPY-centric logic with `MOV`-centric logic for V6C physical
  registers (post-RA, all registers are physical).
- Use `V6CInstrCost` (O11) for copy cost comparisons.
- The reaching-def infrastructure translates directly — `modifiesRegister()`
  with TRI works the same way.
- **Supersedes O1** (single-BB redundant MOV elimination) — O12 catches
  everything O1 catches plus cross-BB patterns and immediate rematerialization.

### Before → After

```asm
; BB1:                              ; BB1:
  MOV  A, M      ;  8cc              MOV  A, M      ;  8cc
  MOV  C, A       ;  8cc             MOV  C, A       ;  8cc
  JNZ  BB2                           JNZ  BB2
; BB2:                              ; BB2:
  MOV  A, C       ;  8cc  ← elim    ADD  E          ;  4cc  (A already == C's value)
  ADD  E          ;  4cc
```

### Benefit

- **Savings per instance**: 8cc + 1 byte per eliminated copy
- **Frequency**: Very high — copy chains after regalloc are pervasive
- **Compound effect**: Fewer live ranges → less register pressure → fewer spills

### Complexity

Medium. ~200 lines. Inter-BB analysis requires careful handling of loop
back-edges and entry block boundaries.

### Risk

Low. Only rewrites when provably cheaper and not clobbered along any path.

---

## O13. Load-Immediate Combining (Register Value Tracking)

*Inspired by llvm-mos `MOSLateOptimization::combineLdImm`.*
*Detailed analysis: [llvm_mos_analysis.md](llvm_mos_analysis.md) §S4.*

### Problem

After pseudo expansion, the emitted code often contains redundant `MVI r, imm`
instructions where another register already holds the needed value, or where
the target register already holds `imm ± 1`.

### How llvm-mos Does It

Forward scan through each basic block tracking the known constant value in
each register (A, X, Y). When a load-immediate is encountered:
1. If another register holds the same value → replace with register transfer
2. If a register holds value ± 1 → replace with INX/DEX/INY/DEY
3. Track transfers (TAX, TAY) to propagate known values across registers

### V6C Adaptation

Track known values in all 7 registers (A, B, C, D, E, H, L). Replacements:
- `MVI r, imm` → `MOV r, r'` when r' holds imm (saves 1 byte, same 8cc)
- `MVI r, imm` → `INR r` or `DCR r` when r holds imm±1 (saves 4cc + 1 byte)
- `MVI r, 0` → `MOV r, known_zero_reg` (extremely common for zext hi-byte)

### Before → After

```asm
; Before                          ; After
MVI  E, 0       ;  8cc, 2B       MVI  E, 0       ;  8cc, 2B  (first occurrence)
MOV  B, E        ;  8cc, 1B       MOV  B, E        ;  8cc, 1B
...
MVI  H, 0       ;  8cc, 2B  ←    MOV  H, E        ;  8cc, 1B  (E still 0)
```

### Benefit

- **Savings per instance**: 1 byte per MVI→MOV; 4cc+1B per MVI→INR/DCR
- **Frequency**: High — zero-byte materialization is extremely common
- **Test case**: Saves 2 bytes in the reference test (two `MVI 0` → `MOV r, E`)

### Complexity

Low. ~60 lines. Single-BB forward scan, no inter-BB analysis needed.

### Risk

Very Low. Only replaces when register value is provably known. Invalidates
tracking when a register is modified by a non-immediate instruction.

---

## O14. Tail Call Optimization (CALL+RET → JMP)

*Inspired by llvm-mos `MOSLateOptimization::tailJMP`.*
*Detailed analysis: [llvm_mos_analysis.md](llvm_mos_analysis.md) §S9.*

### Problem

When a function's last action is a CALL followed by RET, both instructions
can be replaced by a single JMP — the called function's RET will return
directly to the original caller.

### Before → After

```asm
; Before                          ; After
CALL  target     ; 18cc, 3B      JMP  target      ; 12cc, 3B
RET              ; 12cc, 1B
; Total: 30cc, 4B                 ; Total: 12cc, 3B
```

### Implementation

Post-RA peephole: scan each basic block for `CALL target; RET` at the end.
Replace both with `JMP target`. Must verify no stack cleanup is needed
between the CALL and RET (no local frame to deallocate).

### Benefit

- **Savings per instance**: 18cc + 1 byte
- **Frequency**: Common in wrapper functions, dispatch patterns, and at `-O2`
  where inlining creates short call-through functions
- **Additional benefit**: Reduces stack depth, preventing overflow in deep
  call chains

### Complexity

Very Low. ~15 lines in peephole pass.

### Risk

Very Low. Well-understood optimization. Must not apply when there's frame
cleanup (epilogue) between CALL and RET — but V6C already emits epilogue
before the CALL in such cases.

---

## O15. Conditional Call Optimization (Branch-over-Call → CC/CZ etc.)

*Inspired by jacobly0 Z80 `Z80MachineEarlyOptimization`.*
*Detailed analysis: [llvm_z80_analysis.md](llvm_z80_analysis.md) §S2.*

### Problem

The V6C backend emits branch-over-call patterns for conditional function calls:

```asm
  JZ  skip        ; 12cc, 3B  (branch if condition false)
  CALL target     ; 18cc, 3B
skip:
```

The 8080 has dedicated conditional call instructions (CC, CNC, CZ, CNZ, CP, CM,
CPE, CPO) that combine the test and call into one instruction — but V6C never
emits them.

### Before → After

```asm
; Before                          ; After
JZ   skip       ; 12cc, 3B       CNZ  target      ; 18cc, 3B (taken)
CALL target     ; 18cc, 3B                         ; 12cc, 3B (not taken)
skip:
; Total: 30cc taken, 12cc not     ; Total: 18cc taken, 12cc not taken
; 6 bytes                         ; 3 bytes
```

### Implementation

Pre-RA `MachineFunctionPass`:
1. Scan for conditional branch → fallthrough to block containing a single CALL
2. Verify the call block has only the CALL (+ optional result copies below a
   cost threshold)
3. Replace the branch + call with the corresponding conditional CALL opcode
4. Move result copies, preserve flag register across the transformation

Uses a cost threshold (`cond-call-threshold`) to avoid conversion when the
"then" block has too many non-call instructions that would all become
unconditional.

### Benefit

- **Savings per instance**: 3 bytes always; 12cc when call is taken
- **Frequency**: Medium — wrapper functions, error handling branches, dispatch
- **Side benefit**: Reduces basic block count → less branch overhead

### Complexity

Medium. ~80-100 lines. Requires analyzing the branch target block structure
and carefully handling result register COPYs.

### Risk

Low. Both `JNZ target / CALL fn / target:` and `CNZ fn` have identical
semantics. Only applies when the skipped block contains just the call.

---

## O16. Post-RA Store-to-Load Forwarding (Spill/Reload)

*Inspired by llvm-z80 `Z80LateOptimization` IX-indexed and SM83 SP-relative forwarding.*
*Detailed analysis: [llvm_z80_analysis.md](llvm_z80_analysis.md) §S5, §S6.*

### Problem

After register allocation, V6C inserts spill/reload sequences for stack access
costing ~52cc each (see O8). Often, the register being reloaded still holds
the same value that was spilled — the register was not clobbered between the
spill and reload. In these cases, the reload is completely redundant.

Even when the original register was clobbered, another register might still
hold the spilled value (from a copy chain), enabling a cheap register-to-register
transfer (8cc) instead of a full stack reload (52cc).

### How the Z80 Backends Do It

**jacobly0**: Tracks `DenseMap<int, MCPhysReg> AvailValues` mapping IX+d offsets
to physical registers. On spill: record. On reload: forward or eliminate.
On register clobber: invalidate affected entries. On call: clear all.

**llvm-z80**: Extended version for SM83 (which lacks IX, like the 8080):
- Tracks both register values and immediate constants at each SP-relative offset
- Handles 16-bit store/load patterns (two adjacent 8-bit slots)
- Detects and eliminates redundant stores (same value already in slot)
- Manages SP delta tracking through PUSH/POP/ADD SP,e

### V6C Adaptation

V6C's stack access uses the pattern:
```asm
PUSH HL; LXI HL, offset; DAD SP; MOV M, r; POP HL   ; spill
PUSH HL; LXI HL, offset; DAD SP; MOV r, M; POP HL   ; reload
```

The pass would track `offset → register` mappings and:
1. **Eliminate redundant reloads**: If `r` still holds the spilled value, erase
   the entire 5-instruction reload sequence (saves 52cc + 5 bytes)
2. **Forward via MOV**: If `r` was clobbered but `r'` holds the value, replace
   the reload with `MOV r, r'` (saves 44cc + 4 bytes)
3. **Eliminate redundant stores**: If the slot already holds the value being
   stored, erase the entire spill sequence

### Before → After

```asm
; Before                                    ; After
PUSH HL; LXI HL,4; DAD SP; MOV M,C; POP HL ; spill C at SP+4
; ... C not clobbered ...                    ; ... C not clobbered ...
PUSH HL; LXI HL,4; DAD SP; MOV E,M; POP HL ; reload → E   MOV E,C  ; 8cc, 1B
; Saves: 52cc – 8cc = 44cc per forwarded reload
```

### Benefit

- **Savings per instance**: 44-52cc per forwarded/eliminated reload
- **Frequency**: Very high — spill/reload pairs are pervasive in any function
  with >1 live pointer
- **Compound effect**: Eliminated reloads free HL for other uses → further
  reducing spill pressure

### Complexity

Medium. ~100-150 lines. The offset tracking is straightforward. Main
complexity: correctly invalidating entries on register clobber (must check
all tracked registers, not just the instruction's explicit defs) and handling
calls/side effects.

### Risk

Low-Medium. Only replaces when provably correct (register value matches
what's in the stack slot). Conservative: clear all on call/unknown side
effects.

---

## O17. Redundant Flag-Setting Elimination (Post-RA)

*Inspired by llvm-z80 `Z80PostRACompareMerge`.*
*Detailed analysis: [llvm_z80_analysis.md](llvm_z80_analysis.md) §S7.*

### Problem

The V6C backend frequently emits `ORA A` (or `ANA A`) before conditional
branches to set the zero flag, even when the preceding ALU instruction
already set the flags correctly.

```asm
XRA  E          ; sets Z flag (A = A XOR E)
ORA  A          ; redundant — Z already reflects A's value
JZ   .label
```

V6C's `V6CEliminateZeroTest` pass handles the `ZERO_TEST` pseudo, but this
is limited to specific patterns at pseudo expansion time. Post-RA code may
have additional redundant flag-setting instructions that are missed.

### Implementation

Post-RA `MachineFunctionPass`: forward scan through each basic block tracking
whether the Z flag is "valid for A" (set by an instruction that both defines
FLAGS and operates on A):

1. On any ALU instruction that defines FLAGS and A (ADD, ADC, SUB, SBB, ANA,
   ORA, XRA, CMP, CPI): mark `ZFlagValid = true`
2. On `ORA A` or `ANA A` when `ZFlagValid`: erase the instruction
3. On any instruction that modifies A without setting flags (MOV A,r, MVI A,
   LDA, etc.): mark `ZFlagValid = false`
4. On call, return, branch, or pseudo: mark `ZFlagValid = false`

### Before → After

```asm
; Before                    ; After
ANA  D       ;  4cc         ANA  D       ;  4cc
ORA  A       ;  4cc  ←del
JZ   label   ; 12cc         JZ   label   ; 12cc
```

### Benefit

- **Savings per instance**: 4cc + 1 byte
- **Frequency**: Medium-high — occurs after comparison expansions, loop
  condition checks, and any conditional branch based on an ALU result

### Complexity

Low. ~50 lines. Simple forward scan, no inter-BB analysis needed.

### Risk

Very Low. The Z flag semantics are well-defined for all affected instructions.
Only erases when provably redundant.

---

## O18. Loop Counter DEC+Branch Peephole

*Inspired by llvm-z80 `Z80LateOptimization` dec-and-branch peephole and
`Z80ExpandPseudo` DJNZ expansion.*
*Detailed analysis: [llvm_z80_analysis.md](llvm_z80_analysis.md) §S8.*

### Problem

V6C emits a 5-instruction sequence for "decrement counter and branch if
nonzero" because the accumulator is required for both `DCR` (which doesn't
set all flags on all registers) and the branch test:

```asm
MOV  A, B        ;  8cc   load counter into A
DCR  A           ;  4cc   decrement
MOV  B, A        ;  8cc   store back
ORA  A           ;  4cc   set flags
JNZ  loop        ; 12cc   branch if nonzero
; Total: 36cc, 6B
```

The 8080's `DCR r` instruction sets the Z flag directly for any register r.
The entire 5-instruction sequence can be replaced with:

```asm
DCR  B           ;  4cc   decrement B, sets Z flag
JNZ  loop        ; 12cc   branch if nonzero
; Total: 16cc, 2B
```

### Implementation

Post-RA peephole: match the 5-instruction template `MOV A,r; DCR A; MOV r,A;
ORA A; JNZ target` and replace with `DCR r; JNZ target`. Preconditions:
1. A must be dead after the sequence (not used before next definition)
2. No intervening instructions between the 5

### Benefit

- **Savings per instance**: 20cc + 4 bytes per loop iteration
- **Frequency**: Very high — this is the standard loop counter pattern
- **Compound**: Loop iterations × savings → massive in tight loops

### Complexity

Low. ~40 lines. Pattern matching on 5 consecutive instructions with a
register liveness check.

### Risk

Very Low. `DCR r` and `JNZ` have identical semantics to the expanded sequence.
Only applies when A is dead after (checked by forward scan to next A def/use).

---

## O19. Inline Arithmetic Expansion (Mul/Div)

*Inspired by llvm-z80 `Z80ExpandPseudo` inline multiply and divide.*
*Detailed analysis: [llvm_z80_analysis.md](llvm_z80_analysis.md) §S9.*

### Problem

V6C uses library calls (`__mulqi3`, `__divqi3`, etc.) for all multiply and
divide operations. Each library call incurs:
- CALL/RET overhead: ~30cc
- Register save/restore in the callee: ~40-80cc (PUSH/POP pairs)
- Function body execution
- Total: ~150-300cc+ per invocation

For 8-bit multiply (the most common case), an inline shift-add loop takes
only ~100-120cc with no call overhead and no register save/restore beyond
what the caller already manages.

### How the Z80 Does It

Expand pseudo instructions into inline loops:

**8-bit multiply** (SM83 variant = 8080-compatible):
```asm
  LD   D, A           ; D = multiplier
  XOR  A              ; A = 0 (accumulator)
  LD   B, 8           ; counter
loop:
  ADD  A, A           ; A <<= 1
  RL   D              ; D <<= 1, MSB → carry
  JR   NC, skip
  ADD  A, E           ; A += multiplicand
skip:
  DJNZ loop
; Result in A (low 8 bits)
```

8080 equivalent:
```asm
  MOV  D, A           ; D = multiplier
  XRA  A              ; A = 0
  MVI  B, 8
loop:
  ADD  A              ; A <<= 1
  MOV  A, D           ; (need to rotate D via A on 8080)
  RAL                 ; carry into D's MSB position
  MOV  D, A
  JNC  skip
  ADD  E              ; A += multiplicand
skip:
  DCR  B
  JNZ  loop
```

**16-bit multiply** and **8/16-bit divide** follow similar shift-loop patterns
with the SM83 variants (no DJNZ, no EX DE,HL) mapping directly to 8080.

### Implementation

Expand arithmetic pseudo instructions in a post-RA pass:
1. **8-bit multiply**: ~12-15 instructions inline (vs CALL + library)
2. **8-bit divide/mod**: ~20 instructions inline (restoring division)
3. **Signed variants**: Absolute value + unsigned op + sign correction
4. Selection: Always inline for 8-bit; use size threshold for 16-bit

Could be controlled by `-O` level: inline at `-O2`/`-O3`, keep library calls
at `-Os`/`-Oz`.

### Benefit

- **8-bit multiply**: ~100-120cc inline vs ~200-300cc library = **2-3× faster**
- **8-bit divide**: ~150-200cc inline vs ~300-400cc library = **1.5-2× faster**
- **Code size tradeoff**: Each inline expansion is ~12-20 bytes vs 3-byte CALL,
  but eliminates the library function from the linked binary

### Complexity

Medium. ~200-400 lines for all variants (8/16 bit, unsigned/signed, mul/div/mod).
The algorithms are well-known and the Z80 SM83 variants provide tested templates.

### Risk

Low. The algorithms are standard binary multiply/divide. Correctness can be
exhaustively tested for 8-bit operands (256×256 = 65536 cases).

---

## Summary Table

| ID | Optimization | Source | Savings/instance | Frequency | Complexity | Risk | Dependencies | Complete |
|----|-------------|--------|-----------------|-----------|------------|------|-------------|-----|
| O1 | Redundant MOV elimination | V6C | 8cc, 1B | Very high | Low | Low | None (superseded by O12) | [ ] |
| O2 | Sequential LXI → INX | V6C | 4cc, 2B | High | Medium | Low-Med | None | [ ] |
| O3 | Narrow-type arithmetic | V6C | 30-100cc | Very high | High | Med-High | None | [ ] |
| O4 | ADD M / SUB M direct | V6C | 4-8cc, 1B | High | Medium | Low-Med | O2 helps | [ ] |
| O5 | BUILD_PAIR(x,0)+ADD16 | V6C | 16-24cc | Very high | Medium | Low-Med | None | [ ] |
| O6 | LDA/STA absolute addr | V6C | 2cc, 1B | Medium | Low | Low | None | [ ] |
| O7 | Loop Strength Reduction (TTI) | V6C | 120-160cc/iter | High (loops) | Medium | Medium | None | [x] |
| O8 | Spill Optimization (T1/T2) | V6C | 64-76cc/pair | Very high | High | Med-High | O10 enhances T2 | [ ] |
| O9 | Inline Assembly (MC parser) | V6C | N/A (feature) | N/A | High | Low | None | [ ] |
| O10 | Static Stack (non-reentrant) | llvm-mos | 32-36cc/access | Very high | Medium | Medium | LTO/single-TU | [ ] |
| O11 | Dual Cost Model (Bytes+Cycles) | llvm-mos | N/A (infra) | N/A | Low | Very Low | None | [ ] |
| O12 | Global Copy Opt (cross-BB) | llvm-mos | 8cc, 1B | Very high | Medium | Low | O11 | [ ] |
| O13 | LdImm Combining (value track) | llvm-mos | 1B or 4cc+1B | High | Low | Very Low | None | [ ] |
| O14 | Tail Call (CALL+RET→JMP) | llvm-mos | 18cc, 1B | Medium | Very Low | Very Low | None | [ ] |
| O15 | Conditional Call (JNZ+CALL→CNZ) | llvm-z80 | 12cc, 3B | Medium | Medium | Low | None | [ ] |
| O16 | Store-to-Load Forwarding | llvm-z80 | 44-52cc/reload | Very high | Medium | Low-Med | None | [ ] |
| O17 | Redundant Flag Elimination | llvm-z80 | 4cc, 1B | Med-high | Low | Very Low | None | [ ] |
| O18 | Loop Counter DCR+JNZ | llvm-z80 | 20cc, 4B/iter | Very high | Low | Very Low | None | [ ] |
| O19 | Inline Arithmetic (Mul/Div) | llvm-z80 | 100-200cc | Medium | Medium | Low | None | [ ] |

### Recommended order

**Phase 1 — Quick wins (Low complexity, immediate benefit)**:
1. **O14** — trivial tail-call peephole, 18cc savings, ~15 lines
2. **O18** — loop counter DCR+JNZ peephole, 20cc savings per iteration, ~40 lines
3. **O17** — redundant flag elimination, 4cc+1B per instance, ~50 lines
4. **O11** — cost model infrastructure, enables cost-aware decisions everywhere
5. **O13** — register value tracking peephole, saves bytes on MVI→MOV/INR
6. **O6** — simple ISel pattern for LDA/STA

**Phase 2 — Core optimizations (Medium complexity, high payoff)**:
7. **O16** — store-to-load forwarding, 44-52cc per eliminated reload
8. **O12** — cross-BB copy optimization, supersedes O1
9. **O15** — conditional call, 12cc+3B per instance, reduces branch count
10. **O5** — BUILD_PAIR+ADD16 fusion, high per-instance savings
11. **O2** — sequential LXI→INX folding
12. **O4** — ADD M / SUB M direct memory, builds on O2

**Phase 3 — Loop & stack (Medium-High complexity, massive payoff)**:
13. **O7** — TTI for Loop Strength Reduction, existing LLVM pass just needs cost info
14. **O10** — static stack allocation for non-reentrant functions, supersedes O8 T2
15. **O19** — inline arithmetic expansion for mul/div, 2-3× faster than libcalls

**Phase 4 — Advanced (High complexity)**:
16. **O3** — narrow-type arithmetic, highest per-instance savings but complex DAGCombine
17. **O8** — remaining spill optimization (T1 PUSH/POP), complements O10

**Deferred**:
13. **O9** — inline assembly MC parser, implement when needed

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
Their backend has 12+ custom optimization passes solving the same fundamental
problems we face. Full analysis: [llvm_mos_analysis.md](llvm_mos_analysis.md).

**Passes directly adapted for V6C** (O10-O14 above):
- **`MOSNonReentrant` + `MOSStaticStackAlloc`** → O10 (static stack for non-reentrant
  functions, 3-5× faster spill/reload)
- **`MOSInstrCost`** → O11 (dual Bytes+Cycles cost model)
- **`MOSCopyOpt`** → O12 (inter-BB copy forwarding + immediate rematerialization)
- **`MOSLateOptimization::combineLdImm`** → O13 (register value tracking,
  replace MVI with MOV/INR/DCR)
- **`MOSLateOptimization::tailJMP`** → O14 (CALL+RET → JMP tail calls)

**Passes with indirect value for V6C**:
- **`MOSIndexIV`** — IR-level loop pass that narrows indices to 8 bits via SCEV
  analysis. Complements O7 (TTI). Almost target-independent; minimal porting.
- **`MOSZeroPageAlloc`** — frequency-weighted call-graph-aware allocation of
  scarce fast-access memory. No direct 8080 zero page, but the algorithm is
  valuable for O8/O10 global bss slot allocation decisions.
- **`MOSLateOptimization::lowerCmpZeros`** — eliminates compare-against-zero
  by scanning backward past known-safe instructions. Enhances existing V6C
  `ZERO_TEST` pass.
- **`MOSShiftRotateChain`** — chains constant shifts to share intermediate
  results via dominance analysis. Lower priority for 8080 (shifts less common).

**Key architectural insight**: The 8080 has *more* registers (7 vs 3) but
*fewer* addressing modes (no indexed, no zero page). llvm-mos compensates for
its tiny register file with zero-page "soft registers" and indexed addressing.
V6C must compensate for its addressing limitations with better register
utilization and cheaper pointer management — different mechanism, same goal.

### Reference: llvm-z80

Two Z80 LLVM backends were analyzed — full details in
[llvm_z80_analysis.md](llvm_z80_analysis.md).

**jacobly0/llvm-project** (https://github.com/jacobly0/llvm-project, `z80`
branch, 171 stars) — mature Z80/eZ80 backend, GlobalISel, ~LLVM 15. 14
custom passes. Key contribution: comprehensive `RegVal` tracking in
`Z80MachineLateOptimization` that knows per-register constants, flag states,
and sub-register composition. This is the inspiration for O13's "enhanced"
form.

**llvm-z80/llvm-z80** (https://github.com/llvm-z80/llvm-z80, `main` branch,
34 stars) — newer active Z80+SM83 backend, ~LLVM 20, ports from llvm-mos.
23 custom passes. Key contribution: SM83 (Game Boy) is an 8080 subset, so
its SM83 code paths are directly applicable to V6C.

**Passes directly adapted for V6C** (O15-O19 above):
- **`Z80MachineEarlyOptimization`** (jacobly0) → O15 (conditional call,
  JNZ+CALL → CNZ using the 8080's CC/CNC/CZ/CNZ/CP/CM/CPE/CPO)
- **`Z80LateOptimization` IX-forwarding** (llvm-z80) → O16 (store-to-load
  forwarding, tracking spilled register values to eliminate redundant reloads)
- **`Z80PostRACompareMerge`** (llvm-z80) → O17 (redundant flag elimination,
  erase ORA A when preceding ALU already set Z flag)
- **`Z80LateOptimization` loop counter** (llvm-z80) → O18 (5-instruction
  loop counter → DCR r; JNZ, saving 20cc+4B per iteration)
- **`Z80ExpandPseudo` inline arithmetic** (llvm-z80) → O19 (shift-add mul,
  restoring div inline instead of library calls)

**Passes enhancing existing V6C plans**:
- **`Z80TargetTransformInfo`** — `areInlineCompatible()` restricts inlining
  to ≤10 instructions or InlineHint-annotated functions (because with few
  registers, inlining large functions causes massive spilling). Enhances O7.
  `isLSRCostLess()` prioritizes instruction count over register pressure.
  Enhances O7's TTI cost model.
- **`Z80MachineLateOptimization` RegVal** (jacobly0) — extends O13 with
  comprehensive per-register constant tracking, flag state awareness,
  sub-register composition knowledge, and many more peephole patterns
  (SLA A→ADD A,A, LD 0→SBC r,r when carry known, LD imm±1→INC/DEC).
- **`Z80InstrCost`** + **`Z80ShiftRotateChain`** + **`Z80IndexIV`** — all
  ported from llvm-mos, confirming the value of O11 (dual cost model).

**Key architectural insight**: The Z80 is a strict superset of the 8080. Any
Z80 optimization using only base 8080 instructions applies directly to V6C.
The SM83 (Game Boy CPU) is an 8080 subset (no IX/IY, no relative jumps, no
block instructions) — making the llvm-z80 SM83 code paths the most directly
portable to V6C. The main Z80-only features (IX+d indexing, relative jumps,
DJNZ, block I/O) require 8080-specific alternatives when porting.
