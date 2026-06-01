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
tests\features\71\result.txt
xor16_cmp_zero:         ; lo-byte XRA + CMP8_ZERO shape 2
    MOV  A, E          ;  8cc, 1B
    XRA  L             ;  4cc, 1B
    MOV  L, A          ;  8cc, 1B
    XRA  A             ;  4cc, 1B  — CMP8_ZERO shape 2
    CMP  L             ;  4cc, 1B
    JZ   .zero         ;  8/12cc, 3B
    XRA  A             ;  4cc, 1B
    RET                ; 12cc, 1B
.zero:
    INR  A             ;  8cc, 1B
    RET                ; 12cc, 1B  — worst 60cc, 11B ✓

Optimization. DO bot emit CMP8_ZERO is the flag Z was set by the previous operation.
=================================
this compiles wrongly when draw_pixel is not inlined.
    // Draw a sin wave across the screen.
    for (int x = 0; x < 256; x++) {
        uint8_t y = 127 + sin8(x);
        draw_pixel(x, y);
    }
================================
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
XOR16/AND18/OR16/CMD16 and others can fuse a emmidiate constant and and produce
the code like this
	;--- V6C_XOR16_IMM ---
	MVI	A, IMM_LO
	XRA	REG_LO
	MOV	REG_LO, A
	MVI A, IMM_HI
	XRA	REG_HI
	MOV	REG_HI, A
    ; takes 40 cc

Benefits: it takes less cpu time and the MOST IMPORTANT it doesn't clobber an
extra reg pair because it doesn't require a spare reg pair!
============================
	;--- V6C_RELOAD16 ---
	LHLD	.LLo61_0+1
	MOV	C, L
	POP	H
	MOV	A, C
	ANI	1
	JNZ	.LBB15_2

can be optimizaed into
	;--- V6C_RELOAD16 ---
	LHLD	.LLo61_0+1
	MOV	A, L
	POP	H
	ANI	1
	JNZ	.LBB15_2
    ; minus 8 cc
