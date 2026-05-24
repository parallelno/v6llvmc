	.text
	.section	.text.draw_line2,"ax",@progbits
draw_line2:                             ; -- Begin function draw_line2
                                        ; @draw_line2
.Lfunc_begin0:
	;=== void draw_line2(char scr_addr_h, char x0, char y0, char x1, char y1) ===
	;  scr_addr_h = A
	;  x0 = B
	;  y0 = C
	;  x1 = D
	;  y1 = E
; %bb.0:
	;DEBUG_VALUE: draw_line2:scr_addr_h <- $a
	;DEBUG_VALUE: draw_line2:x0 <- $b
	;DEBUG_VALUE: draw_line2:y0 <- $c
	;DEBUG_VALUE: draw_line2:x1 <- $d
	;DEBUG_VALUE: draw_line2:y1 <- $e
	;DEBUG_VALUE: draw_line2:_scr_addr_h <- $a
	;DEBUG_VALUE: draw_line2:_x0 <- $b
	;DEBUG_VALUE: draw_line2:_y0 <- $c
	;DEBUG_VALUE: draw_line2:_x1 <- $d
	;DEBUG_VALUE: draw_line2:_y1 <- $e
	;APP
	STA	.ADDR_H+1
	MOV	A, D
	SUB	B
	JC	.SWAP_POINTS
.SET_DX:
	MOV	D, A
	LXI	H, .ADV_Y
	MOV	A, E
	SUB	C
	JC	.ADV_Y_NEG
.ADV_Y_POS:
	MVI	M, 0x2c
	JMP	.CHECK_SLOP
.ADV_Y_NEG:
	CMA

	INR	A
	MVI	M, 0x2d
.CHECK_SLOP:
	CMP	D
	JNC	.VERTICAL_DRAW
	STA	.DY+1
	CALL	.SET_LOOP_VARS
.LOOP_H:
	MOV	A, M
	ORA	E
	MOV	M, A
	ANA	E
	RRC

	MOV	E, A
	ADC	H
	SUB	E
	MOV	H, A
	MOV	A, C
.DY:
	SUI	0
	JNC	.NO_ADV_Y
	ADD	D
.ADV_Y:
	INR	L
.NO_ADV_Y:
	MOV	C, A
	DCR	B
	JNZ	.LOOP_H
	RET

.SWAP_POINTS:
	CMA

	INR	A
	XCHG

	MOV	D, B
	MOV	E, C
	MOV	B, H
	MOV	C, L
	JMP	.SET_DX
.VERTICAL_DRAW:
	LXI	H, .DX2+1
	MOV	M, D
	MOV	D, A
	LDA	.ADV_Y
	STA	.ADV_Y2
	CALL	.SET_LOOP_VARS
.LOOP_V:
	MOV	A, M
	ORA	E
	MOV	M, A
.ADV_Y2:
	INR	L
	MOV	A, C
.DX2:
	SUI	0
	MOV	C, A
	JNC	.NO_ADV_X2
	ADD	D
	MOV	C, A
	MOV	A, E
	RRC

	MOV	E, A
	ADC	H
	SUB	E
	MOV	H, A
.NO_ADV_X2:
	DCR	B
	JNZ	.LOOP_V
	RET

.SET_LOOP_VARS:
	LXI	H, BIT_MASK
	MVI	A, 7
	ANA	B
	ADD	L
	MOV	L, A
	ADC	H
	SUB	L
	MOV	H, A
	MOV	E, M
	MVI	A, 0xf8
	ANA	B
	RRC

	RRC

	RRC

.ADDR_H:
	ADI	0x80
	MOV	H, A
	MOV	L, C
	MOV	B, D
	INR	B
	XRA	A
	ORA	D
	RAR

	MOV	C, A
	RET


	;NO_APP
	RET
.Lfunc_end0:
                                        ; -- End function
	.section	.text.main,"ax",@progbits
	.globl	main                            ; -- Begin function main
main:                                   ; @main
.Lfunc_begin1:
	;=== void main(void) ===
; %bb.0:
	;APP
	MVI	C, 0x64
	LXI	H, pos
.loop_0:
	MOV	B, M
	INX	H
	MOV	C, M
	INX	H
	MOV	D, M
	INX	H
	MOV	E, M
	INX	H
	PUSH	B
	PUSH	D
	PUSH	H
	MVI	A, 0x80
	CALL	draw_line2
	POP	H
	POP	D
	POP	B
	DCR	C
	JNZ	.loop_0

	;NO_APP
	;APP
	HLT

	;NO_APP
	;DEBUG_VALUE: main:ppp <- -32768
	LDA	0x8000
	;DEBUG_VALUE: main:r1 <- $a
	;--- V6C_SPILL8 ---
	STA	.LLo61_0+1
	;--- V6C_RELOAD8 ---
.LLo61_0:
	MVI	L, 0
	INR	L
	;DEBUG_VALUE: main:r2 <- $l
	;--- V6C_SPILL8 ---
	MOV	B, A
	MOV	A, L
	STA	.LLo61_0+1
	MOV	A, B
	;DEBUG_VALUE: main:r2 <- [$sp+0]
	MOV	H, A
	;DEBUG_VALUE: main:r1 <- $h
	ADI	2
	;DEBUG_VALUE: main:r3 <- $a
	MOV	C, A
	;DEBUG_VALUE: main:r3 <- $c
	MOV	A, H
	ADI	3
	;DEBUG_VALUE: main:r4 <- $a
	MOV	D, A
	;DEBUG_VALUE: main:r4 <- $d
	MOV	A, H
	ADI	4
	;DEBUG_VALUE: main:r5 <- $a
	MOV	E, A
	;DEBUG_VALUE: main:r5 <- $e
	MOV	A, H
	;--- V6C_RELOAD8 ---
	LXI	H, .LLo61_0+1
	MOV	B, M
	;DEBUG_VALUE: main:r2 <- $b
	JMP	draw_line2
.Lfunc_end1:
                                        ; -- End function
	.data
	.globl	__v6c_rand_state                ; @__v6c_rand_state
__v6c_rand_state:
	DW	1                               ; 0x1

	.section	.rodata,"a",@progbits
pos:                                    ; @pos
	.ascii	"\264\213\355\f\007\026.\350\365\202r\021]*e\341u'\325z\336,ry \314\274d\n]O\227\304r]X\371\277&\364S-\235|\246#d\264Xa\350\030\237\372\314\023\001\326.\330\235\226\230\000\236*\3443\2275\365\340\234\365\344(\310z\264,\321\372\262h\365\244\325\037*\331\361\371V\242\310\264\216z\341\017\352x4\363~\361\031\322wT\302[\2374\203\365\352\306t\303\221g\225\3302r+\n\270Uq\013,\\\275\264\265\335j\351r\374\346\317\226\305\303I\246\353\306\024\2235\017\0070\341\210\214\351W\fCj\377\250\037\337\237\374&Y\325.\343\343\330:\"\343\255\277\235\244f\004\270\257<|\342QM\365P\221\261\006\241t\300\227\273\260S\325\032\243I\372\307c\253\230 \356\n\236!~D\020sIa\237\007\357\343<y\b\333\377\005\227\310wk=C\345\366\206\254\276a\345S\211j\266\360\371\324\341`\"\371H\b\006\b\351m\001\033\300(\266\227\024q[n>m\243\224\266\306\376\271\330\361\375pF\237\261\227Y\025\323\245P\214\327\316@\353\262=IXVn\206\273\254\027\311\304\351\274\317\034\336\372\377\200\0302\202NG!b)\275\216<r\316\"\330z\313\353|\336\200_:\331FY3\203\3541\215\023\177\245\345\2450u\203-1j\367\004\361QW\311\320o\f\275\t\315\224uuo\201\326n\205\002K\"\036\322\234\032\f\341h \224/\022\001{"

BIT_MASK:                               ; @BIT_MASK
	.ascii	"\200@ \020\b\004\002\001"

	.local	__v6c_ss.main                   ; @__v6c_ss.main
	.comm	__v6c_ss.main,1,1
	.addrsig
	.addrsig_sym __mulqi3
	.addrsig_sym __v6c_mulqihi3
	.addrsig_sym __mulhi3
	.addrsig_sym __v6c_udivmod16_body
	.addrsig_sym __udivhi3
	.addrsig_sym __umodhi3
	.addrsig_sym __udivmodhi4
	.addrsig_sym __divmodhi4
	.addrsig_sym __v6c_neg_hl_body
	.addrsig_sym __v6c_neg_de_body
	.addrsig_sym __divhi3
	.addrsig_sym __modhi3
	.addrsig_sym __ashlhi3
	.addrsig_sym __lshrhi3
	.addrsig_sym __ashrhi3
	.addrsig_sym pos
	.addrsig_sym BIT_MASK
