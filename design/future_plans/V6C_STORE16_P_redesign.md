# V6C_STORE16_P Design Redesign

## Problem
. V6C_STORE16_P — also overconservative AND has a real bug
Declared Defs = [HL, A]. Per shape:

val	addr	expansion	actually clobbered
HL	HL	MOV A,H; MOV M,L; INX H; MOV M,A	A, HL (HL = orig+1)
HL	DE	[PUSH D]; MOV A,L; STAX D; INX D; MOV A,H; STAX D; [POP D]	A; DE preserved by PUSH/POP only when not dead — otherwise DE = orig+1, but pseudo claims DE preserved
HL	BC	symmetric to DE	A; BC = orig+1 if BC was dead
≠HL	HL	MOV M,lo; INX H; MOV M,hi	HL (= orig+1); A not touched
≠HL	≠HL	MOV H,addrHi; MOV L,addrLo; MOV M,lo; INX H; MOV M,hi	HL clobbered (consistent with Defs); A not touched
Issues:

Overconservative for val≠HL & addr≠HL: declares A clobbered, but A is genuinely preserved.
Overconservative for val≠HL & addr=HL: same — A preserved but declared clobbered.
Underconservative / bug for val=HL, addr=DE (or BC) when DE/BC is dead at the pseudo: the "skip PUSH/POP when dead" optimization leaves DE/BC holding orig_addr + 1 after the pseudo, but Defs does not include DE/BC. That's fine if "dead" really means dead — isRegDeadAtMI checks the kill flag/liveness at this MI, so the value is unused downstream and the lie is benign. However it's a fragile pattern: any later pass that reads liveness after this expansion sees an INX D that doesn't appear in any Defs, with D/E not redefined. As long as expansion is expandPostRAPseudos and no liveness recompute happens that re-reads the original pseudo, it works. Worth reviewing.
val=HL, addr=HL correctly clobbers HL (already in Defs) and A (already in Defs). OK.
The INX rp for rp=DE/BC does not bump HL, so the Defs=[HL] on those shapes is wrong-direction over-conservative (HL is preserved when val=HL, addr∈{DE,BC} until the optional PUSH/POP path — actually HL is genuinely preserved there, so Defs=[HL] is a lie in the over-conservative direction).
So V6C_STORE16_P has the same structural problem: one pseudo, many shapes, single coarse Defs set that is simultaneously too tight (under-declares BC/DE clobber when the dead-optimization fires) and too loose (declares A and HL clobbered in shapes where they're preserved).