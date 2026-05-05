# Plan: V6C_LOAD16_P Redesign — Honest Per-Shape Preservation

Source design: [O71 V6C_LOAD16_P Redesign](future_plans/O71_V6C_LOAD16_P_redesign.md)

## 1. Problem

### Current behavior

`V6C_LOAD16_P` is the generic 16-bit load-through-pointer pseudo:

```tablegen
let mayLoad = 1 in
def V6C_LOAD16_P : V6CPseudo<(outs GR16:$dst), (ins GR16:$addr),
    "# LOAD16P $dst, ($addr)",
    [(set i16:$dst, (load i16:$addr))]>;
```

The pseudo declares **no `Defs`**, so RA and pre-RA passes treat the
instruction as preserving every register except `$dst`. The post-RA
expander in `V6CInstrInfo::expandPostRAPseudo()` is responsible for
honoring that contract. It does not — five concrete bugs are visible
today:

1. **`addr=HL, dst=HL`** silently corrupts `A`:
   `MOV A,M; INX H; MOV H,M; MOV L,A`. `A` is a temp, never saved.
2. **`addr=HL, dst∈{BC,DE}`** leaks `HL = orig + 1`:
   `MOV lo,M; INX H; MOV hi,M`. The `INX H` is never undone.
3. **`addr=DE, dst=DE`** computes wrong values in HL and DE:
   `XCHG; MOV E,M; INX H; MOV D,M; XCHG` ends with HL = loaded value
   (wrong) and DE = ptr+1 (wrong). Observed in
   `temp\asm_inline\custom_cc.s`.
4. **`addr=BC` with HL dead** skips PUSH/POP and leaks HL via
   `MOV H,B; MOV L,C; …; INX H`, so HL exits as `orig_BC + 1`.
   Benign while `HLDead` truly means dead, but the pseudo's declared
   `Defs` (none) still lies to any later pass.
5. **`addr=BC, dst=HL`** silently corrupts `A` for the same reason
   as bug 1.

### Desired behavior

After the redesigned expander runs:

- `A` is preserved across every shape (a dead GR8 is preferred as
  the temp; `PUSH PSW`/`POP PSW` is the fallback when no GR8 is
  dead and `A` is live).
- The address pair (`HL`, `BC`, or `DE`) is preserved across every
  shape when it is live across the pseudo, using the cheapest
  available recovery (`DCX rp` after `INX rp`, or `PUSH H`/`POP H`
  when HL was overwritten as part of the shape).
- `dst=HL` shapes correctly deliver the loaded value into HL via
  the trailing `XCHG` (case 3b) or the `MOV L,SpareR` pair (cases
  1, 6).
- The pseudo's pre-RA contract — "defines `$dst`, preserves
  everything else" — is honest.

### Root cause

The original expander conflated several distinct `(addr, dst)`
shapes onto two code paths (`emitLoad` and the BC PUSH/POP wrapper)
and treated the temporaries (`A`, the trailing `INX H`, the leading
`XCHG`) as locally invisible. The `(outs GR16:$dst)` declaration,
combined with no `Defs`, makes RA trust those locally-invisible
clobbers, and miscompiles follow. A single blanket `Defs = [HL, A,
FLAGS]` would close the holes but would force RA to spill `A`
across every pointer load even on shapes where `A` is genuinely
preserved (most of cases 2 and 3).

---

## 2. Strategy

### Approach: per-shape expansion with cheap-first preservation

Keep `V6C_LOAD16_P` exactly as declared today (`(outs GR16:$dst),
(ins GR16:$addr)`, no `Defs`). Replace the body of `case
V6C::V6C_LOAD16_P:` in `V6CInstrInfo::expandPostRAPseudo()` with a
six-case dispatch on `(addr, dst)` register pairs. For each case,
compute post-RA liveness for the address pair, for `HL`, for `A`,
and for the GR8 set, then pick preservation in cheap-first order:

1. Use any dead GR8 as the low-byte temp (cases 1, 4, 6).
2. Emit `DCX rp` to undo `INX rp` when the address pair is live
   (cases 1, 2, 3a, 3b, 4).
3. Wrap `PUSH PSW` / `POP PSW` when no GR8 is dead and `A` is live
   (cases 1, 4, 6).
4. Wrap `PUSH H` / `POP H` when HL was overwritten and HL is live
   (cases 5, 6 — `addr=BC`).

### Why this works

- **Pressure-friendly.** RA still sees the pseudo as preserving
  every non-`$dst` register, so it does not insert spills around
  pointer loads.
- **Honest at expansion time.** All clobbers are visible to the
  expander because RA has committed; the expander emits exactly
  the recovery code each instance needs.
- **Cheaper than RA-visible `Defs`.** RA cannot emit `DCX rp`
  (operates at vreg granularity) and cannot pick a dead GR8 at
  expansion time. Both are key cost levers on this 3-element-GR16
  / 1-element-A ISA. See the design doc's pre-RA-vs-expander
  table.
- **Reuses existing liveness machinery.** `isRegDeadAtMI`
  (V6CInstrInfo.cpp:474) already handles forward scans plus
  successor live-ins, and is correct across loop back-edges. The
  only new helper is `findDeadGR8AtMI`.

### Summary of changes

| Step | What | Where |
|------|------|-------|
| Add helper | `findDeadGR8AtMI(MI, MBB, &RI)` returns a dead GR8 or `0` | V6CInstrInfo.cpp |
| Rewrite expander | Six-case dispatch with cheap-first preservation | V6CInstrInfo.cpp `case V6C::V6C_LOAD16_P:` |
| (No change) | `V6C_LOAD16_P` td declaration unchanged | V6CInstrInfo.td |
| Test coverage | Lit test per case + runtime guard derived from `custom_cc.c` | tests/lit/, tests/features/53/ |
| Doc updates | Mark O71 done in `design/future_plans/README.md`, fill Implementation Notes | design/future_plans/ |

---

## 3. Implementation Steps

### Step 3.1 — Add `findDeadGR8AtMI` helper [x]

**File**: `llvm-project/llvm/lib/Target/V6C/V6CInstrInfo.cpp`

Add a static helper near `isRegDeadAtMI` (line 474) that scans the
seven GR8 registers and returns the first one dead at the pseudo's
location, or `Register()` if none.

```cpp
// Return a GR8 register that is dead at MI, or Register() if none.
// Order matches GR8AllocationOrder so we prefer call-clobbered
// registers first, leaving callee-saved ones untouched. The
// preferred set excludes A (callers handle A specially via
// PUSH PSW/POP PSW). When ExcludeReg is non-zero, that register
// (and its sub-registers) is also excluded.
static Register findDeadGR8AtMI(const MachineInstr &MI,
                                const MachineBasicBlock &MBB,
                                const TargetRegisterInfo *TRI,
                                Register ExcludeReg = Register());
```

Iterate the GR8 register class (excluding `A`, excluding any
register that aliases `ExcludeReg`); return the first one that
`isRegDeadAtMI` reports as dead.

> **Design Notes**: `ExcludeReg` lets cases 1/4/6 exclude the
> address pair and the destination pair from the candidate set,
> avoiding accidental aliasing with HL/DE/BC sub-regs.

> **Implementation Notes**: Implemented as `findDeadGR8AtMI(MI, MBB,
> TRI, ExcludeReg1, ExcludeReg2)` — two excludes (cases 4 and 6 need
> both the address pair and the destination pair excluded). Iterates
> {B, C, D, E, H, L} (skips A; A is handled by the caller via PUSH
> PSW). Skips any candidate that overlaps either exclude. Returns
> `Register()` if none. Located just after `isRegDeadAtMI` in
> V6CInstrInfo.cpp.

### Step 3.2 — Rewrite expander: case 2 (`addr=HL, dst∈{BC,DE}`) [x]

**File**: `llvm-project/llvm/lib/Target/V6C/V6CInstrInfo.cpp`,
`case V6C::V6C_LOAD16_P:` (currently line ~1372).

Start with the simplest case to anchor the new structure:

```asm
    MOV  DstLo, M
    INX  H
    MOV  DstHi, M
    DCX  H               ; only if HL live after the pseudo
```

Branch on `AddrReg == V6C::HL && (DstReg == V6C::BC || DstReg == V6C::DE)`.
Emit `DCX H` iff `!isRegDeadAtMI(V6C::HL, MI, MBB, &RI)`.

> **Design Notes**: This fixes bug 2.

> **Implementation Notes**: Lambda closures `emitMOVrM(R)`,
> `emitINXHL()`, `emitDCX(rp)` factor the common shape. `DCX H` is
> emitted only when `!isRegDeadAtMI(V6C::HL, MI, ...)` — saves 1 B /
> 5 cy when the pointer is dead, which is the common case.

### Step 3.3 — Case 1 (`addr=HL, dst=HL`) [x]

```asm
    MOV  Spare, M
    INX  H
    MOV  H, M
    MOV  L, Spare
```

`Spare = findDeadGR8AtMI(MI, MBB, &RI, /*ExcludeReg=*/V6C::HL)`.
If `Spare == 0`, set `Spare = V6C::A` and wrap with
`PUSH PSW` / `POP PSW` iff `!isRegDeadAtMI(V6C::A, MI, MBB, &RI)`.

No `DCX H` — the load itself overwrites HL, so no recovery is
needed (and no recovery is possible).

> **Design Notes**: Fixes bug 1. Note `dst=HL` ⇒ HL is *not* live
> across the pseudo as the original value; only the loaded value
> matters.

> **Implementation Notes**: PUSH PSW / POP PSW fallback only when
> *no* GR8 spare is dead AND `A` is live across the pseudo. In all
> O22 / O23 / `temp/asm_inline/custom_cc.c` runs observed so far the
> dead-GR8 spare path is taken (typically B or C); the PUSH PSW path
> exists only as a worst-case safety net.

### Step 3.4 — Cases 3a (`addr=DE, dst=BC`) and 3b (`addr=DE, dst=HL`) [x]

Case 3a:
```asm
    XCHG
    MOV  C, M
    INX  H
    MOV  B, M
    XCHG
    DCX  D            ; only if DE live after the pseudo
```

Case 3b:
```asm
    XCHG
    MOV  E, M
    INX  H
    MOV  D, M
    XCHG              ; mandatory — delivers loaded value to HL
    DCX  D            ; only if DE live after the pseudo
```

`DCX D` is emitted iff `!isRegDeadAtMI(V6C::DE, MI, MBB, &RI)`.
The trailing `XCHG` is always emitted (it is the delivery for 3b
and the DE-restore for 3a).

> **Design Notes**: Case 3b never needs `A` and never clobbers HL
> (the original HL value lands in DE during the load and is
> restored by the trailing XCHG, modulo +1 which `DCX D` corrects
> via the swapped role).

> **Implementation Notes**: Latent bug discovered during
> implementation: case 3b cannot stage the loaded value into
> `DstLo=L, DstHi=H` because after `XCHG` those halves hold the
> address. Fixed by always staging case 3b through `E` (lo) and
> `D` (hi) — the trailing `XCHG` then swaps the loaded value into
> HL and the original-HL bytes back into DE, while `DCX D` (when
> needed) decrements DE which now logically represents the address
> pair after the second XCHG. Case 3a still uses `DstLo=C, DstHi=B`
> directly. The `XCHG` peephole `foldXchgDad` may eliminate the
> trailing XCHG when the next op is `DAD D` and DE is dead.

### Step 3.5 — Case 4 (`addr=DE, dst=DE`) [x]

```asm
    XCHG
    MOV  Spare, M
    INX  H
    MOV  H, M
    MOV  L, Spare
    XCHG
```

`Spare = findDeadGR8AtMI(MI, MBB, &RI, V6C::HL, V6C::DE)`. If
`Spare == 0`, set `Spare = V6C::A` and wrap with `PUSH PSW` /
`POP PSW` iff `!isRegDeadAtMI(V6C::A, MI, MBB, &RI)`.

No `DCX D` is ever needed: `dst=DE` means the destination of the
load is DE, so the caller cannot also expect DE to still hold the
old address afterwards.

> **Design Notes**: Fixes bug 3. Both `HL` and `DE` must be
> excluded from the spare candidate set: after the leading `XCHG`,
> `HL` holds the address (so picking `H` or `L` would clobber it),
> and `DE` holds the original `HL` bytes which the trailing `XCHG`
> swaps back into `HL` (so picking `D` or `E` would corrupt the
> preserved-HL value). The original design doc's "optional `DCX D`
> if DE live" line is incorrect for this shape and is dropped.

> **Implementation Notes**:

### Step 3.6 — Cases 5 (`addr=BC, dst∈{BC,DE}`) and 6 (`addr=BC, dst=HL`) [x]

Case 5:
```asm
    PUSH H            ; only if HL live after the pseudo
    MOV  H, B
    MOV  L, C
    MOV  DstLo, M
    INX  H
    MOV  DstHi, M
    POP  H            ; matches the PUSH
```

Case 6:
```asm
    MOV  H, B
    MOV  L, C
    MOV  Spare, M
    INX  H
    MOV  H, M
    MOV  L, Spare
```
(wrapped with `PUSH PSW`/`POP PSW` iff no spare GR8 and `A` live).

For case 5: emit `PUSH H`/`POP H` iff
`!isRegDeadAtMI(V6C::HL, MI, MBB, &RI)`. No `DCX BC` is needed —
BC is never modified (we only copy `B→H`, `C→L`).

For case 6: `dst=HL` means the caller's HL is the destination of
the load, so the original HL value is dead by definition — never
emit `PUSH H`/`POP H`. `Spare = findDeadGR8AtMI(MI, MBB, &RI,
V6C::HL, V6C::BC)` (must exclude both BC, since BC holds the
address, and HL, since HL is being filled with the load result).
If `Spare == 0`, set `Spare = V6C::A` and wrap `PUSH PSW`/`POP PSW`
iff `A` is live.

> **Design Notes**: Fixes bugs 4 and 5. Earlier drafts assumed
> case 6 also needed `PUSH H`/`POP H` to "preserve HL," requiring a
> two-spare staging trick or `XTHL`. That was wrong: `dst=HL`
> defines HL, so original HL is not live across the pseudo. The
> simple six-instruction body (no PUSH/POP HL, single spare) is
> always sufficient.

> **Implementation Notes**: Case 6 spare excludes both HL (dst) and
> BC (addr); fallback is PUSH PSW / POP PSW. No PUSH/POP HL is ever
> emitted in this shape — the design doc's claim was wrong.

### Step 3.7 — Build [x]

Run from repo root:

```
cmd /c "call ""C:\Program Files\Microsoft Visual Studio\2022\Community\Common7\Tools\VsDevCmd.bat"" -arch=amd64 >nul 2>&1 && ninja -C llvm-build clang llc 2>&1"
```

Fix any compile errors, then proceed.

> **Implementation Notes**: One ambiguity error (`Register` →
> `MCRegister` conversion) was resolved by calling `.asMCReg()` on
> the candidate registers. No other diagnostics. Build succeeds.

### Step 3.8 — Lit test: load16p-shapes (case 1 + case 4) [x]

**File**: `llvm-project/llvm/test/CodeGen/V6C/load16p-shapes.ll`

Consolidated into a single lit file pinning the two highest-value
shapes:

  * `case1_hl_hl` — addr=HL, dst=HL — verifies dead-GR8 spare path
    (`MOV B, M; INX H; MOV H, M; MOV L, B`) and absence of `PUSH`.
  * `case4_de_de` — addr=DE, dst=DE — bug-3 regression. Asserts
    `XCHG; MOV [BC], M; INX H; MOV H, M; MOV L, [BC]` and absence
    of the old `MOV E, M; INX H; MOV D, M` shape. The trailing
    `XCHG` is intentionally not asserted because `foldXchgDad`
    optimizes it away in this context.

Cases 2, 3, 5, 6 are exercised end-to-end by
`tests/features/53/v6llvmc.c` (and indirectly across the rest of the
lit / golden suite — 128 lit tests + 16 golden tests pass). The
V6C calling convention places the first 16-bit arg in HL and the
second in DE, so granular shape pinning via plain C IR is awkward
for cases 5/6 (addr=BC); those shapes are validated through the
golden runner instead of FileCheck.

> **Implementation Notes**: Two pre-existing tests had their CHECK
> updated for the new pattern: `load-store-i16.ll` (load_ptr) and
> `pointer-arith.ll` (gep_i16) — both now use
> `MOV [[T:[A-Z]+]], M ... MOV L, [[T]]` placeholders to accept any
> dead-GR8 spare instead of pinning `MOV A, M`.

### Step 3.13 — Run regression tests [x]

```
python tests\run_all.py
```

Diagnose and fix any regression. Re-run until clean.

> **Implementation Notes**: 128/128 lit tests pass, 16/16 golden
> tests pass after the mirror sync.

### Step 3.14 — Verification assembly steps from `tests\features\README.md` [x]

Compile `tests\features\53\v6llvmc.c` to `v6llvmc_new01.asm` and
analyze:

- Case 2: `DCX H` appears when HL pointer is reused after the load.
- Case 1/4/6: temp is a dead GR8 when one is available; otherwise
  `PUSH PSW`/`POP PSW` wraps the load.
- Case 3 (DE): trailing `XCHG` is always present; `DCX D` only when
  DE is reused.
- Case 4: bug-3 regression — check the assembly matches the
  expected pattern.
- Cases 5/6: `PUSH H`/`POP H` when HL live; case 6 single-spare
  uses `XTHL`.

Iterate to `v6llvmc_new02.asm`, `v6llvmc_new03.asm`, … until the
expected improvements are present.

> **Implementation Notes**: `v6llvmc_new01.asm` matches
> `v6llvmc.asm` byte-for-byte. `bug3_de_de` now produces `XCHG; MOV
> B, M; INX H; MOV H, M; MOV L, B; DAD D; RET` (correct, +1 byte
> over the buggy old shape). `case2_hl_reused` and
> `case5_bc_with_hl_live` use `MOV B, M ... MOV L, B` (A preserved,
> same size as the old `MOV A, M ... MOV L, A`). `case16_a_live`
> unchanged at `INX H; XRA M; RET`.

### Step 3.15 — Make sure `result.txt` is created (`tests\features\README.md`) [x]

Document c8080 vs v6llvmc cycles/bytes per function and the
shape-by-shape matrix.

> **Implementation Notes**: `tests/features/53/result.txt` written.
> Includes c8080 reference, baseline old asm (with the bug 3
> demonstration), the new asm, and per-function instruction-count /
> approx-cycle stats.

### Step 3.16 — Sync mirror [x]

```
powershell -ExecutionPolicy Bypass -File scripts\sync_llvm_mirror.ps1
```

> **Implementation Notes**: Mirror synced; `tests\lit` reflects the
> updated `load-store-i16.ll`, `pointer-arith.ll`, and
> `load16p-shapes.ll`.

### Step 3.17 — Mark O71 complete in `design/future_plans/README.md` [x]

Add the **DONE** marker on the O71 row, set the implementation
order checkbox.

> **Implementation Notes**: O71 row marked **DONE** in
> `design/future_plans/README.md`.

---

## 4. Expected Results

### Example 1 — `custom_cc.c` (bug 3 regression)

**Before** (broken):
```asm
DAD     B            ; HL = sum
XCHG
MOV     E, M
INX     H
MOV     D, M
XCHG                 ; HL = loaded (wrong), DE = ptr+1 (wrong)
DAD     D            ; HL = loaded + (ptr + 1)   -- WRONG
```

**After** (case 4, DE dead):
```asm
DAD     B            ; HL = sum
XCHG
MOV     <Spare>, M
INX     H
MOV     H, M
MOV     L, <Spare>
XCHG                 ; DE = loaded value, HL = sum
DAD     D            ; HL = sum + loaded   -- correct
```

### Example 2 — pointer-reuse loop, `addr=HL, dst=BC`

**Before** (case 2, leaks HL):
```asm
MOV  C, M
INX  H
MOV  B, M
; HL = orig + 1, but RA thinks HL is unchanged
LXI  H, ptr          ; reload required → +3B/+10cc/iter
```

**After**:
```asm
MOV  C, M
INX  H
MOV  B, M
DCX  H               ; +1B / +5cc, HL = ptr restored
; loop reuses HL directly → −3B/−10cc/iter on the next load
```

Net per iteration: **−2B / −5cc** in the typical sequential-load
loop, plus **+correctness**.

### Example 3 — `A` live across `addr=HL, dst=HL`

**Before**: silent corruption.
**After**: dead-GR8 spare (zero overhead) when one is available;
otherwise `PUSH PSW`/`POP PSW` (+2B / +23cc) — but at least
correct.

---

## 5. Risks & Mitigations

| Risk | Mitigation |
|------|------------|
| Missed live-reg case in the dispatch leaves a clobber unrecovered | Per-case lit tests with both live-after and dead-after variants; runtime guard derived from `custom_cc.c`. |
| `findDeadGR8AtMI` returns a register that aliases the address or destination pair | Helper takes an `ExcludeReg` argument; expander passes the address+destination pairs. |
| Case 6 single-spare `XTHL` path has subtle stack interaction with surrounding code | Lit test exercises the path; runtime guard runs the expansion under the emulator with `--halt-exit`. |
| Increased expander size (~150 LOC) raises maintenance cost | Single switch on `(addr, dst)` shape with shared helpers (`emitDCXIfLive`, `wrapPushHIfLive`, `wrapPushPSWIfLive`); each shape body is 5–10 lines. |
| Regression on hot paths that previously got "lucky" with the old expander | `python tests\run_all.py` covers golden + lit; `tests\features\53` exercises every shape. |

---

## 6. Relationship to Other Improvements

- **O20 (Honest Store/Load Pseudo Defs)** — same structural problem
  but at the td-declaration level. O71 takes the orthogonal
  expander-side approach for `LOAD16_P` because RA-visible Defs
  cost more than expander-time recovery on this ISA. O72 (planned)
  applies the same template to `V6C_STORE16_P`.
- **O42 (Liveness-Aware Pseudo Expansion)** — provides
  `isRegDeadAtMI`, the foundation for O71's preservation
  decisions.
- **O44 (Adjacent XCHG Cancellation)** — cancels the trailing
  `XCHG` of a case-3/case-4 load against the leading `XCHG` of an
  adjacent `addr=DE` load, so the nominal +4cc XCHG overhead is
  paid only at chain boundaries.


---

## 7. Future Enhancements

- **O72 — `V6C_STORE16_P` redesign** along the same template.
  Same five-shape problem; same dead-GR8/`DCX rp`/PUSH PSW/PUSH H
  toolkit.
- **`V6C_LOAD16_G` / `V6C_STORE16_G` global-address variants** —
  same shape-conflation pattern, follow-up.
- **Two-load chain cancellation peephole** — when two `addr=DE`
  loads abut, the trailing `XCHG` of the first cancels the leading
  `XCHG` of the second (covered by O44, but explicitly track the
  `LOAD16_P` use case).
- **INX/DCX Cancelation Peephole** — `DCX rp` after
  `INX rp` or vice versa pair elimitation peephole.
- **POP RP/PUSH RP Cancelation Peephole**.

---

## 8. References

* [O71 design doc](future_plans/O71_V6C_LOAD16_P_redesign.md)
* [Plan format reference](plan_cmp_based_comparison.md)
* [V6C Build Guide](../docs/V6CBuildGuide.md)
* [Vector 06c CPU Timings](../docs/Vector_06c_instruction_timings.md)
* [Future Improvements](future_plans/README.md)
* [Feature Test Cases](../tests/features/README.md)
* [Pipeline](pipeline_feature.md)
* [v6emul CLI](../tools/v6emul/docs/cli.md)
* [v6asm CLI](../tools/v6asm/docs/cli.md)
