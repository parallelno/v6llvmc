# Plan: O75 — Flag-Producing Arithmetic SDNodes (X86-Style)

## 1. Problem

### Current behavior

In V6C, only `V6CISD::CMP` and `V6CISD::CMP_ZERO` produce FLAGS, and they
do so via `SDNPOutGlue`. Every flag-setting ALU SDAG node (i8 ADD, SUB,
AND, OR, XOR; INC/DEC) discards its FLAGS at the SDAG level — its
TableGen `Pat<>` only matches `[(set i8:$dst, (add i8:$lhs, i8:$rs))]`.

`LowerBR_CC` for i8 unconditionally emits a fresh `V6CISD::CMP` node:

```cpp
// V6CISelLowering.cpp — current i8 path
SDValue Glue = DAG.getNode(V6CISD::CMP, DL, MVT::Glue, LHS, RHS);
SDValue CCVal = DAG.getConstant(V6CC, DL, MVT::i8);
return DAG.getNode(V6CISD::BRCOND, DL, MVT::Other, Chain, Dest, CCVal, Glue);
```

Even when `LHS` is itself an arithmetic op (`x - 1`, `x & MASK`, …)
that already set the right flags, the SDAG cannot consume them — flags
flow only through glue, and glue is only attached to `CMPr` / `CPI`.

For C source like `while (--n) {…}` the matcher therefore picks the only
SDAG operator that has a CMP node attached: `CPI 0` against an
accumulator-form result. Register allocation then **pins the loop
counter to A** because `CPI`'s operand is in the `Acc` regclass and the
producer (`DCRr`) must funnel through A:

```mir
%8:gr8  = DCRr %1:gr8(tied-def 0), implicit-def dead $flags
%19:acc = COPY %8:gr8                 ; Acc-class operand of CPI
CPI %19:acc, 0, implicit-def $flags
V6C_BRCOND %bb.2, COND_NZ, implicit $flags
```

After regalloc that becomes:

```asm
MOV  A, C        ;  8cc   (forced by Acc-class operand of CPI)
DCR  A           ;  4cc
MOV  C, A        ;  8cc   (write back; A is still pinned)
CPI  0           ;  7cc   (redundant — DCR A already set Z)
JNZ  loop        ; 12cc
; Total: 39cc, 7B
```

vs. the hand-written ideal:

```asm
DCR  C           ;  4cc
JNZ  loop        ; 12cc
; Total: 16cc, 2B
```

### Desired behavior

When the SDAG produces a value whose only or only-flag-relevant use is
a comparison-against-zero, the matcher should pick the value's
flag-producing ALU op directly (`DCR C`, `ANI #MASK`, `XRA r`, …) and
the BRCOND should consume **those** flags — without ever emitting
`CPI 0` and without forcing the value through A.

```asm
; After O75 — counter stays in C
DCR  C           ;  4cc
JNZ  loop        ; 12cc

; After O75 — mask test stays out of A (mask in r)
ANA  r           ;  4cc
JZ   .lab        ; 12cc
```

### Root cause

Two coupled root causes:

1. **FLAGS travel only via `MVT::Glue`** in the V6C SDAG. Glue is a
   non-SSA edge: a node with `SDNPOutGlue` cannot have its value safely
   replaced (`ReplaceAllUsesOfValueWith`) when it has multiple uses,
   because the glue chain participates in the replacement and the
   SelectionDAG infrastructure recurses into a pathological state. The
   prior O75 attempt (Phase 1, single-use only) crashed deterministically
   with `LLVM ERROR: SmallVector unable to grow. Requested capacity
   (4294967296)` whenever multi-use RAUW was attempted on a glue-bearing
   node — see repo memory.

2. **Only `V6CISD::CMP` exposes a flag SDAG output.** Every other
   flag-setting ALU node (`add i8`, `sub i8`, `and i8`, `or i8`, `xor i8`,
   plus INX/DEC immediates) is matched from a plain `[(set i8:$dst, …)]`
   pattern that throws the FLAGS away at the SDAG level. There is
   nothing for BRCOND to consume.

### How X86 solves the same problem

X86's solution (X86InstrFragments.td + X86ISelLowering.cpp::EmitTest)
is the canonical reference:

* **FLAGS is an SSA value of MVT::i32**, not glue. `SDTBinaryArithWithFlags`
  declares 2 outputs `(SDTCisInt<0>, SDTCisVT<1, i32>)`. The "i32" is
  bound to the physical `EFLAGS` register at TableGen pattern level.
* `X86ISD::ADD/SUB/AND/OR/XOR` are flag-producing variants of the plain
  ISD ops. They return `(value, flags)` — both real SSA values, no glue.
* `X86brcond` takes EFLAGS as its third operand of type i32:
  `[(X86brcond bb:$dst, timm:$cond, EFLAGS)]`. ISel auto-inserts the
  `CopyToReg` / implicit-use plumbing.
* `EmitTest()` (called during `LowerSETCC`/`LowerBRCOND`) decides if it
  is profitable to convert a plain ISD arith to its flag form
  (`isProfitableToUseFlagOp`) and, if so, builds the new node, RAUWs
  the value (result 0), and returns the FLAGS (result 1) to feed BRCOND.
  RAUW is safe because **the new node has no glue output**.

The user's hint at the top of `O75_flag_producing_arith_sdnodes.md`
("X86-style: `setOperationAction(ISD::ADD/SUB/AND/OR/XOR, MVT::i8,
Custom)` + always-lower to `V6CISD::*F`") is the right architecture.
This plan ports that architecture to V6C.

---

## 2. Strategy

### Approach: SSA-typed FLAGS + flag-producing arith nodes

Two structural changes, in order:

**Phase A — FLAGS as an SSA-i8 value (replaces glue).**
* `V6CISD::CMP` and `V6CISD::CMP_ZERO` are redefined to return a single
  i8 result (FLAGS), not glue.
* `V6CISD::BRCOND` and `V6CISD::SELECT_CC` are redefined to take FLAGS
  as a regular i8 operand (last operand), not glue.
* TableGen patterns reference the physical `FLAGS` register: e.g.
  `[(set FLAGS, (V6Ccmp i8:$lhs, i8:$rs))]` for `CMPr`, and
  `[(V6Cbrcond bb:$dst, (i8 imm:$cc), FLAGS)]` for `BRCOND`.
* This phase is **regression-only** — the same code is generated, but
  the wire format for FLAGS becomes SSA-typed. It unblocks safe RAUW.

**Phase B — Flag-producing arith nodes (`V6CISD::*F`).**
* New SDNodes: `ADDF`, `SUBF`, `ANDF`, `ORF`, `XORF` (register form);
  `ADDF_IMM`, `SUBF_IMM`, `ANDF_IMM`, `ORF_IMM`, `XORF_IMM` (immediate);
  `INCF`, `DECF` (constant ±1, maps to `INR`/`DCR`). Each returns
  `(i8 value, i8 flags)`.
* TableGen `Pat<>`s for each *F node target the same machine instruction
  that the plain-ISD pattern targets, but with both outputs:
  `[(set GR8:$dst, FLAGS, (V6CADDF GR8:$lhs, GR8:$rs))]`.
* `setOperationAction(ISD::ADD/SUB/AND/OR/XOR, MVT::i8, Custom)`. The
  custom-lowering hook always rewrites these into the corresponding
  *F node, choosing register vs immediate vs INC/DEC variant. The flags
  result is initially unused (dead SSA value) — but the rewrite is
  safe because we are *creating* the new node, not RAUW-ing.
* `LowerBR_CC` / `LowerSELECT_CC`, when comparing an i8 value to zero
  with EQ/NE, look at LHS:
  * If LHS is a `V6CISD::*F` node, use `LHS.getValue(1)` (FLAGS) as the
    BRCOND/SELECT_CC operand directly. **No CMP emitted.**
  * Otherwise, fall back to the existing path (emit `V6CISD::CMP_ZERO`
    or `V6CISD::CMP rhs=0`).

### Why this works (and why the prior attempt failed)

* **RAUW safety**: there is no glue on the *F nodes. `LowerOperation`
  builds the new node, returns its result-0 SDValue. SelectionDAG's
  built-in legalization replaces the original ISD op with our new
  SDValue — a single, clean RAUW on a normal SSA value. This is the
  exact mechanism X86 has used for ~15 years without crashes.
* **No "always rewrite at custom-lower time + then maybe RAUW the
  flags" dance.** Because every i8 ADD/SUB/AND/OR/XOR becomes a *F
  node from the start, the consumer (BR_CC) just inspects LHS and
  picks the FLAGS SDValue. No DAG mutation is needed at consumer time.
* **No new pass.** Everything happens in custom lowering / TableGen.

### What this plan explicitly does NOT do

* Does not touch i16 paths. i16 BR_CC continues through `V6C_BR_CC16`
  / `V6C_BR_CC16_IMM` (already non-glue at the pseudo level) and
  through `V6CISD::CMP_ZERO` for i16 zero tests. Phase A's CMP_ZERO
  rewrite still applies (i16 CMP_ZERO returns SSA-i8 FLAGS) but no
  new i16 *F nodes are introduced.
* Does not touch ADC/SBB. ADC/SBB *use* FLAGS (CY) as well as define
  them — the SDTypeProfile is "FlagsInOut", an additional complication
  the user's plan defers (see "Future Improvements" in the plan body).
* Does not touch O17 (RedundantFlagElim) or O18 (foldCounterBranch).
  They remain as backstops for any shape this plan does not reach
  (e.g. inline-asm-produced sequences).

### Summary of changes

| What | Where | Phase |
|------|-------|-------|
| FLAGS as i8 SSA in CMP/BRCOND/SELECT_CC SDNodes | `V6CISelLowering.h`, `V6CInstrInfo.td` | A |
| `LowerBR_CC` / `LowerSELECT_CC` — pass FLAGS as operand | `V6CISelLowering.cpp` | A |
| TableGen patterns for `CMPr`/`CPI`/`BRCOND` use `FLAGS` reg | `V6CInstrInfo.td` | A |
| Add 12 `V6CISD::*F` enum + name-printer entries | `V6CISelLowering.h`/`.cpp` | B |
| Add SDTypeProfiles + SDNodes + Pat<>s for *F | `V6CInstrInfo.td` | B |
| `setOperationAction(Custom)` on i8 ADD/SUB/AND/OR/XOR | `V6CISelLowering.cpp` ctor | B |
| `LowerArithF` helper + LowerOperation dispatch | `V6CISelLowering.cpp` | B |
| `LowerBR_CC`/`LowerSELECT_CC` — short-circuit when LHS is *F | `V6CISelLowering.cpp` | B |

---

## 3. Implementation Steps

### Step 3.1 — Phase A: Define FLAGS-as-SSA-i8 SDNode profiles [ ]

**File**: `llvm/lib/Target/V6C/V6CInstrInfo.td`

Replace the glue-based definitions. New shape (paralleling X86):

```tablegen
// FLAGS is a single i8-typed SSA value bound to the FLAGS physreg in patterns.

// V6Ccmp:        (i8 flags) = cmp(i8 lhs, i8 rhs)
def SDT_V6CCmp     : SDTypeProfile<1, 2, [SDTCisVT<0, i8>,
                                          SDTCisSameAs<1, 2>,
                                          SDTCisVT<1, i8>]>;
def V6Ccmp     : SDNode<"V6CISD::CMP",      SDT_V6CCmp, []>;

// V6Ccmpzero:    (i8 flags) = cmpzero(i16 val)
def SDT_V6CCmpZero : SDTypeProfile<1, 1, [SDTCisVT<0, i8>, SDTCisVT<1, i16>]>;
def V6Ccmpzero : SDNode<"V6CISD::CMP_ZERO", SDT_V6CCmpZero, []>;

// V6Cbrcond:     brcond(chain, dst, cc, i8 flags)
def SDT_V6CBrCond  : SDTypeProfile<0, 3, [SDTCisVT<0, OtherVT>,
                                          SDTCisVT<1, i8>,    // CC immediate
                                          SDTCisVT<2, i8>]>;  // FLAGS
def V6Cbrcond  : SDNode<"V6CISD::BRCOND",   SDT_V6CBrCond, [SDNPHasChain]>;

// V6Cselectcc:   (T) = selectcc(T true, T false, cc, i8 flags)
def SDT_V6CSelectCC : SDTypeProfile<1, 4, [SDTCisSameAs<0, 1>,
                                           SDTCisSameAs<0, 2>,
                                           SDTCisVT<3, i8>,    // CC
                                           SDTCisVT<4, i8>]>;  // FLAGS
def V6Cselectcc : SDNode<"V6CISD::SELECT_CC", SDT_V6CSelectCC, []>;
```

> **Design Note**: i8 is the FLAGS-as-SSA marker type. It's only ever
> produced by V6CISD::CMP/CMP_ZERO/*F and only consumed by BRCOND /
> SELECT_CC. No risk of mixing with ordinary i8 values because no
> generic ISD op produces a "FLAGS" SDValue.

> **Implementation Notes**:

### Step 3.2 — Phase A: Update CMP/BRCOND TableGen patterns to use `FLAGS` [ ]

**File**: `llvm/lib/Target/V6C/V6CInstrInfo.td`

Convert `CMPr`/`CMPM`/`CPI` patterns to `[(set FLAGS, (V6Ccmp …))]`,
where `FLAGS` refers to the physical register `def FLAGS` already in
`V6CRegisterInfo.td`. `Defs = [FLAGS]` lets are dropped from the
instructions whose `Pat<>` now sets FLAGS explicitly (TableGen derives
the def from the pattern).

Convert `V6C_BRCOND` pseudo:
```tablegen
// Before
let isBranch=1, isTerminator=1, Uses=[FLAGS] in
def V6C_BRCOND : V6CPseudo<(outs), (ins brtarget:$dst, i8imm:$cc), …,
    [(V6Cbrcond bb:$dst, (i8 imm:$cc))]>;

// After
let isBranch=1, isTerminator=1, Uses=[FLAGS] in
def V6C_BRCOND : V6CPseudo<(outs), (ins brtarget:$dst, i8imm:$cc), …,
    [(V6Cbrcond bb:$dst, (i8 imm:$cc), FLAGS)]>;
```

Same for `V6C_SELECT_CC` (the FLAGS operand is appended).

> **Implementation Notes**:

### Step 3.3 — Phase A: Update LowerBR_CC / LowerSELECT_CC for SSA FLAGS [ ]

**File**: `llvm/lib/Target/V6C/V6CISelLowering.cpp`

Replace:
```cpp
SDValue Glue = DAG.getNode(V6CISD::CMP, DL, MVT::Glue, LHS, RHS);
return DAG.getNode(V6CISD::BRCOND, DL, MVT::Other, Chain, Dest, CCVal, Glue);
```
with:
```cpp
SDValue Flags = DAG.getNode(V6CISD::CMP, DL, MVT::i8, LHS, RHS);
return DAG.getNode(V6CISD::BRCOND, DL, MVT::Other,
                   {Chain, Dest, CCVal, Flags});
```

Same shape for `CMP_ZERO` (i16 zero test):
```cpp
SDValue Flags = DAG.getNode(V6CISD::CMP_ZERO, DL, MVT::i8, LHS);
return DAG.getNode(V6CISD::SELECT_CC, DL, VTs,
                   {TrueVal, FalseVal, CCVal, Flags});
```

> **Design Note**: This is a wire-format change only. Code emitted is
> identical to before Phase A.

> **Implementation Notes**:

### Step 3.4 — Build [ ]

```
cmd /c "call ""C:\Program Files\Microsoft Visual Studio\2022\Community\Common7\Tools\VsDevCmd.bat"" -arch=amd64 >nul 2>&1 && ninja -C llvm-build clang llc 2>&1"
```

> **Implementation Notes**:

### Step 3.5 — Lit: re-run all CodeGen tests after Phase A [ ]

```
python llvm-build\bin\llvm-lit.py -v llvm-project\llvm\test\CodeGen\V6C\
```

Expectation: **0 regressions**. Phase A is structurally equivalent.

> **Implementation Notes**:

### Step 3.6 — Phase B: Add `V6CISD::*F` enum entries + name printer [ ]

**File**: `llvm/lib/Target/V6C/V6CISelLowering.h`

Add to `enum NodeType`:
```cpp
ADDF, SUBF, ANDF, ORF, XORF,
ADDF_IMM, SUBF_IMM, ANDF_IMM, ORF_IMM, XORF_IMM,
INCF, DECF,
```

**File**: `V6CISelLowering.cpp` `getTargetNodeName` — add 12 cases.

> **Implementation Notes**:

### Step 3.7 — Phase B: SDTypeProfiles + SDNodes + Pat<>s for *F [ ]

**File**: `llvm/lib/Target/V6C/V6CInstrInfo.td`

```tablegen
// (i8 dst, i8 flags) = OP_F(i8 lhs, i8 rs)
def SDT_V6CArithF    : SDTypeProfile<2, 2, [SDTCisVT<0, i8>, SDTCisVT<1, i8>,
                                            SDTCisVT<2, i8>, SDTCisVT<3, i8>]>;
// (i8 dst, i8 flags) = OP_F_IMM(i8 lhs, i8imm)
def SDT_V6CArithFImm : SDTypeProfile<2, 2, [SDTCisVT<0, i8>, SDTCisVT<1, i8>,
                                            SDTCisVT<2, i8>, SDTCisVT<3, i8>]>;
// (i8 dst, i8 flags) = INCF/DECF(i8 src)
def SDT_V6CIncDecF   : SDTypeProfile<2, 1, [SDTCisVT<0, i8>, SDTCisVT<1, i8>,
                                            SDTCisVT<2, i8>]>;

def V6Caddf : SDNode<"V6CISD::ADDF", SDT_V6CArithF, [SDNPCommutative]>;
def V6Csubf : SDNode<"V6CISD::SUBF", SDT_V6CArithF, []>;
def V6Candf : SDNode<"V6CISD::ANDF", SDT_V6CArithF, [SDNPCommutative]>;
def V6Corf  : SDNode<"V6CISD::ORF",  SDT_V6CArithF, [SDNPCommutative]>;
def V6Cxorf : SDNode<"V6CISD::XORF", SDT_V6CArithF, [SDNPCommutative]>;

def V6Caddf_imm : SDNode<"V6CISD::ADDF_IMM", SDT_V6CArithFImm, []>;
def V6Csubf_imm : SDNode<"V6CISD::SUBF_IMM", SDT_V6CArithFImm, []>;
def V6Candf_imm : SDNode<"V6CISD::ANDF_IMM", SDT_V6CArithFImm, []>;
def V6Corf_imm  : SDNode<"V6CISD::ORF_IMM",  SDT_V6CArithFImm, []>;
def V6Cxorf_imm : SDNode<"V6CISD::XORF_IMM", SDT_V6CArithFImm, []>;

def V6Cincf : SDNode<"V6CISD::INCF", SDT_V6CIncDecF, []>;
def V6Cdecf : SDNode<"V6CISD::DECF", SDT_V6CIncDecF, []>;
```

Patterns piggyback on existing instructions (`ADDr`, `ADI`, `INRr`,
etc.) but emit `(set GR8:$dst, FLAGS, ...)`. We add new `Pat<>`s rather
than modify the existing patterns — the existing `[(set i8:$dst,
(add i8:$lhs, i8:$rs))]` patterns become unreachable for i8 because
of `setOperationAction(Custom)` (Step 3.8), and can be removed in a
follow-up cleanup. Keep them initially to minimize blast radius.

```tablegen
// Examples (analogous patterns for SUBF/ANDF/ORF/XORF/etc.):
def : Pat<(V6Caddf i8:$lhs, i8:$rs),
          (ADDr i8:$lhs, i8:$rs)>;          // implicit set FLAGS via Defs
def : Pat<(V6Caddf_imm i8:$lhs, (i8 imm:$imm)),
          (ADI i8:$lhs, imm:$imm)>;
def : Pat<(V6Cincf i8:$src), (INRr i8:$src)>;
def : Pat<(V6Cdecf i8:$src), (DCRr i8:$src)>;
```

> **Design Note**: TableGen accepts patterns with multi-result SDNodes
> matching machine instructions whose `Defs = [FLAGS]` and which have
> a single explicit GR8 output. ISel uses the existing `Defs` list to
> connect the *F node's result-1 (FLAGS) to the instruction's
> implicit-def. No `(set GR8:$dst, FLAGS, ...)` is needed in the Pat<>
> when the instruction already declares `Defs = [FLAGS]`. (Verified by
> X86 patterns for `X86add_flag` → `ADD8rr`.)

> **Implementation Notes**:

### Step 3.8 — Phase B: setOperationAction(Custom) + LowerArithF [ ]

**File**: `V6CISelLowering.cpp` constructor:
```cpp
for (unsigned Op : {ISD::ADD, ISD::SUB, ISD::AND, ISD::OR, ISD::XOR})
  setOperationAction(Op, MVT::i8, Custom);
```

**File**: `V6CISelLowering.cpp` `LowerOperation` dispatch — new arms:
```cpp
case ISD::ADD: case ISD::SUB:
case ISD::AND: case ISD::OR: case ISD::XOR:
  return LowerArithF(Op, DAG);
```

Implementation of `LowerArithF`:
```cpp
SDValue V6CTargetLowering::LowerArithF(SDValue Op, SelectionDAG &DAG) const {
  assert(Op.getValueType() == MVT::i8);
  SDLoc DL(Op);
  SDValue LHS = Op.getOperand(0), RHS = Op.getOperand(1);
  unsigned ISDOpc = Op.getOpcode();

  // INCF / DECF: ADD i8 X, ±1
  if (ISDOpc == ISD::ADD) {
    if (auto *C = dyn_cast<ConstantSDNode>(RHS)) {
      int64_t V = C->getSExtValue();
      if (V == 1)  return DAG.getNode(V6CISD::INCF, DL,
                       DAG.getVTList(MVT::i8, MVT::i8), LHS).getValue(0);
      if (V == -1) return DAG.getNode(V6CISD::DECF, DL,
                       DAG.getVTList(MVT::i8, MVT::i8), LHS).getValue(0);
    }
    if (auto *C = dyn_cast<ConstantSDNode>(LHS)) {
      int64_t V = C->getSExtValue();
      if (V == 1)  return DAG.getNode(V6CISD::INCF, DL,
                       DAG.getVTList(MVT::i8, MVT::i8), RHS).getValue(0);
      if (V == -1) return DAG.getNode(V6CISD::DECF, DL,
                       DAG.getVTList(MVT::i8, MVT::i8), RHS).getValue(0);
    }
  }

  // RHS-immediate variants
  if (auto *C = dyn_cast<ConstantSDNode>(RHS)) {
    SDValue Imm = DAG.getTargetConstant(C->getZExtValue() & 0xFF, DL, MVT::i8);
    unsigned Opc;
    switch (ISDOpc) {
    case ISD::ADD: Opc = V6CISD::ADDF_IMM; break;
    case ISD::SUB: Opc = V6CISD::SUBF_IMM; break;
    case ISD::AND: Opc = V6CISD::ANDF_IMM; break;
    case ISD::OR:  Opc = V6CISD::ORF_IMM;  break;
    case ISD::XOR: Opc = V6CISD::XORF_IMM; break;
    default: llvm_unreachable("unexpected op");
    }
    return DAG.getNode(Opc, DL, DAG.getVTList(MVT::i8, MVT::i8),
                       LHS, Imm).getValue(0);
  }

  // Register form (canonicalize commutatively if LHS is the constant)
  unsigned Opc;
  switch (ISDOpc) {
  case ISD::ADD: Opc = V6CISD::ADDF; break;
  case ISD::SUB: Opc = V6CISD::SUBF; break;
  case ISD::AND: Opc = V6CISD::ANDF; break;
  case ISD::OR:  Opc = V6CISD::ORF;  break;
  case ISD::XOR: Opc = V6CISD::XORF; break;
  default: llvm_unreachable("unexpected op");
  }
  return DAG.getNode(Opc, DL, DAG.getVTList(MVT::i8, MVT::i8),
                     LHS, RHS).getValue(0);
}
```

> **Design Note**: Returning `getValue(0)` discards the FLAGS result on
> the SDValue interface, but the SDNode still has 2 results in its
> internal VTList. Subsequent SDAG users see only result 0 by default;
> a downstream consumer that wants the FLAGS reads `LHS.getValue(1)`
> on the original ADD/SUB/AND/OR/XOR position.

> **Implementation Notes**:

### Step 3.9 — Phase B: short-circuit *F flags in LowerBR_CC [ ]

**File**: `V6CISelLowering.cpp` — i8 path of `LowerBR_CC` and
`LowerSELECT_CC`, when CC is EQ/NE and RHS is `0`:

```cpp
auto isFlagArith = [](unsigned Opc) {
  return Opc >= V6CISD::ADDF && Opc <= V6CISD::DECF; // contiguous range
};

if (LHS.getValueType() == MVT::i8 && isNullConstant(RHS) &&
    (V6CC == V6CCC::COND_Z || V6CC == V6CCC::COND_NZ) &&
    isFlagArith(LHS.getOpcode())) {
  SDValue Flags = LHS.getValue(1);
  SDValue CCVal = DAG.getConstant(V6CC, DL, MVT::i8);
  return DAG.getNode(V6CISD::BRCOND, DL, MVT::Other,
                     {Chain, Dest, CCVal, Flags});
}
```

Same shape for `LowerSELECT_CC`.

> **Design Note**: `isFlagArith` checks the opcode is one of the 12
> *F nodes; it intentionally does not check `LHS.hasOneUse()`. Multiple
> uses are fine because the *F node already has both value and flags
> available — the flag SSA edge is independent of the value edge. This
> is the entire point of the X86-style architecture and the reason the
> previous glue-based attempt failed.

> **Implementation Notes**:

### Step 3.10 — Build [ ]
> **Implementation Notes**:

### Step 3.11 — Lit test: `o75-flag-arith-fold.ll` [ ]

New lit test under `llvm-project/llvm/test/CodeGen/V6C/`:

* `dec_loop`: `while (--c)` — expect `DCR C; JNZ` only, no `MOV A,C` /
  `MOV C,A` / `CPI 0`.
* `mask_test`: `(x & 0x0F) == 0` — expect `MOV A,r; ANI 0x0F; JZ`,
  no `CPI 0`.
* `xor_test`: `(x ^ y) != 0` — expect `XRA r; JNZ`, no CPI.
* `sub_test`: `(x - 5) != 0` — expect `SUI 5; JNZ`, no CPI.
* `multi_use`: counter that is both decremented and used afterwards —
  must still fold the BRCOND, must still produce a correct value.
* `disabled`: a flag like `-v6c-disable-flag-arith-fold` toggles the
  short-circuit (re-emits CPI 0) — for A/B comparison in regression.

> **Implementation Notes**:

### Step 3.12 — Run regression tests [ ]

```
python tests\run_all.py
```

Expectation: 132/132 PASS or better; checksums for the three
benchmarks (bsort/sieve/fib_crc) unchanged.

> **Implementation Notes**:

### Step 3.13 — Verification assembly steps from `tests\features\README.md` [ ]

* Compile `tests/features/57/v6llvmc.c` to `v6llvmc_new01.asm`.
* Confirm the assembly shows the targeted shape: counter loops use
  `DCR R; JNZ` (no `MOV A,R / DCR A / MOV R,A / CPI 0`); mask tests
  use `ANA R / JZ` (no trailing `CPI 0`).
* If a test still emits `CPI 0` or accumulator round-tripping for a
  shape that should fold, file as Step 3.13.x sub-step, fix, and
  recompile.

> **Implementation Notes**:

### Step 3.14 — Make sure result.txt is created [ ]

Per `tests\features\README.md` — include c8080 reference, v6llvmc old
asm (`tests/features/57/v6llvmc.asm`), v6llvmc new asm
(`tests/features/57/v6llvmc_new01.asm` or last numbered), and the
comparison table.

> **Implementation Notes**:

### Step 3.15 — Sync mirror [ ]

```
powershell -ExecutionPolicy Bypass -File scripts\sync_llvm_mirror.ps1
```

> **Implementation Notes**:

---

## 4. Expected Results

### Example 1: loop counter `while (--n)`

| | Before | After |
|---|---|---|
| Per iteration | 39cc / 7B | 16cc / 2B |

A is **not** pinned; the counter stays in C/B/D/E/H/L. Surrounding
code is therefore freer in its register choices, reducing spill
pressure for the rest of the loop body (this is the *real* win — the
peephole-level CPI removal was already done by O17/O18 but couldn't
unpin A).

### Example 2: mask test `(x & MASK) == 0`

| | Before | After |
|---|---|---|
| Per test | 34cc / 6B | 27cc / 5B |

The leading `MOV A, B` survives because `ANI`/`ANA` are A-only — that's
intrinsic to the ISA, not a redundancy.

### Example 3: counter that is both compared and consumed

```c
while (--n) { sum += n; }
```

* The DECF node has two consumers: the value (used by `sum += n`) and
  the flags (used by the loop branch).
* RA picks any GR8 for `n` (no Acc bias from CPI).
* `DCR n; JNZ; …` becomes the loop trailer; the value is read normally.

### Indirect win: spill behavior in `bsort` inner loop

The current `tests/features/43/v6llvmc_bsort_spillfrwd.asm` artifact
(see TODO.md attached) shows A getting clobbered around a `LDAX BC` in
a loop hot path because the surrounding code expects A to be free.
Removing the Acc-pin from the loop counter / mask test in the same
function frees the spill scheduler from having to dance around A,
which O61's patched-reload path can then exploit.

---

## 5. Risks & Mitigations

| Risk | Mitigation |
|------|------------|
| Phase A breaks all i8 BR_CC lit tests at once | Phase A is committed before Phase B; Step 3.5 must pass clean before proceeding. |
| TableGen rejects a Pat<> that sets a 2-result SDNode but only the value-half is bound | Pattern style verified in X86 (`X86add_flag` → `ADD8rr`); use the same style: omit `FLAGS` from the Pat output, rely on `Defs=[FLAGS]` on the instruction. |
| FLAGS-as-i8 SSA value is observed by a generic ISD pass that mistakes it for an ordinary i8 | i8 FLAGS is only produced and consumed by V6CISD nodes; no generic ISD op produces or consumes a FLAGS SDValue. Risk is theoretical. Mitigation: lit `verify-machineinstrs` runs in `tests/run_all.py`. |
| `LowerArithF` with `setOperationAction(Custom)` causes infinite recursion if the new V6CISD::*F node is itself triggered | LowerOperation is dispatched from ISD opcodes only; V6CISD::*F is a target opcode, not an ISD op, so it skips LowerOperation. Verified pattern in X86. |
| The 12-node enum range used by `isFlagArith` in Step 3.9 is non-contiguous if someone inserts a non-*F node between them | Group the 12 *F enum entries together in `V6CISD::NodeType` and add `static_assert`s that the range is contiguous, or replace the range check with an explicit switch. |
| ADC/SBB inadvertently get matched to `V6Caddf` because `add+carry` lowers to the same SDAG shape | ADC/SBB are not lowered by this plan; ISD::ADDC/ADDE/SUBC/SUBE remain Expand or are matched by their own code paths. `setOperationAction(Custom)` only triggers for the 5 listed opcodes. |
| Phase A regresses `tests/features/13` (branch threading) or other branch-heavy tests because BRCOND gets a new operand position | Lit tests need updating along with the SDNode profile change; Step 3.5 expects this and the lit edits are part of Step 3.2. |

---

## 6. Relationship to Other Improvements

* **Composes with O17/O18**: those peepholes remain in place as
  defensive backstops for shapes the SDAG-level fold doesn't reach
  (e.g. inline-asm-emitted `CPI 0`).
* **Composes with O27/O38**: i16 zero-test (CMP_ZERO) gets the same
  Phase A wire-format upgrade — the i16 path doesn't add *F nodes but
  does benefit from glue-free FLAGS plumbing.
* **Unblocks future i16 `ADDF16`/`DCXF`/`INXF`**: not in this plan,
  but the architecture extends naturally if an i16 producer wants to
  expose flags.
* **Reduces O61 / O64 pressure**: less Acc-pinning means fewer cases
  where the spill scheduler has to route through A.

---

## 7. Future Enhancements

* **i16 flag-producing nodes** (DCX/INX don't set flags on 8080, but
  DAD does; SUB16/AND16/OR16/XOR16 expansions could expose flags). Out
  of scope here.
* **ADC/SBB flag-in/flag-out nodes** modeled on X86's
  `SDTBinaryArithWithFlagsInOut`. Lets us fuse multi-byte adds with
  carry chains expressed in IR. Out of scope here.
* **Cleanup of legacy `[(set i8:$dst, (add i8:$lhs, i8:$rs))]` patterns**
  in `V6CInstrInfo.td` once Phase B is stable — they become
  unreachable for i8.

---

## 8. References

* [O75 design](design/future_plans/O75_flag_producing_arith_sdnodes.md)
* [V6C Build Guide](docs/V6CBuildGuide.md)
* [Vector 06c CPU Timings](docs/Vector_06c_instruction_timings.md)
* [Future Improvements](design/future_plans/README.md)
* [Plan format reference: cmp_based_comparison](design/plan_cmp_based_comparison.md)
* `llvm-project/llvm/lib/Target/X86/X86InstrFragments.td` —
  `SDTBinaryArithWithFlags`, `X86add_flag`, `X86brcond`.
* `llvm-project/llvm/lib/Target/X86/X86ISelLowering.cpp` —
  `EmitTest` (line 22417), `EmitCmp` (line 22517), `LowerBRCOND` /
  `LowerSETCC`.

---

## Dependencies

* `tools/v6emul` — runtime checksum verification of bsort/sieve/fib_crc
  benchmarks (correctness gate).
* `tools/v6asm` — assembly of any `tests/features/57/*.asm` artifacts
  for byte-by-byte comparison.
