# Plan: Commutable ALU Operand Selection (O60)

## 1. Problem

### Current behavior

Trivial commutative 8-bit adds produce a 3-instruction shuffle when the
incoming operand placement does not match the `Acc` (A) register the
pattern requires as LHS:

```asm
; char sum(char arg0, char arg1)   ; arg0=A, arg1=E
sum:
    MOV   L, A      ; save arg0
    MOV   A, E      ; move arg1 into A (the LHS)
    ADD   L         ; ADD with the saved arg0
    RET
```

The shuffle costs **2 extra `MOV`s (8cc, 2B)** for every commutative
ALU op whose operand assignment got flipped. In hotter code this
cascades — see the inner loop in `interleaved_add`:

```asm
    ;--- V6C_RELOAD8 ---
    PUSH  DE
    MOV   D, H
    LXI   HL, __v6c_ss.interleaved_add+6
    MOV   L, M
    MOV   H, D
    POP   DE
    ADD   L           ; ← the *only* real work; everything above is shuffle
```

### Desired behavior

The compiler should recognize that `+`, `&`, `|`, `^` are commutative
and pick whichever operand ordering requires fewer copies:

```asm
sum:
    ADD   E           ; arg0 already in A; arg1 in E — commute and use directly
    RET
```

### Root cause

Three independent gaps in the backend combine to produce the shuffles:

1. **TableGen defs lack `isCommutable = 1`.** All 8-bit register ALU ops
   (`ADDr`, `ADCr`, `ANAr`, `ORAr`, `XRAr`) and all 16-bit commutative
   pseudos (`V6C_ADD16`, `V6C_AND16`, `V6C_OR16`, `V6C_XOR16`) are
   missing the flag. Without it, `TwoAddressInstructionPass` never
   swaps operands to avoid a tied-operand copy; the register coalescer
   never retries coalescing through a commuted form; and MachineCSE
   cannot canonicalize operand order across uses. See
   [V6CInstrInfo.td#L259](llvm/lib/Target/V6C/V6CInstrInfo.td#L259) (8-bit)
   and [V6CInstrInfo.td#L721](llvm/lib/Target/V6C/V6CInstrInfo.td#L721) (16-bit).

2. **ISel does not prefer A-aligned LHS.** When a function argument or
   the result of a prior ALU op already sits in `A`, ISel still emits
   the DAG in whichever operand order the SelectionDAG happens to
   produce. For commutative ops this is essentially random; when the
   "wrong" operand is picked as LHS, a pre-RA commute cannot always
   recover (both operands live past the op).

3. **No post-RA residual cleanup.** Spill reshaping and late
   scheduling can flip which operand ended up in `A` at the use site.
   `V6CAccumulatorPlanning` already tracks A-contents but does not
   rewrite a commutative ALU op to read from whichever side currently
   matches `A`.

---

## 2. Strategy

### Approach: Three-layer operand-selection improvement

**Layer 1 — TableGen `isCommutable = 1` (pre-RA, primary win)**

Add `let isCommutable = 1 in` around the five 8-bit register ALU defs
and the four 16-bit pseudo defs. This is consumed by:

- `TwoAddressInstructionPass`: before inserting a tied-operand copy,
  tries swapping; keeps the swap iff it avoids the copy.
- Register coalescer: retries coalescing the tied def against the
  commuted source operand.
- MachineCSE / scheduler: hashes operand-order-insensitively.

Because `$dst` is tied to `$lhs = Acc` (fixed A), the legal commute
swaps the meaning of `$lhs` and `$rs`; the tied pair still lands in
`A` (the non-`Acc` operand just keeps its GR8 allocation). This is
the case LLVM's default `commuteInstructionImpl` handles correctly.

**Layer 2 — ISel operand-order preference (pre-RA, secondary)**

In `V6CDAGToDAGISel::Select` (or via a pattern predicate), for the
commutative ALU opcodes, inspect the two operands. When one operand
is demonstrably "already in A" at that SelectionDAG point — e.g. it is
an incoming physreg copy from `$A`, or it is the result of a prior
node that writes `A` (`LDA`, previous ALU, `LDAX`) — prefer it as
LHS. This fixes cases where pre-RA commute (Layer 1) cannot fire
because both operands are live past the op (TwoAddressPass can only
eliminate one of the two possible copies).

**Layer 3 — Post-RA commute in `V6CAccumulatorPlanning`**

Add a new method `commuteMatchingAccALU()` to
[V6CAccumulatorPlanning.cpp](llvm/lib/Target/V6C/V6CAccumulatorPlanning.cpp)
that walks each MBB post-RA, maintains `A`-value tracking (already
present), and when it encounters a commutative ALU op whose current
LHS is NOT what `A` holds but whose RHS IS, swaps them by rewriting
operand 2. Handles residual cases introduced by the spiller and
scheduler that Layers 1 and 2 cannot reach.

### Why this works

- **Layer 1 is sound by construction.** LLVM's tied-operand commute
  rewriter respects reg-class constraints. `Acc` is a single-reg class;
  the tied result class is unchanged. If the commute would violate
  constraints, the pass simply skips it.
- **Layer 2 is a pure ISel preference.** No correctness change — just
  pick between two semantically equivalent DAG selections.
- **Layer 3 only rewrites operand positions of a single commutative
  ALU op.** Preserves flag semantics (commutative ops produce the same
  flags regardless of operand order: ADD/ADC Z/S/P/CY all symmetric;
  logicals clear CY unconditionally). No live-range extension.

### Summary of changes

| File | Layer | Change |
|------|-------|--------|
| `llvm-project/llvm/lib/Target/V6C/V6CInstrInfo.td` | 1 | Add `isCommutable = 1` to `ADDr`, `ADCr`, `ANAr`, `ORAr`, `XRAr` |
| `llvm-project/llvm/lib/Target/V6C/V6CInstrInfo.td` | 1 | Add `isCommutable = 1` to `V6C_ADD16`, `V6C_AND16`, `V6C_OR16`, `V6C_XOR16` |
| `llvm-project/llvm/lib/Target/V6C/V6CISelDAGToDAG.cpp` | 2 | Prefer A-aligned LHS when selecting commutative ALU ops |
| `llvm-project/llvm/lib/Target/V6C/V6CAccumulatorPlanning.cpp` | 3 | Add `commuteMatchingAccALU()` walker using existing A-value tracking |
| `llvm/...` (mirror) | — | Run `scripts\sync_llvm_mirror.ps1` |
| `design/future_plans/README.md` | — | Add O60 row |

No new pass. No new pseudo. No CC/flag semantic change. `ADCr` and
`SBBr` behaviors are preserved (only `ADCr` is commutative and only
when the carry-in is considered invariant — which it is, as the carry
operand is implicit in FLAGS and unaffected by operand swap).

Note: `SBBr` is NOT commutative (`a - b - C ≠ b - a - C`). Only `ADCr`
is. `SUBr`/`SBBr`/`CMPr` must remain non-commutable.

---

## 3. Implementation Steps

### Step 3.1 — Read reference documents [ ]

- [V6CArchitecture.md](docs/V6CArchitecture.md) — calling convention
  (arg0 in A, arg1 in E)
- [V6COptimization.md](docs/V6COptimization.md) — existing ALU patterns
- [V6CCallingConvention.md](docs/V6CCallingConvention.md) — physreg
  argument assignment
- [V6CBuildGuide.md](docs/V6CBuildGuide.md) — build commands
- [Vector_06c_instruction_timings.md](docs/Vector_06c_instruction_timings.md)
  — verify `MOV r,r'` = 4cc, 1B

> **Design Notes**: Confirm that `ADCr` semantics are invariant under
> commute (carry is read from FLAGS, not a source operand) — it is.

> **Implementation Notes**: <empty. filled after completion>

### Step 3.2 — Layer 1a: Mark 8-bit ALU regs commutable [ ]

In [V6CInstrInfo.td](llvm/lib/Target/V6C/V6CInstrInfo.td), wrap
`ADDr`, `ADCr`, `ANAr`, `ORAr`, `XRAr` in an additional
`let isCommutable = 1 in { ... }` scope. `SUBr`, `SBBr`, and `CMPr`
must NOT receive the flag.

> **Design Notes**: The existing `let Defs = [FLAGS] in { let
> Constraints = "$dst = $lhs" in { ... } }` block already covers all
> eight ops. Split into two inner scopes: commutable (add/adc/and/or/xor)
> and non-commutable (sub/sbb). `CMPr` is outside the `Constraints`
> block (no `$dst`) and stays as-is.

> **Implementation Notes**: <empty. filled after completion>

### Step 3.3 — Layer 1b: Mark 16-bit ALU pseudos commutable [ ]

In [V6CInstrInfo.td](llvm/lib/Target/V6C/V6CInstrInfo.td), add
`isCommutable = 1` to `V6C_ADD16`, `V6C_AND16`, `V6C_OR16`,
`V6C_XOR16`. `V6C_SUB16` stays non-commutable.

> **Design Notes**: These pseudos do NOT have `$dst = $lhs`
> constraints (unlike the 8-bit physical ops). Commute still helps by
> letting the coalescer choose the cheaper of two copy insertions
> when expanding to `V6C_ADD16`'s 8-bit chain.

> **Implementation Notes**: <empty. filled after completion>

### Step 3.4 — Layer 1: Build & sanity check [ ]

```
cd c:\Work\Programming\v6llvmc
cmd /c """C:\Program Files\Microsoft Visual Studio\2022\Community\Common7\Tools\VsDevCmd.bat"" -arch=amd64 >nul 2>&1 && ninja -C llvm-build clang llc FileCheck not"
```

Run existing full test suite to catch any unexpected commute-induced
changes before proceeding to Layers 2/3.

> **Design Notes**: Expect small MIR diffs from the commuter picking
> different operand orders. Golden test numeric output must be
> unchanged.

> **Implementation Notes**: <empty. filled after completion>

### Step 3.5 — Layer 1 lit test: `commute-alu-tied.ll` [ ]

Create `tests/lit/CodeGen/V6C/commute-alu-tied.ll` asserting the
`sum`-style case:

```
define i8 @add_a_e(i8 %a, i8 %b) {
  %r = add i8 %a, %b
  ret i8 %r
}
; CHECK-LABEL: add_a_e:
; CHECK-NEXT:  ADD E
; CHECK-NEXT:  RET
; CHECK-NOT:   MOV L, A
```

Add parallel cases for `and`, `or`, `xor` (all 8-bit commutative ops).

> **Design Notes**: Use `-O2` — `-O0` will keep spills.

> **Implementation Notes**: <empty. filled after completion>

### Step 3.6 — Layer 2: A-aligned LHS preference in ISel [ ]

In [V6CISelDAGToDAG.cpp](llvm/lib/Target/V6C/V6CISelDAGToDAG.cpp),
add a `preferAccLHS()` helper used in `Select()` before falling
through to the TableGen-generated selector. For commutative 8-bit
ALU nodes (`ISD::ADD`/`AND`/`OR`/`XOR` with i8 result), if operand 1
is a `CopyFromReg(A)` or a node known to produce its result in `A`,
swap operands 0 and 1 on the DAG before selection.

> **Design Notes**: Keep the helper conservative — only rewrite when
> the match is certain (explicit `CopyFromReg` of `A`, or a V6C
> opcode whose TableGen def has `Acc:$dst`). Do not attempt full
> value-tracking here; that's Layer 3's job.

> **Implementation Notes**: <empty. filled after completion>

### Step 3.7 — Layer 2: Build [ ]

Same command as Step 3.4.

> **Implementation Notes**: <empty. filled after completion>

### Step 3.8 — Layer 2 lit test: `commute-alu-isel.ll` [ ]

Create `tests/lit/CodeGen/V6C/commute-alu-isel.ll` targeting cases
Layer 1 cannot reach — both operands live past the ALU op, but one
is already in A from a prior use. Example: `r = a + b; use(a);
use(b); use(r)`.

> **Design Notes**: If the output is already optimal after Layer 1
> alone for a given case, drop it from this test and document why.

> **Implementation Notes**: <empty. filled after completion>

### Step 3.9 — Layer 3: `commuteMatchingAccALU()` in AccumulatorPlanning [ ]

In [V6CAccumulatorPlanning.cpp](llvm/lib/Target/V6C/V6CAccumulatorPlanning.cpp),
add a new method that walks MBBs post-RA. Maintain the existing
`A`-value tracking (pass already has this for `eliminateRedundantAccMoves`).

When the scanner hits one of `ADDr`/`ADCr`/`ANAr`/`ORAr`/`XRAr`:

- If current tracked `A`-value == RHS physreg (`$rs`) AND
- LHS physreg is currently live and not equal to A,

swap operand 2 so that the now-correct RHS is the physreg that is
NOT in A, and the preceding `MOV A, <lhs>` becomes dead (to be
cleaned up by the existing redundant-MOV elimination in the same
pass).

> **Design Notes**: Keep the rewrite confined to the operand at index
> 2 (the `$rs` input). The tied `$dst`/`$lhs` input stays as `A`.
> Flag semantics: all five ops set Z/S/P identically under commute;
> ADD/ADC set CY identically; AND/OR/XOR clear CY regardless. Safe.

> **Design Notes**: Guard with `-v6c-disable-acc-planning` (existing
> toggle) and add a sub-toggle `-v6c-disable-commute-acc-alu` for
> isolation testing.

> **Implementation Notes**: <empty. filled after completion>

### Step 3.10 — Layer 3: Build [ ]

Same command as Step 3.4.

> **Implementation Notes**: <empty. filled after completion>

### Step 3.11 — Layer 3 lit test: `commute-alu-post-ra.ll` [ ]

Create `tests/lit/CodeGen/V6C/commute-alu-post-ra.ll` targeting
spill-induced residuals. Construct a function with enough register
pressure that the spiller introduces a late `MOV A, X` where `A`
already held the correct RHS pre-spill.

Toggle test: `-v6c-disable-commute-acc-alu` reverts to the
Layer-1/2 output.

> **Implementation Notes**: <empty. filled after completion>

### Step 3.12 — Lit test: `commute-alu-disabled.ll` [ ]

Sanity-check that disabling Layer 3 only (keeping Layers 1 and 2
live) still produces Layer-1 optimal output. Ensures layers are
independent and the toggle is correct.

> **Implementation Notes**: <empty. filled after completion>

### Step 3.13 — Run regression tests [ ]

```
python tests/run_all.py
```

Must pass:
- All lit tests (CodeGen + MC + Clang)
- All 15 golden tests
- M7 round-trip (13)
- M10 link round-trip (2)
- M12 validation sweep
- Runtime tests (4)
- `-verify-machineinstrs` sweep

> **Design Notes**: Expect MIR diffs across the suite. Verify that
> cycle-count-sensitive golden tests either improve or stay flat;
> any regression is a bug.

> **Implementation Notes**: <empty. filled after completion>

### Step 3.14 — Verification assembly steps from `tests\features\README.md` [ ]

Create `tests/features/<next-id>/` following the template. Include
at minimum:

- `sum` (arg0+arg1, both scalar)
- `multi_live` (commutative op with liveness pressure)
- An i16 variant exercising `V6C_ADD16` commute
- A loop body containing `ADD` where commute fires inside the hot path

> **Implementation Notes**: <empty. filled after completion>

### Step 3.15 — Make sure `result.txt` is created [ ]

Per [tests/features/README.md](tests/features/README.md), run the
feature verification script and confirm `result.txt` is generated
and matches the expected commuted output.

> **Implementation Notes**: <empty. filled after completion>

### Step 3.16 — Sync mirror [ ]

```
powershell -ExecutionPolicy Bypass -File scripts\sync_llvm_mirror.ps1
```

> **Implementation Notes**: <empty. filled after completion>

### Step 3.17 — Documentation updates [ ]

- `design/future_plans/README.md`: add O60 table row and summary row
- `design/future_plans/O60_commutable_alu_ops.md`: short cross-ref
  stub pointing to this plan
- `docs/V6COptimization.md`: add "Commutable operand selection"
  subsection describing the three layers

> **Implementation Notes**: <empty. filled after completion>

---

## 4. Expected Results

### Example 1: `sum(char, char)` — the canonical case

Before (current output, from
[tests/features/20/v6llvmc_xchg.asm#L119](tests/features/20/v6llvmc_xchg.asm#L119)):

```asm
sum:
    MOV   L, A      ; 4cc 1B
    MOV   A, E      ; 4cc 1B
    ADD   L         ; 4cc 1B
    RET
```

After Layer 1 alone:

```asm
sum:
    ADD   E         ; 4cc 1B
    RET
```

**Savings: 8cc, 2B per function.**

### Example 2: `multi_live` — inline commute avoids reload

Before:

```asm
multi_live:
    MOV   L, A      ; save arg0
    MOV   A, C      ; set up OUT
    OUT   0xde
    MOV   A, L      ; reload arg0
    ADD   E
    ADI   3
    RET
```

After (Layer 1 + Layer 2): `A` is clobbered by `OUT`, so Layer 1
alone still spills. Layer 2 cannot help because the A-clobber is
unavoidable. Layer 3 cannot help either. This case remains
unchanged — correctly demonstrating where the boundary of the
optimization lies. (A further enhancement would lift `ADD E` ahead
of the `OUT`; that is outside this plan's scope.)

### Example 3: i16 commute reducing copies before expansion

A function containing `i16 c = a + b;` where `a` is in DE and `b`
in HL. Pre-Layer-1, ISel may produce `V6C_ADD16 dst=HL, lhs=DE, rhs=HL`
requiring a DE→HL copy before expansion. With Layer 1, the coalescer
commutes to `V6C_ADD16 dst=HL, lhs=HL, rhs=DE`, eliminating the
`XCHG` / `MOV H,D; MOV L,E` pair.

**Savings: 4cc, 1B per i16 commute (XCHG) or 8cc, 2B (MOV pair).**

### Example 4: inner loop from `interleaved_add`

Within `.LBB0_2`, any of the 4+ ALU ops that currently shuffle `A`
back into place will benefit from combined Layer 1+3. Exact savings
depend on RA output, but even one eliminated shuffle per iteration
over a typical loop trip count of 256 = **2048cc, 512B** saved over
the program.

### Aggregate expectation across golden tests

Anticipated reduction: 1-3% in code size, 1-2% in cycle counts for
arithmetic-dominated golden tests (`arith`, `fib`, `sieve`). Flat
for data-movement-dominated ones (`memcpy`, `sprintf`-style).

---

## 5. Risks & Mitigations

| Risk | Mitigation |
|------|------------|
| `isCommutable` on `ADCr` violates carry semantics | `ADCr` IS commutative: `a + b + C == b + a + C`. Carry read from FLAGS unaffected by operand order. Covered by existing ADC lit tests + new commute-alu-tied.ll. |
| TwoAddressPass commute breaks `Acc` class constraint | LLVM checks reg-class legality inside `commuteInstructionImpl`; if illegal, it skips. Tested via `-verify-machineinstrs` sweep in Step 3.13. |
| Layer 2 ISel rewrite produces different DAG shape breaking existing patterns | Gate Layer 2 on a `-v6c-disable-isel-commute-pref` hidden toggle. Any test regression → disable Layer 2 and investigate. |
| Layer 3 swap leaves stale A-value tracking | Post-swap, refresh the tracked A-value to the result of the commuted op. Identical to existing write-through logic for non-commuted ALU ops — reuse the same hook. |
| Flag differences in CY for ADD vs SUB swap | Only commutative ops receive the flag; SUB/SBB/CMP explicitly excluded. Covered by code review + encoding lit tests. |
| Interaction with O36 (branch-implied value propagation) | Commute preserves both result value and Z flag; O36 observes only those. No interaction. |
| Interaction with O38 (XRA+CMP zero-test) | O38 rewrites `XRA A` (identity); commute doesn't apply (both operands are A). No interaction. |
| Layer 3 creates new adjacent redundant MOVs | Existing V6CPeephole pass (self-MOV + redundant-MOV) runs after AccPlanning and will clean them up. |

---

## 6. Relationship to Other Improvements

- **O13 Load-Immediate Combining**: Commute exposes more
  opportunities for O13 by freeing registers. After commute, an
  immediate that was loaded into the original LHS may be reusable.
- **O32 XCHG in copyPhysReg**: 16-bit commute (Layer 1b) reduces the
  need for O32's XCHG insertions by letting the coalescer pick the
  pair that doesn't need swapping.
- **O20 Honest Store/Load Defs**: Orthogonal — operates at a
  different level (pseudo expansion correctness, not operand order).
- **O39 IPRA Integration**: IPRA narrows per-call clobbers; commute
  reduces the cost of the clobbers that remain. Composes cleanly.
- **O12 Global Copy Optimization**: Targets cross-BB copy elimination;
  commute (Layer 1) targets intra-BB copy elimination at tied-operand
  boundaries. Non-overlapping coverage.
- **Supersedes**: parts of O01 (redundant MOV after BUILD_PAIR + ADD16)
  for the common `a = a + b` pattern.

---

## 7. Future Enhancements

- **Layer 4 — Inter-BB commute**: Extend Layer 3 to track A-value
  across BB boundaries for single-predecessor successors. Rarely
  applicable given the 8080's short BB lifetimes, but could help
  short loops.
- **Commute-aware scheduler hooks**: Integrate with
  `MachineScheduler` to prefer schedules that align A-value with
  commutative ALU LHS operands. Depends on O11 cost model.
- **Immediate-form commute**: Already subsumed by DAG canonicalization
  for `ADI`/`ANI`/`ORI`/`XRI` (constant → RHS → immediate form). No
  action needed.
- **Memory-form commute (`ADDM`/`ANAM`/...)**: Impossible — the M
  operand is implicit-HL. Excluded by ISA.
- **Commute across V6C_BUILD_PAIR**: When building an i16 from two
  bytes to feed into a commutative i16 op, sometimes the pair order
  can be swapped to align with the coalescer's preferred DE/HL. Out
  of scope here; worth an O6x follow-up.

---

## 8. References

* [V6C Build Guide](docs/V6CBuildGuide.md)
* [V6C Architecture](docs/V6CArchitecture.md)
* [V6C Calling Convention](docs/V6CCallingConvention.md)
* [V6C Optimization](docs/V6COptimization.md)
* [Vector 06c CPU Timings](docs/Vector_06c_instruction_timings.md)
* [Future Improvements](design/future_plans/README.md)
* [V6CInstrInfo.td — 8-bit ALU defs](llvm/lib/Target/V6C/V6CInstrInfo.td#L243)
* [V6CInstrInfo.td — 16-bit ALU pseudos](llvm/lib/Target/V6C/V6CInstrInfo.td#L720)
* [V6CAccumulatorPlanning.cpp](llvm/lib/Target/V6C/V6CAccumulatorPlanning.cpp)
* [V6CISelDAGToDAG.cpp](llvm/lib/Target/V6C/V6CISelDAGToDAG.cpp)
* LLVM `TwoAddressInstructionPass` — consumes `isCommutable`
* LLVM `TargetInstrInfo::commuteInstructionImpl` — default commute impl
