Investigate if it is possible to teach compiler+linker to operate fraction of address.
like take a hi or lo byte of a address that will be resolved at the linking time.
============================
A special aligment that guarantee aligment INTO block, not at start of the block.
For example the data below all:
static block_align(256) uint8_t arr[10]
static block_align(256) uint8_t arr[10]
static int A = 10;
Research it. perhaps it can be done via lld scripts.
================================
possible bug. the svofski line draw program doesnt work when compiled with v6asm.
compare v6asm binary output with what the downloaded line bin from https://svofski.github.io/pretty-8080-assembler/
================================
optimization template:
make an optimization peephole design document and store it to design\future_plans\ folder. add it to design\future_plans\README.md.
...
================================
samples\03_demo\main.s

	;--- V6C_CMP16_IMM ---
	MVI	A, 0xff
	SUB	L
	MVI	A, 0xff
	SBB	H
	JP	.LBB20_3

cheaper is
	;--- V6C_CMP16_IMM ---
	MVI	A, CONST_HI
	cmp reg_hi
	jnz loop
	MVI	A, CONST_LO
	cmp reg_lo
	jnz loop