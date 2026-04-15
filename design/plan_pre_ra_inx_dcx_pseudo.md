# Plan: Pre-RA INX/DCX Pseudo for Small-Constant Pointer Arithmetic (O41)

## 1. Problem

### Current behavior

Pointer increment `gep ptr, 1` (or any i16 `add x, 1..3`) lowers through
the standard 16-bit add path:

1. **ISel**: `add i16 ptr, 1` → either `V6CISD::DAD` (pointer context)
   or `V6C_ADD16` (general context) — both require the constant in a
   register pair.
2. **RA**: Constant 1 → allocates a physical register pair (e.g. BC) →
   `LXI BC, 1` materialized in the preheader.
3. **Post-RA peephole**: Detects `LXI BC, 1` + `DAD BC` → converts to
   `INX HL`, but BC was **already reserved by RA**.

The register pair holding the constant is wasted — the peephole removes
the use but RA has already reserved the register.

### Desired behavior

Small-constant (±1..±3) i16 additions emit single-operand pseudos
(`V6C_INX16` / `V6C_DCX16`) at ISel time, so RA never sees a second
register operand and never allocates a register pair for the constant.

### Root cause

The conversion from `LXI + DAD` to `INX` happens post-RA — too late to
recover the wasted register pair. Moving the decision before RA (into
DAG combine) avoids the allocation entirely.

## 2. Strategy

### Approach: ISel-level INX/DCX pseudos via DAG Combine

Add new V6CISD nodes (`INX16`, `DCX16`) and corresponding pseudos
(`V6C_INX16`, `V6C_DCX16`). Each pseudo takes one register pair and an
i8 immediate count (1..3), with a tied constraint `$dst = $src`.

In `PerformDAGCombine`, intercept `ISD::ADD` (and `ISD::SUB`) with a
small constant operand **before** the existing DAD conversion. Emit
`V6CISD::INX16` or `V6CISD::DCX16` instead.

Post-RA expansion trivially emits N copies of physical `INX rp` or
`DCX rp`.

### Why this works

- **Pre-RA**: RA sees only one register operand — no constant pair is
  allocated. This frees BC/DE for other live values.
- **Cost neutral or better**: For N≤3, N×INX (N×8cc, N×1B) ≤ LXI+DAD
  (24cc, 4B). Equal cycles at N=3, strictly fewer bytes always.
- **No flag concern at DAG level**: `ISD::ADD` in the DAG doesn't produce
  flags; converting to INX16 is semantically identical.
- **Existing post-RA INX path preserved**: For constants ≥4, the existing
  `findDefiningLXI` + INX conversion in V6C_DAD/ADD16/SUB16 expansion
  remains as a fallback.

### Summary of changes

| Step | What | Where |
|------|------|-------|
| Add ISD nodes | INX16, DCX16 to V6CISD enum | V6CISelLowering.h |
| Add node names | getTargetNodeName entries | V6CISelLowering.cpp |
| Add SDNode defs | SDT_V6CInxDcx16, V6Cinx16, V6Cdcx16 | V6CInstrInfo.td |
| Add pseudos | V6C_INX16, V6C_DCX16 | V6CInstrInfo.td |
| DAG combine | Intercept ISD::ADD/SUB with ±1..±3 | V6CISelLowering.cpp |
| Post-RA expand | N copies of INX/DCX | V6CInstrInfo.cpp |
| Lit test | pre-ra-inx-dcx.ll | tests/lit/CodeGen/V6C/ |

---

## 3. Implementation Steps

### Step 3.1 — Add V6CISD::INX16 and DCX16 node types [x]

**File**: `llvm-project/llvm/lib/Target/V6C/V6CISelLowering.h`

Add two new entries to the `V6CISD::NodeType` enum, after `DAD`:
```cpp
  INX16,      // 16-bit increment by immediate count (1..3), no flag set.
  DCX16,      // 16-bit decrement by immediate count (1..3), no flag set.
```

**File**: `llvm-project/llvm/lib/Target/V6C/V6CISelLowering.cpp`

Add `getTargetNodeName` entries:
```cpp
  case V6CISD::INX16:    return "V6CISD::INX16";
  case V6CISD::DCX16:    return "V6CISD::DCX16";
```

> **Implementation Notes**: Added INX16, DCX16 after DAD in enum. Added getTargetNodeName entries.

### Step 3.2 — Add TableGen SDNode and pseudo definitions [x]

**File**: `llvm-project/llvm/lib/Target/V6C/V6CInstrInfo.td`

Add SDNode type profile and nodes (near existing V6Cdad definition):
```tablegen
// INX16/DCX16: increment/decrement i16 by immediate i8 count (1..3).
def SDT_V6CInxDcx16 : SDTypeProfile<1, 2, [SDTCisVT<0, i16>,
                                             SDTCisVT<1, i16>,
                                             SDTCisVT<2, i8>]>;
def V6Cinx16 : SDNode<"V6CISD::INX16", SDT_V6CInxDcx16>;
def V6Cdcx16 : SDNode<"V6CISD::DCX16", SDT_V6CInxDcx16>;
```

Add pseudo-instruction definitions (near V6C_DAD):
```tablegen
// V6C_INX16: rp += count (1..3) via N copies of INX rp.
// No register pair needed for the constant — count is an immediate.
// Does NOT clobber A or FLAGS (INX sets no flags).
def V6C_INX16 : V6CPseudo<(outs GR16:$dst), (ins GR16:$src, i8imm:$count),
    "# INX16 $dst, $src, $count",
    [(set i16:$dst, (V6Cinx16 i16:$src, (i8 timm:$count)))]> {
  let Constraints = "$dst = $src";
}

// V6C_DCX16: rp -= count (1..3) via N copies of DCX rp.
def V6C_DCX16 : V6CPseudo<(outs GR16:$dst), (ins GR16:$src, i8imm:$count),
    "# DCX16 $dst, $src, $count",
    [(set i16:$dst, (V6Cdcx16 i16:$src, (i8 timm:$count)))]> {
  let Constraints = "$dst = $src";
}
```

> **Design Note**: No `Defs` — INX/DCX set neither A nor FLAGS. This
> is the key benefit: RA sees minimal clobber pressure from these pseudos.

> **Implementation Notes**: Added SDT_V6CInxDcx16, V6Cinx16/V6Cdcx16 nodes, V6C_INX16/V6C_DCX16 pseudos. No Defs (no A/FLAGS clobber).

### Step 3.3 — DAG Combine: intercept small-constant ADD/SUB [x]

**File**: `llvm-project/llvm/lib/Target/V6C/V6CISelLowering.cpp`

In `PerformDAGCombine`, add small-constant checks **before** the existing
`UsedAsPointer` → DAD conversion in the `ISD::ADD` case. Also add an
`ISD::SUB` case.

```cpp
  case ISD::ADD:
    if (N->getValueType(0) == MVT::i16) {
      SDLoc DL(N);
      // Check for small constant ±1..±3 → INX16/DCX16.
      for (unsigned OpIdx = 0; OpIdx < 2; ++OpIdx) {
        if (auto *C = dyn_cast<ConstantSDNode>(N->getOperand(OpIdx))) {
          int64_t Val = C->getSExtValue();
          if (Val >= 1 && Val <= 3)
            return DAG.getNode(V6CISD::INX16, DL, MVT::i16,
                               N->getOperand(1 - OpIdx),
                               DAG.getConstant(Val, DL, MVT::i8));
          if (Val >= -3 && Val <= -1)
            return DAG.getNode(V6CISD::DCX16, DL, MVT::i16,
                               N->getOperand(1 - OpIdx),
                               DAG.getConstant(-Val, DL, MVT::i8));
        }
      }
      // Existing DAD conversion for pointer adds...
      ...
    }
    break;

  case ISD::SUB:
    if (N->getValueType(0) == MVT::i16) {
      if (auto *C = dyn_cast<ConstantSDNode>(N->getOperand(1))) {
        SDLoc DL(N);
        int64_t Val = C->getSExtValue();
        if (Val >= 1 && Val <= 3)
          return DAG.getNode(V6CISD::DCX16, DL, MVT::i16,
                             N->getOperand(0),
                             DAG.getConstant(Val, DL, MVT::i8));
        if (Val >= -3 && Val <= -1)
          return DAG.getNode(V6CISD::INX16, DL, MVT::i16,
                             N->getOperand(0),
                             DAG.getConstant(-Val, DL, MVT::i8));
      }
    }
    break;
```

> **Design Note**: The constant check comes first so that `add ptr, 1`
> used as a pointer gets INX16 (better than DAD, which would still work
> but needs a register pair). The zero case (`add x, 0`) is excluded —
> the optimizer removes it anyway.

> **Implementation Notes**: **Critical fix**: Must use `DAG.getTargetConstant()` (not `getConstant()`) for the count operand. TableGen patterns use `timm` which matches `ISD::TargetConstant`; using `getConstant()` produces `ISD::Constant` and causes "Cannot select" ISel failures. Both operands of ISD::ADD checked (commutative).

### Step 3.4 — Post-RA expansion: V6C_INX16, V6C_DCX16 [x]

**File**: `llvm-project/llvm/lib/Target/V6C/V6CInstrInfo.cpp`

Add two expansion cases in `expandPostRAPseudo()`:
```cpp
  case V6C::V6C_INX16: {
    Register Rp = MI.getOperand(0).getReg();
    unsigned Count = MI.getOperand(2).getImm();
    for (unsigned I = 0; I < Count; ++I)
      BuildMI(MBB, MI, DL, get(V6C::INX), Rp).addReg(Rp);
    MI.eraseFromParent();
    return true;
  }
  case V6C::V6C_DCX16: {
    Register Rp = MI.getOperand(0).getReg();
    unsigned Count = MI.getOperand(2).getImm();
    for (unsigned I = 0; I < Count; ++I)
      BuildMI(MBB, MI, DL, get(V6C::DCX), Rp).addReg(Rp);
    MI.eraseFromParent();
    return true;
  }
```

> **Implementation Notes**: Added before V6C_DAD case. Emits N copies of INX/DCX with addReg(Rp).

### Step 3.5 — Build [x]

```
cmd /c "call ""C:\Program Files\Microsoft Visual Studio\2022\Community\Common7\Tools\VsDevCmd.bat"" -arch=amd64 >nul 2>&1 && ninja -C llvm-build clang llc 2>&1"
```

> **Implementation Notes**: Build succeeded 40/40 on first try (after initial getConstant bug, fixed in step 3.3).

### Step 3.6 — Lit test: pre-ra-inx-dcx.ll [x]

**File**: `tests/lit/CodeGen/V6C/pre-ra-inx-dcx.ll`

Test cases:
1. `add i16 %x, 1` → INX (general context, not pointer)
2. `add i16 %x, 3` → 3×INX
3. `sub i16 %x, 1` → DCX
4. `sub i16 %x, 2` → 2×DCX
5. `getelementptr i8, ptr %p, 1` (pointer context) → INX
6. `add i16 %x, 4` → NOT INX (falls through to ADD16/DAD)
7. Loop with pointer increment → INX inside loop, no LXI for constant

> **Implementation Notes**: 8 test functions: add1 (INX), add3 (3×INX), sub1 (DCX), sub2 (2×DCX), gep1 (pointer context), add4 (negative — NOT INX, threshold test), add_neg1 (INX via negative constant), fill_loop (loop with pointer). All FileCheck patterns pass.

### Step 3.7 — Run regression tests [x]

```
python tests\run_all.py
```

> **Implementation Notes**: 15/15 golden, 100/100 lit. One test updated: spill-forwarding.ll expected `LDAX BC` but O41 freed BC so RA chose DE → updated to `LDAX DE`. This is a positive sign: O41 successfully reduced register pressure.

### Step 3.8 — Verification assembly steps from `tests\features\README.md` [x]

Compile feature test, analyze assembly for freed register pairs and
eliminated dead LXI instructions.

> **Implementation Notes**: Compiled v6llvmc.c → v6llvmc_new01.asm. Confirmed: dead `LXI BC, 1` removed from fill_array (24B→21B) and copy_loop (26B→23B). Total −6B, −24cc. BC freed for RA.

### Step 3.9 — Make sure result.txt is created. `tests\features\README.md` [x]

> **Implementation Notes**: Created result.txt with full analysis: c8080 vs v6llvmc OLD vs NEW comparison tables, cycle counts, code analysis.

### Step 3.10 — Sync mirror [x]

```
powershell -ExecutionPolicy Bypass -File scripts\sync_llvm_mirror.ps1
```

> **Implementation Notes**: Mirror synced.

### Example 1: fill_array loop (pointer store)

```asm
; Before (O20 + O40, post-RA peephole converts DAD→INX but BC wasted):
fill_array:
    MOV     L, A                ; save start_val
    LXI     DE, array1          ; pointer
    LXI     BC, 1               ; ← dead constant, BC wasted
.loop:
    MOV     A, L
    STAX    DE
    INX     DE                  ; peephole: was DAD BC → INX DE
    INR     L
    ...

; After (O41, no constant register needed):
fill_array:
    MOV     L, A                ; save start_val
    LXI     DE, array1          ; pointer
.loop:                          ; BC is FREE for RA
    MOV     A, L
    STAX    DE
    INX     DE                  ; directly from V6C_INX16 pseudo
    INR     L
    ...
```

**Savings**: Eliminates dead LXI BC, 1 (12cc, 3B). Frees BC for RA.

### Example 2: General i16 add with small constant

```asm
; Before: add i16 %x, 2 → V6C_ADD16 → LXI + 8-bit chain through A
    LXI     DE, 2               ; constant in register pair
    MOV     A, L
    ADD     E
    MOV     L, A
    MOV     A, H
    ADC     D
    MOV     H, A

; After: V6C_INX16 → 2×INX, no A clobber, no register pair for constant
    INX     HL
    INX     HL
```

**Savings**: 36cc→16cc, 8B→2B, no A clobber, no DE/BC used.

---

## 5. Risks & Mitigations

| Risk | Mitigation |
|------|------------|
| INX/DCX don't set flags — downstream code may expect FLAGS from add | At DAG level, ISD::ADD doesn't produce flags; they come from separate CMP nodes. No flag issue. |
| DAG combine fires too eagerly (e.g., constant 0) | Only ±1..±3 matched; zero is excluded (optimizer removes `add x, 0` anyway). |
| Conflict with existing post-RA INX conversion | Post-RA path for ≥4 still works. For ≤3, pre-RA pseudo intercepts first — no conflict. |
| ISel pattern doesn't match DAG combine output | Follow V6C_SRL16 precedent: `DAG.getConstant()` + `timm` pattern. |

---

## 6. Relationship to Other Improvements

- **O20** (done): Freed HL for pointers, exposing the wasted constant
  register pair problem in non-HL pairs.
- **O40** (done): Added the post-RA DAD-based expansion with INX fallback
  for larger constants — this optimization supersedes that path for ≤3.
- **O11** (done): Dual cost model validates the INX vs LXI+DAD threshold.

## 7. Future Enhancements

None planned.

## 8. References

* [V6C Build Guide](docs\V6CBuildGuide.md)
* [Vector 06c CPU Timings](docs\Vector_06c_instruction_timings.md)
* [Future Improvements](design\future_plans\README.md)
* [O41 Design](design\future_plans\O41_pre_ra_inx_dcx_pseudo.md)
* [Cost Model Lit Test](tests\lit\CodeGen\V6C\cost-model-inx-threshold.ll)
