# Plan: O55 — `MVI A, 0` → `XRA A` Peephole (when FLAGS dead)

## 1. Problem

### Current behavior

After ISel + register allocation, the V6C backend emits `MVI A, 0`
(2 bytes, 8 cc) wherever a zero needs to be materialised in the
accumulator. There is no post-RA pass that downgrades it to `XRA A`
(1 byte, 4 cc) when the change in flag state is irrelevant.

Concrete example from [tests/lit/CodeGen/V6C/const-i8.ll](tests/lit/CodeGen/V6C/const-i8.ll):

```asm
const_zero:
        MVI     A, 0     ; 2B / 8cc  — could be XRA A (1B / 4cc)
        RET
```

`RET` does not read FLAGS, so writing flags here is benign — but the
backend leaves the longer encoding in place.

### Desired behavior

Post-RA peephole: when an `MVI A, 0` is followed (in linear program
order, possibly after debug instructions) by a region in which FLAGS
is **dead**, rewrite it to `XRA A`. Save 1 byte and 4 cycles per
instance.

```asm
const_zero:
        XRA     A        ; 1B / 4cc
        RET
```

### Root cause

ISel selects `MVI A, 0` because it is unconditionally safe (no flag
side-effect). The narrower `XRA A` encoding requires *liveness*
information that is only reliable post-RA, so it cannot be expressed
as a tablegen pattern. No existing pass currently performs this
downgrade.

The two related peepholes that already exist solve different problems:

* O38 (`foldXraCmpZeroTest` in
  [V6CPeephole.cpp](llvm/lib/Target/V6C/V6CPeephole.cpp)) seeds
  `XRA A` *upstream* of zero-test branches.
* O13 (LoadImmCombine,
  [V6CLoadImmCombine.cpp](llvm/lib/Target/V6C/V6CLoadImmCombine.cpp))
  deletes `MVI A, 0` when an earlier `XRA A` already left A=0.

Neither covers the standalone "trailing `MVI A, 0`" case (e.g. a
function whose last act is to return 0).

### Scope decision (parent spec O55 has 3 patterns)

The parent design [`design/future_plans/O55_additional_peepholes.md`](design/future_plans/O55_additional_peepholes.md)
proposes three patterns:

| Pattern | Empirical occurrences (entire V6C lit corpus) | Decision |
|---|---|---|
| 1. `XRI 0FFH` → `CMA`            | 0 (already handled at ISel: `(not i8) → CMA`)             | **Skip** (dead code) |
| 2. `MVI A, 0` → `XRA A` (FLAGS dead) | 25 raw / handful safe (e.g. `const_zero/RET`)         | **Implement** |
| 3. `ANI n; ANI n` / `ORI n; ORI n` idempotent | 0                                          | **Skip** (dead code) |

This plan implements only Pattern 2. Patterns 1 and 3 produce zero
test-corpus opportunities and adding code paths that no test exercises
would be dead weight. The parent spec will be updated in Phase 5 with
this verification result.

---

## 2. Strategy

### Approach: post-RA peephole, FLAGS-liveness gated

Add a new member `foldMviZeroToXraA` to the existing `V6CPeephole`
pass. For each `MVI A, 0` instruction:

1. Confirm the immediate is exactly `0` and the destination is `A`.
2. Use the existing `isRegDeadAfter(MBB, I, V6C::FLAGS, TRI)` helper
   to verify FLAGS is dead after the `MVI A, 0`.
3. Replace the instruction in-place with `XRAr A, A, A` (the canonical
    3-operand form already used by `foldXraCmpZeroTest`).

### Why this works

* `isRegDeadAfter` already handles the common cases: it scans
  forward, treats any FLAGS use (e.g. `Jcc`, `RST*`, `Rcc`) as live,
  any FLAGS def as dead-from-here, and falls through to successor
  live-in queries when the block ends. The same helper is in active
  service for O18 / O38 / O44 / O65, so its semantics are well
  understood.
* `XRA A` produces A=0 with the same width / semantics as
  `MVI A, 0`. The only observable difference is the flag side-effect,
  and we guard against that.
* Running this pass last (after every other peephole that might
  generate fresh `MVI A, 0`) maximises hits without risk.

### Composition with other passes

* **O13 / LoadImmCombine** — after this peephole rewrites
  `MVI A, 0` to `XRA A`, O13's existing forward value-tracking
  recognises `XRA A` as a known-zero seed (see
  [V6CLoadImmCombine.cpp:550-555](llvm/lib/Target/V6C/V6CLoadImmCombine.cpp)),
  so any *further* downstream `MVI A, 0` is still subject to its
  cascade rule. Order: V6CPeephole runs before LoadImmCombine in the
  pass pipeline already (no change required).
* **O38 / foldXraCmpZeroTest** — independent; that pass produces
  `XRA A` in a different shape (replacing a `MOV A, r; ORA A`).

### Summary of changes

| File | Change |
|------|--------|
| `llvm-project/llvm/lib/Target/V6C/V6CPeephole.cpp` | New helper `foldMviZeroToXraA`, dispatched from `runOnMachineFunction` |
| `llvm-project/llvm/test/CodeGen/V6C/peephole-mvi-zero-to-xra.ll` | New lit test |
| `tests/features/46/` | Feature regression test (C source pair, baseline + post asm, `result.txt`) |
| `design/future_plans/O55_additional_peepholes.md` | Mark Pattern 2 done; record verification that Patterns 1 and 3 are obsolete |
| `design/future_plans/README.md` | Mark O55 ✅ |

---

## 3. Implementation Steps

### Step 3.1 — Add `foldMviZeroToXraA` to V6CPeephole [x]

**File**: `llvm-project/llvm/lib/Target/V6C/V6CPeephole.cpp`

Add a new member function:

```cpp
/// Replace `MVI A, 0` with `XRA A` when FLAGS is dead after the
/// instruction. Saves 1 byte and 4 cycles per instance. (O55 P2.)
bool V6CPeephole::foldMviZeroToXraA(MachineBasicBlock &MBB);
```

Pattern matched:

```text
MVI  A, 0      ; V6C::MVIr, op0 = A, op1 = imm 0
              <FLAGS dead from here on>
```

Body:

```cpp
bool V6CPeephole::foldMviZeroToXraA(MachineBasicBlock &MBB) {
  bool Changed = false;
  const TargetRegisterInfo *TRI =
      MBB.getParent()->getSubtarget().getRegisterInfo();
  const TargetInstrInfo &TII =
      *MBB.getParent()->getSubtarget().getInstrInfo();

  for (MachineInstr &MI : llvm::make_early_inc_range(MBB)) {
    if (MI.getOpcode() != V6C::MVIr)
      continue;
    if (MI.getOperand(0).getReg() != V6C::A)
      continue;
    if (!MI.getOperand(1).isImm() || MI.getOperand(1).getImm() != 0)
      continue;
    if (!isRegDeadAfter(MBB, MI.getIterator(), V6C::FLAGS, TRI))
      continue;

    BuildMI(MBB, MI, MI.getDebugLoc(), TII.get(V6C::XRAr), V6C::A)
        .addReg(V6C::A)
        .addReg(V6C::A);
    MI.eraseFromParent();
    Changed = true;
  }
  return Changed;
}
```

Dispatch from `runOnMachineFunction`, after the existing peepholes
(so any prior pass that produced a fresh `MVI A, 0` is also caught):

```cpp
Changed |= eliminateTailCall(MBB);
Changed |= foldMviZeroToXraA(MBB);   // O55 — added
```

> **Design Notes**:
> * Using `make_early_inc_range` is safe because we only erase the
>   current instruction.
> * The `isRegDeadAfter` helper is the same one O18 / O38 / O44 /
>   O65 already trust for FLAGS / A-liveness. No new infrastructure.
> * Keeping the `XRA A` construction in the canonical
>   3-operand form (`def, lhs-use, rhs-use`) matches the
>   accumulator-ALU instruction layout (see
>   [V6CInstrInfo.td:280-298](llvm/lib/Target/V6C/V6CInstrInfo.td))
>   and the existing `foldXraCmpZeroTest` site, so consumers that
>   already understand `XRA A` (LoadImmCombine, BranchOpt) keep
>   working.

> **Implementation Notes**: Implemented exactly as drafted. The new
> method declaration was added directly after `foldIncDecMviM`, the
> body was inserted just before `runOnMachineFunction`, and the
> dispatch was placed at the end of the per-MBB call chain so any
> peephole earlier in the pass that emits a fresh `MVI A, 0` (today
> none do, but defensively future-proofed) is still caught.

### Step 3.2 — Build [x]

```
cmd /c "call ""C:\Program Files\Microsoft Visual Studio\2022\Community\Common7\Tools\VsDevCmd.bat"" -arch=amd64 >nul 2>&1 && ninja -C llvm-build clang llc 2>&1"
```

> **Implementation Notes**: Clean build, no warnings.

### Step 3.3 — Lit test: `peephole-mvi-zero-to-xra.ll` [x]

**File**: `llvm-project/llvm/test/CodeGen/V6C/peephole-mvi-zero-to-xra.ll`

Two functions:

* `safe_const_zero` — returns `i8 0`. After O55 the body must contain
  `XRA A` and no `MVI A, 0`.
* `unsafe_after_sub` — `(a - b) >= 0 ? 7 : 11`. After SUB, FLAGS (CY)
  is live across `MVI A, 0`, so the peephole must **not** fire and
  the `MVI A, 0` must remain.

`FileCheck` directives assert both expectations.

> **Implementation Notes**: Three cases used: `const_zero` (positive,
> trailing zero before RET), `cold_zero` (positive, zero on the
> JP-not-taken arm — FLAGS already consumed by JP), and `add_i32`
> (negative — `SBB D ; MVI A, 0 ; JNC` carry-fold pattern; the
> peephole must NOT fire here). The original draft `unsafe_after_sub`
> (`(a-b)<0 ? 0 : 7`) was discarded because the i8 select-result on
> the cold path turned out to be lowered as `XRA A` already (no MVI
> A,0 to defend against). The i32 carry-fold is the canonical
> FLAGS-live-across-MVI shape in real V6C codegen.

### Step 3.4 — Run regression tests [x]

```
python tests\run_all.py
```

If any test fails, diagnose, fix, rebuild, rerun.

> **Implementation Notes**: 120/121 lit tests pass after sync. Four
> pre-existing tests legitimately needed CHECK-line updates because
> their generated asm now contains `XRA A` where it previously
> contained `MVI A, 0` (this is the optimisation working as designed):
> `const-i8.ll`, `cmp-i16.ll`, `load-imm-combine.ll`,
> `loop-cmp-imm.ll`. The remaining failure,
> `ipra-call-preservation.ll`, is a pre-existing regression unrelated
> to O55 (verified by stashing the V6CPeephole change and observing
> the same failure: it expects `MOV D, H` but actual is `MOV D, M`,
> a stack-reload shape change with no FLAGS interaction). Logged for
> separate investigation.

### Step 3.5 — Verification assembly steps from `tests\features\README.md` [x]

Test folder: `tests\features\46\`. Compile `v6llvmc.c` with
`clang -O2 -S` to `v6llvmc_new01.asm`. Confirm:

* `const_zero()` returns via `XRA A; RET` (1B + 1B vs old 2B + 1B).
* The branch-on-subtract case keeps `MVI A, 0` intact.

If improvement absent, iterate (`v6llvmc_new02.asm`, …).

> **Implementation Notes**: First-pass `v6llvmc_new01.asm` already
> exhibits the expected rewrite at all five candidate sites
> (`const_zero`, `clear_sink_twice`, `neg_or_seven` else-arm, `main`
> entry, `main` JP-not-taken arm). No iteration required. The
> negative case (FLAGS-live carry fold) is exercised by the i32
> arm of the lit test rather than by feature 46 -- the sub-byte
> ternary in `neg_or_seven` happens to leave FLAGS dead between the
> JP and the constant-zero return, so it triggers the rewrite
> safely.

### Step 3.6 — Make sure result.txt is created [x]

Per `tests\features\README.md`, `result.txt` must contain: C source,
c8080 main + dependent funcs (i8080 form), c8080 worst-cycle/byte
stats per func, v6llvmc asm, v6llvmc worst-cycle/byte stats.

> **Implementation Notes**: Created `tests/features/46/result.txt`.
> Headline numbers: 5 rewrite sites, -5 bytes / -12 cc total across
> the test (`const_zero` -1B/-3cc, `clear_sink_twice` -1B/-3cc,
> `neg_or_seven` -1B/0cc on worst path, `main` -2B/-6cc).

### Step 3.7 — Sync mirror [x]

```
powershell -ExecutionPolicy Bypass -File scripts\sync_llvm_mirror.ps1
```

> **Implementation Notes**: Synced. `tests/lit/CodeGen/V6C/` mirror
> updated; `python tests\run_all.py` reports 120/121 lit + golden PASS
> (the one fail is the pre-existing IPRA regression noted above).

---

## 4. Expected Results

### Example 1 — `int8_t const_zero(void) { return 0; }`

Before:

```asm
const_zero:
        MVI  A, 0      ; 2B / 8cc
        RET
```

After:

```asm
const_zero:
        XRA  A         ; 1B / 4cc
        RET
```

Saves 1 byte / 4 cycles.

### Example 2 — Negative case: post-arithmetic constant load

```c
int8_t neg_or_seven(int8_t a, int8_t b) {
    return (a - b) < 0 ? 0 : 7;
}
```

Lowering produces `SUB ; MVI A, 0 ; JNC ; ...` where `JNC` reads CY
from `SUB`. The peephole's FLAGS-dead check sees the `JNC` and
declines to rewrite. No regression, no functional change.

### Example 3 — Cooperation with O38 / O13

In a function that already triggers O38, the resulting
`XRA A` seeds O13's known-zero map and any *downstream* `MVI A, 0`
is deleted. O55 catches the *upstream* `MVI A, 0` that O38 doesn't
look at — for instance a constant-zero return after a side-effect
call where the FLAGS live range ended.

---

## 5. Risks & Mitigations

| Risk | Mitigation |
|------|------------|
| Mis-identifying FLAGS as dead → silently flipping a downstream branch | Reuse the audited `isRegDeadAfter` helper — same one O18/O38/O44/O65 already rely on. Lit test asserts that the `SUB / MVI A, 0 / JNC` shape is *not* rewritten. |
| Peephole creates a fresh `XRA A` that defeats a still-needed A=k known-value tracked by O13 | A was about to be set to 0 by `MVI A, 0`, so any prior known value of A was already going to be killed. Net A semantics identical. |
| Iterator invalidation during in-place rewrite | `make_early_inc_range` advances the iterator before the body runs; we only erase the current MI. |
| Pattern 1 / Pattern 3 from parent spec left undone | They have **zero** occurrences in the entire V6C lit corpus today (`(not i8)` is already lowered to `CMA` at ISel, idempotent ALU pairs are never produced). Documented in the O55 plan file with the empirical scan as evidence. Can be revisited if a future codegen change starts producing them. |

---

## 6. Relationship to Other Improvements

* **O13** — complementary: O55 *creates* `XRA A` instances, which O13
  then uses to delete *downstream* redundant `MVI A, 0`. Net win
  compounds.
* **O38** — independent: O38 produces `XRA A` from `MOV A,r; ORA A`;
  O55 produces it from `MVI A, 0`. Different sources, same target.
* **O17 (Redundant Flag Elimination)** — orthogonal: O17 removes
  redundant flag-setting instructions; O55 *narrows* a non-flag
  setter to a flag setter (only when flags are dead).
* **O63 (drop false FLAGS def on static-stack spill pseudos)** —
  unrelated, but improves the precision of FLAGS liveness once
  landed, which would only enlarge O55's hit set.

## 7. Future Enhancements

* **Sister pattern `LXI rp, 0` → cheaper sequence** — out of scope,
  but a small `LXI BC, 0` peephole could use the same liveness tools.
* **Re-evaluate Pattern 3 (idempotent `ANI n; ANI n`)** if O53
  (enhanced value tracking) ever starts emitting bit-mask redundant
  pairs.

## 8. References

* [V6C Build Guide](docs/V6CBuildGuide.md)
* [Vector 06c CPU Timings](docs/Vector_06c_instruction_timings.md)
* [Future Improvements](design/future_plans/README.md)
* [O55 parent spec](design/future_plans/O55_additional_peepholes.md)
* [O38 plan (sibling peephole creating `XRA A`)](design/plan_xra_cmp_zero_test.md)
* [O13 plan (downstream consumer of `XRA A`)](design/plan_load_immediate_combining.md)
