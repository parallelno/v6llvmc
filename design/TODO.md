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