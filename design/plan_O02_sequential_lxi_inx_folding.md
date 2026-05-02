# Plan: O02 — Sequential LXI → INX Folding (Extended)

## 1. Problem

### Current behavior

[V6CLoadStoreOpt.cpp](llvm/lib/Target/V6C/V6CLoadStoreOpt.cpp#L132-L205)
implements `mergeAdjacentAccess`: a rigid 4-instruction window matching
`LXI H,N ; <load|store via M> ; LXI H,N+1 ; <load|store via M>` with both
LXI operands as plain `imm`. It folds the second LXI into `INX H`. It
fails on three common shapes:

1. **Chains > 2** — only the first pair folds; the third LXI is never
   compared against the running HL value (which is now `imm+1`).
2. **`GlobalAddress` operands** — `isLXI_HL` rejects anything that is not
   `MachineOperand::isImm`, so `LXI H, g+2` is opaque.
3. **HL-preserving instructions in the gap** — `LDA`, `STA`, `MVI A`,
   immediate ALU, IN/OUT, `MOV` between non-H/L registers, and `INR`/`DCR`
   on non-H/L registers do not touch HL but break the strict access
   pattern. A single `LDA g+1` between an `LXI H,g` and the next
   `LXI H,g+2` blocks the fold.

Real example from `tests/features/50/v6llvmc_old.asm`:

```asm
sum4_global:
    LXI  H, g_s
    LDA  g_s+1            ; HL preserved here
    ADD  M
    LXI  H, g_s+2         ; MISSED — should be INX H
    ADD  M
    LXI  H, g_s+3         ; MISSED — should be INX H
    ADD  M
    RET
```

### Desired behavior

```asm
sum4_global:
    LXI  H, g_s
    LDA  g_s+1
    ADD  M
    INX  H                ; was LXI H, g_s+2  (saves 4cc + 2B)
    ADD  M
    INX  H                ; was LXI H, g_s+3  (saves 4cc + 2B)
    ADD  M
    RET
```

Per Vector-06c timings (`docs/V6CInstructionTimings.md`): LXI = 12cc/3B,
INX = 8cc/1B → saving **4cc + 2B per replaced LXI**.

### Root cause

Existing `mergeAdjacentAccess` is structural pattern-matching (4
adjacent opcodes), not state-tracking. It cannot reason about
"the value HL holds right now" across permitted gaps or chained INXs.

---

## 2. Strategy

### Approach: per-MBB HL-state tracker

Replace `mergeAdjacentAccess` with a forward scan that maintains a
small abstract HL value for each basic block:

```
HLState = Unknown
       | Imm(int64)
       | GA(GlobalValue*, int64 offset)
       | ES(const char* sym, int64 offset)   // ExternalSymbol
       | BA(BlockAddress*, int64 offset)
```

Update rules per instruction:
- `LXI H, X` — if `HLState` matches `X` exactly: drop the LXI.
  Otherwise, if `HLState` matches `X ± Δ` with `1 ≤ |Δ| ≤ MaxDelta(MF)`:
  replace LXI with `|Δ|` × `INX H` (or `DCX H`). Else: set `HLState = X`.
- `INX H` — `HLState.bump(+1)` (saturating: drop to Unknown on overflow).
- `DCX H` — `HLState.bump(-1)`.
- Any instruction defining `H`, `L`, or `HL` (explicit or implicit) →
  `HLState = Unknown`.
- Other instructions → no change.

`MaxDelta`:
- `-Os`/`-Oz`: 3 (size break-even at Δ=3, strict win at Δ≤2).
- `-O2`/`-O3`: 1 (strict speed win only — Δ=1 is 8cc < 12cc).
- `-O1` (Balanced): 2 (mixed; allow Δ=2 = 16cc/2B vs 12cc/3B — speed
  loses 4cc, size wins 1B; treat as net-neutral, allow).

The cost-driven threshold uses the existing `getV6COptMode` helper
(see [V6CInstrCost.h](llvm/lib/Target/V6C/V6CInstrCost.h)).

### Why this works

- **Local to each MBB.** Cross-block tracking would require dataflow;
  it is not needed because the existing `mergeAdjacentAccess` is also
  intra-block. Any unrecognized HL clobber resets the state — fail-safe.
- **Operand identity comparison is cheap.** Two `LXI H, X` operands
  are "consecutive" iff they share the same operand kind (Imm /
  Global / ExternalSymbol / BlockAddress), the same symbol identity
  (`getGlobal()`/`getSymbolName()`), and offsets differ by `Δ`.
- **Reuses existing dual cost model.** No new cost data needed.
- **Subsumes `eliminateDeadLXI`** for the common case (Δ = 0 → drop).

### Summary of changes

| File | Change |
|------|--------|
| `llvm-project/llvm/lib/Target/V6C/V6CLoadStoreOpt.cpp` | Rewrite `mergeAdjacentAccess` as a state-tracking forward scan; extend `isLXI_HL` to accept Imm/GA/ES/BA; widen the matching to handle GlobalAddress + offset and ExternalSymbol + offset; reuse `definesHL` for fail-safe reset. |
| `llvm-project/llvm/test/CodeGen/V6C/loadstore-opt-chain.ll` | New lit test: 3-LXI immediate chain, GA chain, gap-with-LDA, XCHG-blocks-fold (negative), Δ=4 cost-gate (negative). |
| `tests/features/50/` | Feature test (already prepared in Phase 1). |
| `design/future_plans/README.md` | Mark O2 as `[x]`. |
| `design/future_plans/O02_sequential_lxi_inx_folding.md` | Mark as IMPLEMENTED at top. |

---

## 3. Implementation Steps

### Step 3.1 — Refactor `isLXI_HL` to a tagged-union HL operand `[x]`

Add a small POD `HLAddr` carrying:
```cpp
struct HLAddr {
  enum Kind { Imm, GA, ES, BA, Unknown } K = Unknown;
  int64_t Offset = 0;
  const GlobalValue *GV = nullptr;
  const char *Sym = nullptr;          // for ES
  const BlockAddress *BAv = nullptr;  // for BA
  bool sameSymbol(const HLAddr &O) const;
  bool tryDelta(const HLAddr &O, int64_t &Delta) const; // O − this
  static HLAddr fromLXI(const MachineInstr &MI);        // returns Unknown on fail
  void bump(int64_t D);
  bool isKnown() const { return K != Unknown; }
};
```
Move `isLXI_HL` callers to `HLAddr::fromLXI`. `bump` only valid when
known; sets Unknown on int64 overflow guard.

> **Design Notes**: `MachineOperand::isGlobal()` returns the GA wrapper; use
> `getGlobal()` and `getOffset()` for identity. `isSymbol()` returns
> ExternalSymbol; use `getSymbolName()` (pointer compare safe — symbol
> names in MC are interned). `isBlockAddress()` similarly.

> **Implementation Notes**:

### Step 3.2 — Replace `mergeAdjacentAccess` with state tracker `[x]`

```cpp
bool V6CLoadStoreOpt::foldHLChain(MachineBasicBlock &MBB) {
  HLAddr State;             // Unknown initially
  unsigned MaxDelta = getMaxDelta(*MBB.getParent());
  bool Changed = false;
  for (auto I = MBB.begin(); I != MBB.end(); ) {
    MachineInstr &MI = *I++;
    if (MI.getOpcode() == V6C::LXI && MI.getOperand(0).getReg() == V6C::HL) {
      HLAddr New = HLAddr::fromLXI(MI);
      int64_t D;
      if (State.isKnown() && New.isKnown() && State.tryDelta(New, D)) {
        if (D == 0) { /* drop LXI */ }
        else if ((uint64_t)std::abs(D) <= MaxDelta) {
          /* replace with |D| × INX/DCX H */
        } else { State = New; continue; }
        // erase MI (and emit INX/DCX before its position)
        State = New; Changed = true;
        continue;
      }
      State = New;
      continue;
    }
    if (MI.getOpcode() == V6C::INX && MI.getOperand(0).getReg() == V6C::HL) {
      if (State.isKnown()) State.bump(+1);
      continue;
    }
    if (MI.getOpcode() == V6C::DCX && MI.getOperand(0).getReg() == V6C::HL) {
      if (State.isKnown()) State.bump(-1);
      continue;
    }
    if (definesHL(MI)) { State = HLAddr(); }
  }
  return Changed;
}
```

`getMaxDelta(MF)` switches on `getV6COptMode(MF)` (3 for Size, 2 for
Balanced, 1 for Speed).

> **Design Notes**: `definesHL` already covers explicit + implicit defs
> and H/L sub-register defs. Calls (which clobber HL via libcalls) hit
> this path through their RegMask operand — but `definesHL` only inspects
> def operands. Add a RegMask check: `for (MO : MI.operands()) if
> (MO.isRegMask() && MO.clobbersPhysReg(V6C::HL)) return true;`. Same for
> H/L. This catches cross-call HL invalidation.

> **Implementation Notes**:

### Step 3.3 — Build `[x]`

```
cmd /c "call ""C:\Program Files\Microsoft Visual Studio\2022\Community\Common7\Tools\VsDevCmd.bat"" -arch=amd64 >nul 2>&1 && ninja -C llvm-build clang llc 2>&1"
```

> **Implementation Notes**:

### Step 3.4 — Lit test `loadstore-opt-chain.ll` `[x]`

Cases (under `-O2` unless noted):
- **Imm chain**: 3 sequential `LXI H, imm` accesses → 1 LXI + 2 INX.
- **GA chain**: 3 sequential `LXI H, @g+N` → 1 LXI + 2 INX.
- **LDA gap**: `LXI H,g; LDA g+1; ADD M; LXI H,g+2; ADD M` → 1 LXI +
  1 INX (between the two ADD M, not the LDA).
- **XCHG blocks**: `LXI H,g; MOV M,A; XCHG; LXI H,g+1; ...` → 2 LXIs
  preserved.
- **Δ=4 not folded at -O2**: 5-LXI chain → only adjacent Δ=1 folds.
- **Δ=3 folded at -Os**: same input compiled at `-Os` → 1 LXI + 3 INX.

> **Design Notes**: Use `RUN: llc -mtriple=i8080-unknown-v6c -O2 …
> | FileCheck %s --check-prefix=O2`, second `RUN:` for `-Os` /
> `--check-prefix=OS`.

> **Implementation Notes**:

### Step 3.5 — Run regression tests `[x]`

```
python tests\run_all.py
```

Expected: 16/16 golden + full lit suite + 3/3 benchmarks pass with no
checksum changes (the optimization is purely cycle/byte-shrinking on
HL-addressed sequences).

> **Implementation Notes**:

### Step 3.6 — Verification assembly steps from `tests\features\README.md` `[x]`

Compile `tests/features/50/v6llvmc.c` to `v6llvmc_new01.asm`. Confirm:
- `sum4_global`: 3 LXI → 1 LXI + 2 INX H (saves 8cc + 4B).
- `main`: similar pattern on `g_s` and on `g_b/g_c/g_d` after `STA`
  gaps.
- `write4_globals`: STA chain — already optimal (no LXI to fold).

Iterate `v6llvmc_new02.asm`, `_new03.asm`, … if expected savings absent.

> **Implementation Notes**:

### Step 3.7 — Make sure `result.txt` is created `[x]`

Per `tests/features/README.md`: include C source, c8080 main+deps asm,
c8080 stats, v6llvmc final asm, v6llvmc stats.

> **Implementation Notes**:

### Step 3.8 — Sync mirror `[x]`

```
powershell -ExecutionPolicy Bypass -File scripts\sync_llvm_mirror.ps1
```

> **Implementation Notes**:

---

## 4. Expected Results

### Example 1 — `sum4_global` (struct field sum)

**Before** (4 instr 16cc + 3 LXI 36cc + ADD M ×3 24cc + LDA 16cc + RET 12cc = ~104cc / ~14B):
```asm
LXI H, g_s              ; 12cc / 3B
LDA g_s+1               ; 16cc / 3B
ADD M                   ;  8cc / 1B
LXI H, g_s+2            ; 12cc / 3B
ADD M                   ;  8cc / 1B
LXI H, g_s+3            ; 12cc / 3B
ADD M                   ;  8cc / 1B
RET                     ; 12cc / 1B   total: 88cc / 16B
```

**After**:
```asm
LXI H, g_s              ; 12cc / 3B
LDA g_s+1               ; 16cc / 3B
ADD M                   ;  8cc / 1B
INX H                   ;  8cc / 1B   was 12cc / 3B  (-4cc -2B)
ADD M                   ;  8cc / 1B
INX H                   ;  8cc / 1B   was 12cc / 3B  (-4cc -2B)
ADD M                   ;  8cc / 1B
RET                     ; 12cc / 1B   total: 80cc / 12B
```
Savings: **8cc + 4B** in a 12-byte function.

### Example 2 — `main` chain on `g_s` (same shape)

Saves another **8cc + 4B**.

### Example 3 — Aggregate

`tests/features/50` total expected savings: **~16cc + 8B** across the
three call sites of `g_s` field reads (`sum4_global` once, `main` once)
plus any chains the unrolled `write4_globals` exposes after the `STA`
gap test. Goldens/benchmarks unchanged in checksum, slight cycle
reduction in HL-heavy code.

---

## 5. Risks & Mitigations

| Risk | Mitigation |
|------|------------|
| State not invalidated by call clobbers (HL via RegMask) | Add explicit `clobbersPhysReg` RegMask check in `definesHL` (Step 3.2 design notes). |
| Misidentifying GA equality across different relocations | Compare `getGlobal()` pointer identity AND `getTargetFlags()` (catch `MO_LO8`/`MO_HI8` mismatches). |
| Replacing LXI inside an instruction bundle | Bundles aren't used in V6C; assert `!MI.isBundled()` for safety. |
| Cost gate accidentally regressing `-O2` | Default Speed mode allows only Δ=1 (strict win). |
| Reset on `INR H`/`INR L` etc. via implicit def | Already handled — `definesHL` walks all operands incl. implicit. |
| Plan-deferred Option B (`Defs=[HL]` removal) | Out of scope; tracked as O20 separately. |

---

## 6. Relationship to Other Improvements

- **Supersedes `eliminateDeadLXI`** for the dropped-redundant-LXI case
  (Δ=0). Keep `eliminateDeadLXI` as belt-and-braces for cross-MBB
  patterns the state machine doesn't see.
- **Composes with O40 (DAD-based ADD16)**: O40 emits INX chains directly;
  this pass extends them by collapsing a follow-up `LXI H, sym+N`.
- **Independent of O20** (honest store/load defs): O20 attacks the
  same "HL preserved" insight at the pseudo level; this pass operates
  post-expansion and catches what O20 misses (immediate chains).
- **Composes with O49 (direct memory ALU ISel)**: O49 uses `ADD M`
  patterns; O02 shrinks the address-setup that precedes them.

## 7. Future Enhancements

- Track `BC` and `DE` similarly for `LDAX/STAX` chains (rarer; would
  require recognising `LXI B/D, addr; LDAX B/D` → `INX B/D`).
- Cross-block propagation through fall-through edges with single
  predecessor (similar to O29 cross-BB immediate propagation).
- Fold `LXI` followed by `XCHG` into nothing when DE is the desired
  destination for the same constant (compose with O44).

## 8. References

* [V6C Build Guide](docs\V6CBuildGuide.md)
* [V6C Instruction Timings](docs\V6CInstructionTimings.md)
* [Future Improvements](design\future_plans\README.md)
* [O02 design](design\future_plans\O02_sequential_lxi_inx_folding.md)
* [Plan format reference](design\plan_cmp_based_comparison.md)
