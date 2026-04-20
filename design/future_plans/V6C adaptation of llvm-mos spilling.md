# V6C Adaptation of the llvm-mos Spilling

## Problem

Spilling on V6C takes significant CPU time. Some spilling operations like
V6C_SPILL8 use PUSH & POP even when HL is dead and avaliable.


## Original MOS spilling:

### Static stack path (equivalent to V6C's V6CStaticStackAlloc):

* For GPR (A, X, Y) → emits real MOS::STAbs / MOS::LDAbs directly. No pseudo, no hidden clobbers. These are absolute-address store/load instructions — zero extra registers needed.
* For non-GPR (imaginary registers, bit flags) → creates a virtual register (createVirtualRegister(&MOS::GPRRegClass)), emits a COPY to/from it, then stores/loads the vreg via STAbs/LDAbs. The RA sees the vreg and allocates a GPR for it — fully honest, no hidden clobbers.
* For 16-bit Imag16 → splits into lo/hi bytes, stores each separately via the same loadStoreByteStaticStackSlot mechanism.

The critical insight: On the static stack path, llvm-mos doesn't use pseudos at all for spills. It emits real instructions directly in storeRegToStackSlot/loadRegFromStackSlot. When a temporary register is needed (non-GPR spill), it creates a vreg, not a hidden clobber — so the RA is fully aware.

This is the most radical validation of the "honest Defs" approach you've been discussing. llvm-mos goes even further than honest pseudos — it bypasses pseudos entirely for static stack spills, putting real instructions with real vreg dependencies directly into RA's view.

### Soft stack path (frame pointer based):

Emits MOS::LDStk / MOS::STStk pseudos with frame index, lowered during frame index elimination.

---

## V6C Current vs. llvm-mos Spilling: Side-by-Side

### Current V6C Architecture (Two-Phase)

* Phase 1
RA calls storeRegToStackSlot → emits opaque pseudo (V6C_SPILL8, V6C_SPILL16, etc.) with Defs = [FLAGS] only. RA sees these as cheap, non-clobbering instructions.

* Phase 2
EliminateFrameIndex runs post-RA, expands pseudos into real instructions. This is where the complexity lives: 14+ different expansion paths depending on which register is being spilled, whether HL/DE is dead (O42 optimization), etc. The expansion silently clobbers HL (via PUSH HL/LXI HL/POP HL) or DE, but the RA never knew about it.

### llvm-mos Architecture (Single-Phase, Static Stack)
storeRegToStackSlot emits real instructions directly — STAbs/LDAbs with frame indices. When a non-GPR needs spilling, it creates a vreg for the routing copy, so the RA sees and allocates it. No post-RA pseudo expansion needed for static stack spills at all.

### The Fundamental Difference
llvm-mos can emit vregs in storeRegToStackSlot because MOS uses GlobalISel, where register allocation happens later in a different way, and their storeRegToStackSlot is called during RA when vregs are still valid. The RA sees the vreg, allocates a GPR for it, done.


V6C uses SelectionDAG + RegAllocGreedy (standard LLVM pipeline). In this pipeline, storeRegToStackSlot is called by the RA during allocation. You can't create new vregs inside storeRegToStackSlot because:

The RA is in the middle of processing the live interval map
New vregs would need allocation, which the RA isn't set up to handle re-entrantly
After greedy RA, VirtRegMap doesn't expect new vregs to appear
So the MOS trick of "create a vreg for scratch, let RA handle it" doesn't directly port to V6C's pipeline.


### Cons / Risks
1. Can't directly copy the MOS "vreg in storeRegToStackSlot" trick — V6C's pipeline doesn't support it. Must use split pseudos instead.

2. Pseudo proliferation — goes from 4 pseudos (SPILL8/16, RELOAD8/16) to ~12. Each needs expansion logic, testing, TD definitions.

3. RA eviction cascade correctness — must verify that RegAllocGreedy actually handles Defs on spill instructions correctly and doesn't infinite-loop. LLVM's RA is designed for this (ARM/Thumb2 spills declare clobbers), but V6C's extreme register scarcity (7 GPR8s) makes it an unusual stress test.

??????? Is Con 4 true? what about hldl/shld
4. H/L spilling is still ugly — no clean 2-instruction sequence exists. You need either DE as temp (clobbers DE) or route through A twice. The Defs declaration gets complex.

5. Non-static-stack functions — for functions that don't use V6CStaticStackAlloc, STA/SHLD aren't available (they need absolute addresses). Those functions still need SP-relative spilling via LXI HL + MOV M,r, which is back to clobbering HL.

6. Testing burden — every combination of register × liveness state needs verification under maximal pressure.

**Bottom Line**

The MOS approach validates the direction (honest clobbers, RA-aware spilling) but can't be copied mechanically because of the pipeline difference (GlobalISel vs SelectionDAG).


## Common code to store/restore the regs in I8080 ASM.

* A spilling.
STA ADDR - stores A into memory, no extra clobbers, 16cc
LDA ADDR - restores A from memory, no extra clobbers, 16cc

* HL spilling.
SHLD - stores HL into memory, no extra clobbers, 20cc
LHLD - restores HL from memory, no extra clobbers, 20cc

Other regs can be spilled in multiple ways. The best way depends on the spilling
reg and free regs.
Examples:

* DE spilling. HL is dead. 24cc
XCHG
SHLD ADDR

* DE spilling. HL is live. 28cc
XCHG
SHLD ADDR
XCHG

BC spilling, HL is dead. 36cc
MOV L, C
MOV H, B
SHLD ADDR

BC spilling. HL is live, A is dead. 48cc
MOV A, C
STA ADDR1
MOV A, B
STA ADDR1+1

BC spilling. HL is live, A is live. 64cc
PUSH H
MOV L, C
MOV H, B
SHLD ADDR
POP H

When we make spilling honest, the spilling logic should not worry about preserving
live reg. It should only contain the spilling logic and honestly defines what regs
it needs for a spill. RA must provide required regs for a spill. Another complexity
is the multiple paths to spill DE and BC regs. Each path needs their own set of
extra regs and the CPU sycles. To select the best path, RA needs take the Defs and the CPU cycles into account.
To solve that problem we can define multiiple specialized pseudos for each register
or a reg pair.

#### Example 1: DE spill.
We have two pseudos:
1. V6C_SPILL16_DE1, Defs=[], 28cc
XCHG
SHLD ADDR
XCHG
2. V6C_SPILL16_DE2, Defs=[HL], 24cc
XCHG
SHLD ADDR

When HL is dead, RA can use V6C_SPILL16_DE2 because it uses less CC.
When HL is live, RA has no choice but using V6C_SPILL16_DE1.


#### Example 2: BC Spill.
We have three pseudos:
1. V6C_SPILL16_BC1, Defs=[HL], 36cc
MOV L, C
MOV H, B
SHLD ADDR

2. V6C_SPILL16_BC2, Defs=[A], 48cc
MOV A, C
STA ADDR1
MOV A, B
STA ADDR1+1

When A and HL live, RA uses the cjeapest V6C_SPILL16_BC1
When A live, but HL dead, RA uses V6C_SPILL16_BC2
When A and HL dead, RA uses the cheapest V6C_SPILL16_BC2 and apply eviction
mechanism to find the required reg pair for a spill.


### Notes

LIFO: I can't be used directly for spilling because RA stores/restores regs in non
LIFO order.
PUSH Rp - stores the reg pair into stack, no extra clobbers, 16cc
POP  Rp - restores the reg pair from stack, no extra clobbers, 12cc


### Exmples of a bad code generated by the V6C pseudos expansions:
;--- V6C_LEA_FI ---
	LXI	DE, __v6c_ss.main+4
	MOV	H, D
	MOV	L, E
Why no just:
    LXI	HL, __v6c_ss.main+4


    LXI	HL, 0x140a
;--- V6C_STORE16_P ---
	PUSH	DE
	MOV	A, L
	STAX	DE
	INX	DE
	MOV	A, H
	STAX	DE
	POP	DE
Why not just:
    XCHG
    MOV M, E
    INX H
    MOV M, D
    DCX H
    XCHG

;--- V6C_RELOAD16 ---
	PUSH	HL
	LXI	HL, __v6c_ss.main+15
	MOV	C, M
	INX	HL
	MOV	B, M
	POP	HL

Why not just:
    PUSH	HL
    LHLD __v6c_ss.main+15
    MOV	C, L
    MOV	B, H
    POP HL


Or even better, let RA deside when HL requires preservation. If HL is dead,
we don't need PUSH/POP at all.
