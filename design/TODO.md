8.1.7 switch → Jump Tables — ⚠️ Partial / Different
LLVM's SimplifyCFG and SwitchLowering can produce jump tables, bit tests, or balanced binary search trees. However, jump-table lowering on i8080 is awkward (no indexed jump; you'd have to compute target address into HL and do PCHL), and I don't see explicit V6C jump-table tuning in the repo memory. The backend likely falls back to the binary-search/cascade lowering. Not a blocker for correctness, but a potential code-size opportunity.

Status: works correctly via LLVM defaults, but no v6c-specific jump-table tuning has been documented.
=====================================
test this on the real example:
*   - static: per-TU local symbol; no multi-definition link errors.

=============================
explain the paragraph below and also explain naked attribute:
noinline + used: guaranteed out-of-line copy in the .o so an
 *     ISel-emitted `CALL __mulqi3` (etc.) resolves to it via the
 *     assembler's same-TU symbol matching.
==============================
funcs in v6c_arith.h doesn't define clobber regs, return regs. how RA nows what is not clobbered?
=============================
why unused static arith funcs are in the asm?
temp\asm_inline\no_arith.c
temp\asm_inline\no_arith.s
============================
why didn't you use wrapper + body approach for non inline funcs?
============================
why you used volatile after __asm__ ?
============================
From the chat. below your quotes followed by my questions or asks:

>__mulqi3 returns u16, not u8 — libgcc divergence accepted (V6C is freestanding). Documented as a risk in §5.

what risk? explain.


>Drop the wrapper-based Tier B for now (the design mostly serves explicit-call helpers like __v6c_udivmodhi3); ISel-emitted CALLs go straight to the symbol regardless of any C-source wrapper.

the biggest benefit of the wrapper is a possible custom calling convention. learn custom_cc.c test. You dropped very important part of the plan!

> ISel emits __mulhi3, not __v6c_mulhi3
it it emilts __mulhi3, make the wrapper __mulhi3, and the body __v6c_mulhi3. Will it work to use inline wrapper?

>Naked functions don't permit any C statements. Strip them, and fix the /*...*/ comment:

explain this. why do you need naked?

>Now Step 3.5 — re-read the plan to understand the udivmod requirement:
>Implementing standard libgcc-compatible divmod fusion (cleaner than the plan's custom-CC variant — uses LLVM's built-in UDIVREM/SDIVREM libcall path)
>Mid-level rewrites a%b → a - (a/b)*b (one div + mul, fewer total cycles than a fused call). Fusion still works when not rewritten — confirmed via raw IR test. Promote the lit test:

custom CC can reduce reg pressure and saves some cpu cycles. Is your solution better than it? Explain your decision.
==========================
from tests\features\52\result.txt
why does it do the reg shuffling before the call? A*B = B*A, we don't need that shuffling.
v6llvmc_new02.asm — `mul_u8`:
    mul_u8:
            MOV  L, A
            MOV  A, B
            MOV  B, L
            JMP  __mulqi3  ; 8-iteration kernel
===============================
improtant insights that can improve the V6C_LOAD8_FI:
1. The main goal for V6C compiler is to make static stack funcs the most performant, because they have less overhead.
2. In static-stack mode V6C_LOAD8_FI is not very popular. It is used only for arg passing via stack.

2. Register spilling is the biggest problem of the C compiler for i8080.
3. if the V6C_LOAD8_FI is inside a hot code (a loop), it will clobber hl (the most popular and effective regpair), and flags unconditionally increasing the register pressure.
4. we can read the reg without clobbering hl:
hl live, de dead:
new: xchg; lxi h, offset; dad sp; mov reg8, m; xchg; 40cc
old: clobbers hl, which can lead to spilling or less optimal
==================================================
# What I learned from your explanation.
* the selector/scheduler has materialized p+imm_offset1, p+imm_offset2, and p+imm_offset3 first, then performs the loads in reverse order. That means several 16-bit address values are kept live at once, while the 8080 target only has HL/DE/BC.
* each addr+imm_offset operation is done via V6C_DAD. it only works with hl and clobbers oriiginal hl. That triggers a cascade of spills/reloads and
* small addr offsets do not need DAD. they can use inx/dcx if it's in [-3;3]

## Solutions
### option A
Improve V6C_DAD pseudo. Defs=[none], DAD $dst, $lhs, $rp; $dst/$lhs is is GR16, $rhs is GR16All. Pseudo takes case of flags/regs if they alive. ISel: 1. if offset in [-3,+3] emit inx/dcx (no constant reg needed), 2. Otherwise, scan users of the i16 ADD: . it uses xchg wherenever possible.
### option B ???
Option B: At ISel/RA level, emit COPY HL = vreg_in_de as an explicit XCHG pair — i.e. teach copyPhysReg / a custom inserter to convert the 16-bit copy into XCHG when both endpoints are pair-aligned and the other pair is dead.
### Option C ???
In the DAD combine, prefer the operand that is more likely to already live in HL as the LHS. Cheapest heuristic: if N->getOperand(1) is a CopyFromReg of $hl (or any other indicator it's "more HL-like") and N->getOperand(0) is not, swap. A more robust version: check both operands for ISD::CopyFromReg whose source is V6C::HL and put that one first.
``` C
SDValue Lhs = N->getOperand(0), Rhs = N->getOperand(1);
auto isCopyFromHL = [](SDValue V){
  if (V.getOpcode() != ISD::CopyFromReg) return false;
  auto *RN = dyn_cast<RegisterSDNode>(V.getOperand(1));
  return RN && RN->getReg() == V6C::HL;
};
if (!isCopyFromHL(Lhs) && isCopyFromHL(Rhs)) std::swap(Lhs, Rhs);
return DAG.getNode(V6CISD::DAD, DL, MVT::i16, Lhs, Rhs);
```

### Option D ??? — Introduce a "load with base-in-DE + immediate offset" pseudo (cleanest, biggest win)

Add to V6CInstrInfo.td something like:
```
def V6C_LOAD8_PD : V6CPseudo<(outs ACC:$dst), (ins GR16:$base, i16imm:$off), ...>;
```
…that expands to LXI H, off ; DAD D ; MOV A, M (and use it when DAG-combine sees (load (add ptr, imm)) and ptr is not already in HL). Register-allocate $base in a class that excludes HL — say a new GR16NoHL class (add DE, BC). Then the 8 loads share the same base in DE, only HL turns over per load, and there is nothing to spill. The current V6C_LOAD8_P stays for the cases where the pointer truly comes from HL (return values, struct walks, etc.).

### Sink DAD to its load
Add a pre-RA sinking pass that moves V6C_DAD address computations immediately before their single V6C_LOAD8_P / store use.
==================================================
# V6C_DAD — Full Picture
1. Purpose
A pre-RA pseudo for HL-constrained 16-bit add. Models the i8080 physical DAD rp instruction (HL = HL + rp). Selected when an add i16 is used as a memory-address pointer (load/store), so RA must put the live-out base in HL — exactly where the 8080 needs it for MOV r,M / MOV M,r.

2. SDNode + TableGen
V6CInstrInfo.td:133
def V6Cdad : SDNode<"V6CISD::DAD", SDTIntBinOp, [SDNPCommutative]>;

V6CInstrInfo.td:817-828
``` C
// V6C_DAD: HL-constrained 16-bit add → physical DAD rp instruction.
// Does NOT clobber A — only FLAGS (CY).
let Defs = [FLAGS] in
def V6C_DAD : V6CPseudo<(outs GR16Ptr:$dst), (ins GR16Ptr:$lhs, GR16All:$rp),
    "# DAD $dst, $lhs, $rp",
    [(set i16:$dst, (V6Cdad i16:$lhs, i16:$rp))]> {
  let Constraints = "$dst = $lhs";
}
```

$dst/$lhs ∈ GR16Ptr = {HL} only (V6CRegisterInfo.td:99-100).
$rp ∈ GR16All = {HL, DE, BC, SP}.
Tied $dst = $lhs → RA proves the HL constraint at allocation time.
Defs only [FLAGS] (CY): A is preserved — this is the win over V6C_ADD16, which clobbers A via an 8-bit chain.
3. ISel — when it's emitted
V6CISelLowering.cpp:294-312:

First check ±1..±3 constants → rewrite to V6CISD::INX16/DCX16 (no constant reg needed).
Otherwise, scan users of the i16 ADD:
ISD::LOAD at operand 1 (pointer), or
ISD::STORE at operand 2 (pointer)
→ rewrite to V6CISD::DAD.
Non-pointer i16 adds stay as generic ISD::ADD → match V6C_ADD16 (clobbers A).

4. Post-RA expansion
V6CInstrInfo.cpp:705-740:

Assert Dst == HL.
INX/DCX shortcut (only if FLAGS is dead — INX/DCX don't set CY):
findDefiningLXI on the rp operand to recover the constant.
Cost model (dual: bytes+cycles, mode = Speed/Size/Balanced from V6CInstrCost.h) compares N × INX vs LXI + DAD.
If cheaper-or-equal: emit N INX HL/DCX HL, delete the LXI when its dest reg is dead afterward.
Else: emit DAD <rp>.
5. Physical instruction emitted
DAD rp — opcode 00_RP_1001, 10cc/1B, HL ← HL + rp, sets CY only. (Cost table entry V6CCost::DAD.)

6. Related/parallel pseudos
V6C_INX16 / V6C_DCX16 — counts 1..3, no constant register, no FLAGS def. Selected by the same combine for small ±N (O41 plan, plan_pre_ra_inx_dcx_pseudo.md).
V6C_ADD16 — generic i16 add, 8-bit chain through A. Falls back to DAD itself when one operand lands in HL (V6CInstrInfo.cpp #L800-L820).
V6C_ROTL16_1 (O68 phase 2) — uses DAD H + ACI; same HL-constraint precedent (plan_O68_wide_shl_rotate_dad_h.md:157).
7. Costs
HL = HL + rp: 10cc / 1B (DAD), vs. V6C_ADD16 ~24–40cc/6B through A.
HL = HL + small const N (1..3): N × INX = N × (5cc/1B), beats LXI+DAD (10+10=20cc/4B) up to N=3 at Speed, N=4 at Size.
8. Why it shapes pressure (the TODO comment's point)
Because V6C_DAD hard-pins the base/result to HL:

Any pointer + nonzero offset forces HL to be live across the add, blocking HL for other values during that span.
The rp operand can be DE/BC/HL/SP — flexible — but the result must vacate to HL, often costing a copy/XCHG into HL.
In hot loops with two pointers (e.g. dst[i] = src[i]) HL contention is a primary spill driver — this is the rationale behind the O71/O72/O76 LOAD/STORE pseudo redesigns and the "read-without-clobbering-HL via XCHG+LXI+DAD SP" idea you wrote in TODO.
9. References in the codebase
Definition: V6CInstrInfo.td:817
SDNode: V6CInstrInfo.td:133, enum string V6CISelLowering.cpp:240
ISel combine: V6CISelLowering.cpp:294
Expansion: V6CInstrInfo.cpp:705
Cost-model wiring: plan_dual_cost_model.md §3.2
Lit test: cost-model-inx-threshold.ll
Pretty-print marker ;--- V6C_DAD --- emitted by -mv6c-annotate-pseudos (visible in test.s).
=================
>Option A: Drop SDNPCommutative from V6Cdad AND canonicalize in the combine so the operand already in HL (or most likely to land there) is fixed as LHS. Necessary but not sufficient — fails when the "good" operand is in DE/BC at the def point.
is SDNPCommutative dropped already?
==================
Potential big issue. Some helper funcs that check reg pair liveness had broken logic. For example: isHLDead returns true if H or L is dead. that means if it returtns true doesnt mean BOTH regs are live.
Pair-Liveness Audit
For V6C_DAD, the bug was specifically this kind of logic:
``` C
isRegDeadAfter(..., V6C::HL, ...)
```
The old helper could decide “HL is dead” after seeing a later def of only L, even if H was still live and read later. That is wrong if the expansion is about to clobber the whole HL pair.

So the targeted V6C_DAD fix was correct: when deciding whether it is safe not to preserve HL, it checks both halves:
``` C
bool HLDead =
    isRegDeadAfter(..., V6C::H, ...) &&
    isRegDeadAfter(..., V6C::L, ...);
```
That did not cause the broad regression. It is still the right fix and remains landed.

The regression came when I tried to make the helper itself treat any pair register, like HL, DE, or BC, as dead only if both halves were independently dead. That affected many other users of the helper: spills, reloads, frame-index expansion, XCHG peepholes, store/load routing, and so on.

That blanket change changed lots of codegen decisions:

paths that previously skipped PUSH/POP started preserving pairs more often,
routes through XCHG changed,
O61 patched reload/spill shapes changed,
some benchmark code shape shifted enough to expose wrong-code or nontermination.
The key lesson is: “pair deadness should be half-wise” is true when the expansion may clobber the whole pair while preserving unrelated live halves. But it is not automatically safe to change every helper call globally, because each pseudo has its own contract. Some checks are asking “is this full pair value dead?” while others are really asking “can this expansion use this pair as a scratch under this specific restore path?”

So your summary is correct if phrased like this:

The targeted V6C_DAD pair-liveness check was changed to check H and L separately, and that is correct. But applying that behavior globally to every pair-register deadness helper caused broad code-shape regressions, so it was backed out. Other pseudos need to be audited and converted one by one, with proof that the stricter half-wise interpretation matches that pseudo’s preservation contract.
