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

### Step 3.1 — Add `findDeadGR8AtMI` helper [ ]

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

> **Implementation Notes**:

### Step 3.2 — Rewrite expander: case 2 (`addr=HL, dst∈{BC,DE}`) [ ]

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

> **Implementation Notes**:

### Step 3.3 — Case 1 (`addr=HL, dst=HL`) [ ]

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

> **Implementation Notes**:

### Step 3.4 — Cases 3a (`addr=DE, dst=BC`) and 3b (`addr=DE, dst=HL`) [ ]

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

> **Implementation Notes**:

### Step 3.5 — Case 4 (`addr=DE, dst=DE`) [ ]

```asm
    XCHG
    MOV  Spare, M
    INX  H
    MOV  H, M
    MOV  L, Spare
    XCHG
    DCX  D            ; only if DE live after the pseudo
```

`Spare` selected as in step 3.3, with `ExcludeReg=V6C::DE` (the
swapped HL doesn't matter — old HL was dead since `dst=DE` and the
trailing XCHG restores). Wrap `PUSH PSW`/`POP PSW` iff
`Spare == 0` and `A` is live.

> **Design Notes**: Fixes bug 3. The `Spare` excludes DE because
> after the leading `XCHG`, DE holds the original HL bytes; if we
> chose D or E as the spare we'd be reading back uninitialized
> values relative to the load. (HL after the leading XCHG holds
> the address; we must not pick H or L either, but ExcludeReg=DE
> automatically covers that since we have already swapped — we
> still need to pass `ExcludeReg = V6C::HL | V6C::DE` worth of
> regs; concretely, exclude both pairs.)

> **Implementation Notes**:

### Step 3.6 — Cases 5 (`addr=BC, dst∈{BC,DE}`) and 6 (`addr=BC, dst=HL`) [ ]

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
    PUSH H            ; only if HL live after the pseudo
    PUSH PSW          ; only if no Spare GR8 and A live
    MOV  H, B
    MOV  L, C
    MOV  Spare, M
    INX  H
    MOV  H, M
    MOV  L, Spare
    POP  PSW          ; matches its PUSH
    POP  H            ; matches its PUSH
```

For case 6, `Spare = findDeadGR8AtMI(...)` excluding HL and BC.
If `Spare == 0`, set `Spare = V6C::A` and emit `PUSH PSW`/`POP PSW`
iff `A` is live.

For case 5, the address material is consumed before the trailing
INX, but HL is still overwritten relative to the caller; PUSH/POP
HL is the only recovery (no `DCX` works because HL was reloaded
from BC, not incremented).

> **Design Notes**: Fixes bugs 4 and 5. Note that `DstReg == V6C::HL`
> in case 6 means the *loaded* HL is the value the caller wants;
> the PUSH H / POP H pair preserves the *original* HL only — it
> does not corrupt the freshly-loaded HL, because the POP precedes
> nothing that reads HL within the expansion. Wait — POP H *does*
> overwrite HL. **Resolution**: in case 6 with HL live, the load
> result must be staged via the spare temp until *after* the POP
> H. Concrete sequence:
>
> ```asm
>     PUSH H            ; preserve original HL
>     MOV  H, B
>     MOV  L, C
>     MOV  TmpLo, M     ; TmpLo = Spare (or A under PUSH PSW)
>     INX  H
>     MOV  TmpHi, M     ; TmpHi: needs another dead GR8 distinct from TmpLo
>     POP  H            ; restore original HL — discards loaded address
>     MOV  H, TmpHi
>     MOV  L, TmpLo
> ```
>
> When HL is *not* live, the simpler form from the design doc
> applies (no PUSH/POP, single `Spare` temp).
>
> Two-spare requirement: case 6 with HL live needs **two** dead
> GR8s. If only one is available, fall back to staging via PUSH:
>
> ```asm
>     PUSH H            ; preserve original HL
>     MOV  H, B
>     MOV  L, C
>     MOV  Spare, M     ; Spare = lo
>     INX  H
>     MOV  D_or_E, M    ; … no — pick a strategy that does not need 2 GR8s
> ```
>
> The cleanest fallback when only one GR8 is dead: push the
> low byte through the stack:
>
> ```asm
>     PUSH H            ; preserve original HL
>     MOV  H, B
>     MOV  L, C
>     MOV  Spare, M     ; Spare = low byte
>     INX  H
>     MOV  H, M         ; H = high byte
>     MOV  L, Spare     ; L = low byte → HL = loaded
>     XTHL              ; swap HL with [SP] → HL = original, [SP] = loaded
>     POP  H            ; HL = loaded; SP restored
> ```
>
> `XTHL` is 4 bytes? No — `XTHL` is 1 byte / 18 cc on 8080. This
> avoids the two-GR8 requirement at the cost of one extra
> instruction. This sub-strategy is tracked here as the "case 6
> HL-live, single-spare path."

> **Implementation Notes**:

### Step 3.7 — Build [ ]

Run from repo root:

```
cmd /c "call ""C:\Program Files\Microsoft Visual Studio\2022\Community\Common7\Tools\VsDevCmd.bat"" -arch=amd64 >nul 2>&1 && ninja -C llvm-build clang llc 2>&1"
```

Fix any compile errors, then proceed.

> **Implementation Notes**:

### Step 3.8 — Lit test: case 2 — `addr=HL, dst=BC/DE`, HL live and dead [ ]

**File**: `llvm-project/llvm/test/CodeGen/V6C/load16p_case2_hl_to_bc_de.ll`

Two functions: one where the HL pointer is reused after the load
(must see `DCX H`), one where HL is dead after the load (no
`DCX H`).

> **Implementation Notes**:

### Step 3.9 — Lit test: case 1 — `addr=HL, dst=HL` with A live and dead [ ]

**File**: `llvm-project/llvm/test/CodeGen/V6C/load16p_case1_hl_to_hl.ll`

Two functions: A live across the load (must see `PUSH PSW`/`POP PSW`
or a dead-GR8 spare); A dead (no save).

> **Implementation Notes**:

### Step 3.10 — Lit test: cases 3a/3b — `addr=DE, dst∈{BC,HL}`, DE live and dead [ ]

**File**: `llvm-project/llvm/test/CodeGen/V6C/load16p_case3_de_to_bc_hl.ll`

> **Implementation Notes**:

### Step 3.11 — Lit test: case 4 — `addr=DE, dst=DE` regression for bug 3 [ ]

**File**: `llvm-project/llvm/test/CodeGen/V6C/load16p_case4_de_to_de.ll`

Reproduce the `DAD B; <load via DE to DE>; DAD D` pattern from
`temp/asm_inline/custom_cc.c` and `CHECK` that the second `DAD`
sees the original sum + the loaded value, not the buggy
`loaded + (ptr + 1)`.

> **Implementation Notes**:

### Step 3.12 — Lit test: cases 5/6 — `addr=BC, dst∈{BC,DE,HL}`, HL live and dead [ ]

**File**: `llvm-project/llvm/test/CodeGen/V6C/load16p_case56_bc_to_any.ll`

Cover the single-spare path for case 6 with `XTHL` if the
fallback is exercised.

> **Implementation Notes**:

### Step 3.13 — Run regression tests [ ]

```
python tests\run_all.py
```

Diagnose and fix any regression. Re-run until clean.

> **Implementation Notes**:

### Step 3.14 — Verification assembly steps from `tests\features\README.md` [ ]

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

> **Implementation Notes**:

### Step 3.15 — Make sure `result.txt` is created (`tests\features\README.md`) [ ]

Document c8080 vs v6llvmc cycles/bytes per function and the
shape-by-shape matrix.

> **Implementation Notes**:

### Step 3.16 — Sync mirror [ ]

```
powershell -ExecutionPolicy Bypass -File scripts\sync_llvm_mirror.ps1
```

> **Implementation Notes**:

### Step 3.17 — Mark O71 complete in `design/future_plans/README.md` [ ]

Add the **DONE** marker on the O71 row, set the implementation
order checkbox.

> **Implementation Notes**:

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
