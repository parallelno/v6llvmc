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
=================================
this compiles wrongly when draw_pixel is not inlined.
    // Draw a sin wave across the screen.
    for (int x = 0; x < 256; x++) {
        uint8_t y = 127 + sin8(x);
        draw_pixel(x, y);
    }
================================
tests\benchmarks_c\asm\v6llvmc_lfsr16_O2.s
	LXI	B, 0xb400
	;--- V6C_SPILL16 ---
	...
	;--- V6C_RELOAD16 ---
	...
	;--- V6C_XOR16 ---
	MOV	A, L
	XRA	C
	MOV	C, A
	MOV	A, H
	XRA	B
	MOV	B, A
    ; takes 52 cc
Introduce V6C_XOR16_IMM/ (same for AND16/OR16/CMD16) that takes an emmidiate
constant and produces the code like this
	;--- V6C_XOR16_IMM ---
	MVI	A, IMM_LO
	XRA	REG_LO
	MOV	REG_LO, A
	MVI A, IMM_HI
	XRA	REG_HI
	MOV	REG_HI, A
    ; takes 40 cc

Benefits: it takes less cpu time and the MOST IMPORTANT benefit it doesn't
clobber an extra reg pair (BL in the example above) because it doesn't require
a spare reg pair!

Note: AND, OR, XRA are all produce valid results if the arguments are swapped:
A & B == B & A, but CMP doesn't. So you need to carefully design it optimization
case.