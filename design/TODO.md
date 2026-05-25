Investigate if it is possible to teach compiler+linker to operate fraction of address.
like take a hi or lo byte of a address that will be resolved at the linking time.
============================
A special aligment that guarantee aligment INTO block, not at start of the block.
For example the data below all:
static block_align(256) uint8_t arr[10]
static block_align(256) uint8_t arr[10]
static int A = 10;
Research it. perhaps it can be done via lld scripts.
============================
important insights that can improve the V6C_LOAD8_FI:
1. The main goal for V6C compiler is to make static stack funcs the most performant, because they have less overhead.
2. In static-stack mode V6C_LOAD8_FI is not very popular. It is used only for arg passing via stack.

2. Register spilling is the biggest problem of the C compiler for i8080.
3. if the V6C_LOAD8_FI is inside a hot code (a loop), it will clobber hl (the most popular and effective regpair), and flags unconditionally increasing the register pressure.
4. we can read the reg without clobbering hl:
hl live, de dead:
new: xchg; lxi h, offset; dad sp; mov reg8, m; xchg; 40cc
old: clobbers hl, which can lead to spilling or less optimal
================================
optimization peephole.
eleminate push rp, pop rp sequence if:
- it is inside a basic block
- rp is dead after sequence
- no usage of the rp between the push and pop and before the rp death
- the push pop can have other instructions in beetween
evidence:
tests\benchmarks_c\asm\v6llvmc_sieve_O2.s
source:
	DAD	B
	MOV	B, H
	MOV	C, L
	POP	H
	;--- V6C_SPILL16 ---
	PUSH	H
	MOV	L, C
	MOV	H, B
	SHLD	.LLo61_3+1
lines: #147-#155

the invalid sequence:
	POP	H
	;--- V6C_INX16 ---
	INX	H
	INX	H
	;--- V6C_RELOAD16 ---
	PUSH	H
lines #156-#161

a valid sequence with an instruction in beteen
	POP	H
	;--- V6C_INX16 ---
	INX	B
	;--- V6C_SPILL16 ---
	PUSH	H
lines #165 to #169
