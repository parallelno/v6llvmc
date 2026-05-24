Maybe it is possible to teach compiler+linker to operate fraction of address. like take a hi or lo byte of a address that will be resolved at the linking time.
============================
Soft Alignment.
A special aligment that guarantee aligment INTO block, not at start of the block.
For example the data below all :
static soft_align(256) uint8_t arr[10]
static soft_align(256) uint8_t arr[10]
static int A = 10;
Research it. perhaps it can be done via lld scripts.
============================
improtant insights that can improve the V6C_LOAD8_FI:
1. The main goal for V6C compiler is to make static stack funcs the most performant, because they have less overhead.
2. In static-stack mode V6C_LOAD8_FI is not very popular. It is used only for arg passing via stack.

2. Register spilling is the biggest problem of the C compiler for i8080.
3. if the V6C_LOAD8_FI is inside a hot code (a loop), it will clobber hl (the most popular and effective regpair), and flags unconditionally increasing the register pressure.
4. we can read the reg without clobbering hl:
hl live, de dead:
new: xchg; lxi h, offset; dad sp; mov reg8, m; xchg; 40cc
old: clobbers hl, which can lead to spilling or less optimal
=================
>Option A: Drop SDNPCommutative from V6Cdad AND canonicalize in the combine so the operand already in HL (or most likely to land there) is fixed as LHS. Necessary but not sufficient — fails when the "good" operand is in DE/BC at the def point.
is SDNPCommutative dropped from V6Cdad already?
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
