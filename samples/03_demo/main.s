	.text
	.section	.text.v6c_set_palette,"ax",@progbits
v6c_set_palette:                        ; -- Begin function v6c_set_palette
                                        ; @v6c_set_palette
.Lfunc_begin0:
	;=== void v6c_set_palette(void) ===
; %bb.0:
	LXI	H, palette+15
	;APP
	HLT

	MVI	A, 0x88
	OUT	0
	MVI	B, 0xf
.Ltmp0:
	MOV	A, B
	OUT	2
	MOV	A, M
	OUT	0xc
	PUSH	PSW
	POP	PSW
	PUSH	PSW
	POP	PSW
	DCX	H
	DCR	B
	OUT	0xc
	JP	.Ltmp0

	;NO_APP
	RET
.Lfunc_end0:
                                        ; -- End function
	.section	.text.memset,"ax",@progbits
memset:                                 ; -- Begin function memset
                                        ; @memset
.Lfunc_begin1:
	;=== void memset(void) ===
	;  [folded: dst=0x8000, val=0, n=0x8000]
; %bb.0:
	;DEBUG_VALUE: memset:dst <- -32768
	;DEBUG_VALUE: memset:val <- 0
	;DEBUG_VALUE: memset:n <- -32768
	;DEBUG_VALUE: memset:p <- -32768
	;DEBUG_VALUE: i <- 0
	LXI	H, 0x8000
.LBB16_1:                               ; =>This Inner Loop Header: Depth=1
	;DEBUG_VALUE: memset:p <- -32768
	;DEBUG_VALUE: memset:n <- -32768
	;DEBUG_VALUE: memset:val <- 0
	;DEBUG_VALUE: memset:dst <- -32768
	;DEBUG_VALUE: i <- undef
	;--- V6C_STORE8_IMM_P ---
	MVI	M, 0
	;--- V6C_INX16 ---
	INX	H
	;--- V6C_BR_CC16_IMM ---
	MOV	A, H
	ORA	L
	JNZ	.LBB16_1
; %bb.2:
	;DEBUG_VALUE: memset:p <- -32768
	;DEBUG_VALUE: memset:n <- -32768
	;DEBUG_VALUE: memset:val <- 0
	;DEBUG_VALUE: memset:dst <- -32768
	RET
.Lfunc_end1:
                                        ; -- End function
	.section	.text.rand,"ax",@progbits
rand:                                   ; -- Begin function rand
                                        ; @rand
.Lfunc_begin2:
	;=== int rand(void) ===
; %bb.0:
	;APP
.Ltmp1:
	LHLD	__v6c_rand_state
	MOV	A, H
	RAR

	MOV	A, L
	RAR

	XRA	H
	MOV	H, A
	MOV	A, L
	RAR

	MOV	A, H
	RAR

	XRA	L
	MOV	L, A
	XRA	H
	MOV	H, A
	SHLD	__v6c_rand_state

	;NO_APP
	;DEBUG_VALUE: rand:_out <- $hl
	RET
.Lfunc_end2:
                                        ; -- End function
	.section	.text.draw_line,"ax",@progbits
draw_line:                              ; -- Begin function draw_line
                                        ; @draw_line
.Lfunc_begin3:
	;=== void draw_line(char x1, char y1) ===
	;  x1 = A
	;  y1 = B
	;  [folded: scr_addr_h=-128, x0=127, y0=127]
; %bb.0:
	;DEBUG_VALUE: draw_line:x1 <- $a
	;DEBUG_VALUE: draw_line:y1 <- $b
	;DEBUG_VALUE: draw_line:_x1 <- $a
	;DEBUG_VALUE: draw_line:_y1 <- $b
	MOV	E, B
	;DEBUG_VALUE: draw_line:_y1 <- $e
	;DEBUG_VALUE: draw_line:y1 <- $e
	MOV	D, A
	;DEBUG_VALUE: draw_line:_y0 <- 127
	;DEBUG_VALUE: draw_line:_x0 <- 127
	;DEBUG_VALUE: draw_line:_scr_addr_h <- -128
	;DEBUG_VALUE: draw_line:y0 <- 127
	;DEBUG_VALUE: draw_line:x0 <- 127
	;DEBUG_VALUE: draw_line:scr_addr_h <- -128
	;DEBUG_VALUE: draw_line:_x1 <- $d
	;DEBUG_VALUE: draw_line:x1 <- $d
	MVI	A, 0x80
	MVI	B, 0x7f
	MOV	C, B
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
.Lfunc_end3:
                                        ; -- End function
	.section	.text.draw_pixel,"ax",@progbits
draw_pixel:                             ; -- Begin function draw_pixel
                                        ; @draw_pixel
.Lfunc_begin4:
	;=== void draw_pixel(char x, char y) ===
	;  x = A
	;  y = B
; %bb.0:
	;DEBUG_VALUE: draw_pixel:x <- $a
	;DEBUG_VALUE: draw_pixel:y <- $b
	;DEBUG_VALUE: draw_pixel:_x <- $a
	;DEBUG_VALUE: draw_pixel:_y <- $b
	MOV	L, B
	;DEBUG_VALUE: draw_pixel:_y <- $l
	;DEBUG_VALUE: draw_pixel:y <- $l
	;APP
	MOV	C, A
	RRC

	RRC

	RRC

	ANI	0x1f
	ADI	0x80
	MOV	H, A
	MVI	A, 7
	ANA	C
	LXI	B, BIT_MASK
	ADD	C
	MOV	C, A
	ADC	B
	SUB	C
	MOV	B, A
	LDAX	B
	ORA	M
	MOV	M, A

	;NO_APP
	RET
.Lfunc_end4:
                                        ; -- End function
	.section	.text.draw_circle,"ax",@progbits
draw_circle:                            ; -- Begin function draw_circle
                                        ; @draw_circle
.Lfunc_begin5:
	;=== void draw_circle(char r) ===
	;  r = A
	;  [folded: value=127, cy=127]
; %bb.0:
	;DEBUG_VALUE: draw_circle:r <- $a
	;DEBUG_VALUE: draw_circle:x <- $a
	MOV	L, A
	;DEBUG_VALUE: draw_circle:y <- 0
	;DEBUG_VALUE: draw_circle:cy <- 127
	;DEBUG_VALUE: draw_circle:cx <- 127
	;DEBUG_VALUE: draw_circle:x <- $l
	;DEBUG_VALUE: draw_circle:r <- $l
	MVI	E, 0x7f
	RRC
	RRC
	RRC
	RRC
	ANI	0xf
	;DEBUG_VALUE: draw_circle:t1 <- $a
	;--- V6C_SPILL8 ---
	STA	.LLo61_4+1
	;DEBUG_VALUE: draw_circle:t1 <- [$sp+0]
	MOV	A, L
	;DEBUG_VALUE: draw_circle:x <- $a
	;DEBUG_VALUE: draw_circle:r <- $a
	MVI	D, 0
.LBB20_1:                               ; =>This Inner Loop Header: Depth=1
	;DEBUG_VALUE: draw_circle:t1 <- [$sp+0]
	;DEBUG_VALUE: draw_circle:cx <- 127
	;DEBUG_VALUE: draw_circle:cy <- 127
	;DEBUG_VALUE: draw_circle:x <- $a
	;DEBUG_VALUE: draw_circle:x <- $a
	;DEBUG_VALUE: draw_circle:y <- $d
	;DEBUG_VALUE: draw_circle:t1 <- [$sp+0]
	MOV	L, A
	;DEBUG_VALUE: draw_circle:x <- $l
	RRC
	MOV	C, A
	ANI	0x7f
	MOV	H, A
	MOV	A, C
	RRC
	ANI	0x3f
	;DEBUG_VALUE: draw_scale_x_4_3:value <- $l
	ADD	H
	MOV	H, A
	;--- V6C_SPILL8 ---
	MOV	A, L
	STA	.LLo61_0+1
	;DEBUG_VALUE: draw_scale_x_4_3:value <- [$sp+0]
	;DEBUG_VALUE: draw_circle:x <- [$sp+0]
	MOV	A, L
	ANI	3
	MVI	L, 0
	JZ	.LBB20_3
; %bb.2:                                ;   in Loop: Header=BB20_1 Depth=1
	;DEBUG_VALUE: draw_circle:x <- [$sp+0]
	;DEBUG_VALUE: draw_scale_x_4_3:value <- [$sp+0]
	;DEBUG_VALUE: draw_circle:y <- $d
	;DEBUG_VALUE: draw_circle:t1 <- [$sp+0]
	;DEBUG_VALUE: draw_circle:cx <- 127
	;DEBUG_VALUE: draw_circle:cy <- 127
	MVI	L, 1
.LBB20_3:                               ;   in Loop: Header=BB20_1 Depth=1
	;DEBUG_VALUE: draw_circle:x <- [$sp+0]
	;DEBUG_VALUE: draw_scale_x_4_3:value <- [$sp+0]
	;DEBUG_VALUE: draw_circle:y <- $d
	;DEBUG_VALUE: draw_circle:t1 <- [$sp+0]
	;DEBUG_VALUE: draw_circle:cx <- 127
	;DEBUG_VALUE: draw_circle:cy <- 127
	MOV	A, H
	ADD	L
	;DEBUG_VALUE: sx <- $a
	;--- V6C_SPILL8 ---
	STA	.LLo61_1+1
	;DEBUG_VALUE: sx <- [$sp+0]
	ADI	0x7f
	MOV	L, A
	;--- V6C_SPILL8 ---
	MOV	A, L
	STA	.LLo61_2+1
	MOV	A, D
	ADI	0x7f
	;--- V6C_SPILL8 ---
	MOV	B, A
	MOV	A, D
	STA	.LLo61_3+1
	MOV	D, B
	MOV	A, L
	MOV	B, D
	CALL	draw_pixel
	;--- V6C_RELOAD8 ---
.LLo61_1:
	MVI	A, 0
	;DEBUG_VALUE: sx <- $a
	XRI	0x7f
	;--- V6C_SPILL8 ---
	STA	.LLo61_1+1
	;--- V6C_RELOAD8 ---
	LDA	.LLo61_1+1
	MOV	B, D
	CALL	draw_pixel
	;--- V6C_RELOAD8 ---
	LDA	.LLo61_2+1
	MOV	B, E
	CALL	draw_pixel
	;--- V6C_RELOAD8 ---
	LDA	.LLo61_1+1
	;--- V6C_SPILL8 ---
	LXI	H, .LLo61_2+1
	MOV	M, E
	MOV	B, E
	CALL	draw_pixel
	;--- V6C_RELOAD8 ---
.LLo61_3:
	MVI	H, 0
	MOV	A, H
	RRC
	MOV	E, A
	ANI	0x7f
	MOV	L, A
	MOV	A, E
	RRC
	ANI	0x3f
	;DEBUG_VALUE: draw_scale_x_4_3:value <- $h
	ADD	L
	MOV	L, A
	;DEBUG_VALUE: draw_scale_x_4_3:value <- [$sp+0]
	MOV	A, H
	ANI	3
	MVI	H, 0
	JZ	.LBB20_5
; %bb.4:                                ;   in Loop: Header=BB20_1 Depth=1
	;DEBUG_VALUE: draw_scale_x_4_3:value <- [$sp+0]
	;DEBUG_VALUE: draw_circle:x <- [$sp+0]
	;DEBUG_VALUE: draw_scale_x_4_3:value <- [$sp+0]
	;DEBUG_VALUE: draw_circle:t1 <- [$sp+0]
	;DEBUG_VALUE: draw_circle:cx <- 127
	;DEBUG_VALUE: draw_circle:cy <- 127
	MVI	H, 1
.LBB20_5:                               ;   in Loop: Header=BB20_1 Depth=1
	;DEBUG_VALUE: draw_scale_x_4_3:value <- [$sp+0]
	;DEBUG_VALUE: draw_circle:x <- [$sp+0]
	;DEBUG_VALUE: draw_circle:t1 <- [$sp+0]
	;DEBUG_VALUE: draw_circle:cx <- 127
	;DEBUG_VALUE: draw_circle:cy <- 127
	MOV	A, L
	ADD	H
	;DEBUG_VALUE: sy <- $a
	MOV	E, A
	;DEBUG_VALUE: sy <- $e
	ADI	0x7f
	;--- V6C_SPILL8 ---
	STA	.LLo61_1+1
	;--- V6C_RELOAD8 ---
	LDA	.LLo61_0+1
	ADI	0x7f
	MOV	D, A
	;--- V6C_RELOAD8 ---
	LDA	.LLo61_1+1
	MOV	B, D
	CALL	draw_pixel
	MOV	A, E
	;DEBUG_VALUE: sy <- $a
	XRI	0x7f
	MOV	E, A
	MOV	B, D
	CALL	draw_pixel
	;--- V6C_RELOAD8 ---
	LDA	.LLo61_0+1
	;--- V6C_RELOAD8 ---
	LDA	.LLo61_0+1
	XRI	0x7f
	MOV	D, A
	;--- V6C_RELOAD8 ---
	LDA	.LLo61_1+1
	MOV	B, D
	CALL	draw_pixel
	MOV	A, E
	MOV	B, D
	CALL	draw_pixel
	;--- V6C_RELOAD8 ---
	LXI	H, .LLo61_3+1
	MOV	L, M
	INR	L
	;DEBUG_VALUE: draw_circle:t1 <- [DW_OP_LLVM_arg 0, DW_OP_LLVM_arg 1, DW_OP_deref, DW_OP_plus, DW_OP_stack_value] $l, $sp
	;DEBUG_VALUE: draw_circle:y <- $l
	;--- V6C_RELOAD8 ---
.LLo61_4:
	MVI	A, 0
	;DEBUG_VALUE: draw_circle:t1 <- [DW_OP_LLVM_arg 0, DW_OP_LLVM_arg 1, DW_OP_plus, DW_OP_stack_value] $l, $a
	;--- V6C_SPILL8 ---
	MOV	B, A
	MOV	A, L
	STA	.LLo61_3+1
	MOV	A, B
	ADD	L
	;DEBUG_VALUE: draw_circle:y <- [$sp+0]
	MVI	C, 0
	;--- V6C_RELOAD8 ---
.LLo61_0:
	MVI	L, 0
	;--- V6C_BUILD_PAIR ---
	MOV	H, C
	;--- V6C_SPILL8 ---
	STA	.LLo61_4+1
	;--- V6C_BUILD_PAIR ---
	MOV	B, C
	;--- V6C_SUB16 ---
	SUB	L
	MOV	L, A
	MOV	A, B
	SBB	H
	MOV	H, A
	;DEBUG_VALUE: t2 <- $hl
	;--- V6C_CMP16_SIGN ---
	XRA	A
	ADD	H
	JM	.LBB20_7
; %bb.6:                                ;   in Loop: Header=BB20_1 Depth=1
	;DEBUG_VALUE: t2 <- $hl
	;DEBUG_VALUE: draw_circle:y <- [$sp+0]
	;DEBUG_VALUE: draw_scale_x_4_3:value <- [$sp+0]
	;DEBUG_VALUE: draw_circle:x <- [$sp+0]
	;DEBUG_VALUE: draw_circle:cx <- 127
	;DEBUG_VALUE: draw_circle:cy <- 127
	MOV	A, L
	;--- V6C_SPILL8 ---
	STA	.LLo61_4+1
.LBB20_7:                               ;   in Loop: Header=BB20_1 Depth=1
	;DEBUG_VALUE: t2 <- $hl
	;DEBUG_VALUE: draw_circle:y <- [$sp+0]
	;DEBUG_VALUE: draw_circle:x <- [$sp+0]
	;DEBUG_VALUE: draw_circle:cx <- 127
	;DEBUG_VALUE: draw_circle:cy <- 127
	;DEBUG_VALUE: draw_circle:t1 <- [$sp+0]
	MVI	L, 0
	;--- V6C_RELOAD8 ---
.LLo61_2:
	MVI	E, 0
	JM	.LBB20_9
; %bb.8:                                ;   in Loop: Header=BB20_1 Depth=1
	;DEBUG_VALUE: draw_circle:y <- [$sp+0]
	;DEBUG_VALUE: draw_circle:x <- [$sp+0]
	;DEBUG_VALUE: draw_circle:t1 <- [$sp+0]
	;DEBUG_VALUE: draw_circle:cx <- 127
	;DEBUG_VALUE: draw_circle:cy <- 127
	MVI	L, 1
.LBB20_9:                               ;   in Loop: Header=BB20_1 Depth=1
	;DEBUG_VALUE: draw_circle:y <- [$sp+0]
	;DEBUG_VALUE: draw_circle:x <- [$sp+0]
	;DEBUG_VALUE: draw_circle:t1 <- [$sp+0]
	;DEBUG_VALUE: draw_circle:cx <- 127
	;DEBUG_VALUE: draw_circle:cy <- 127
	;--- V6C_RELOAD8 ---
	LDA	.LLo61_0+1
	SUB	L
	;DEBUG_VALUE: draw_circle:x <- $a
	DCR	E
	;--- V6C_RELOAD8 ---
	LXI	H, .LLo61_3+1
	MOV	D, M
	CMP	D
	;--- V6C_BRCOND ---
	JNC	.LBB20_1
; %bb.10:
	;DEBUG_VALUE: draw_circle:y <- [$sp+0]
	;DEBUG_VALUE: draw_circle:t1 <- [$sp+0]
	;DEBUG_VALUE: draw_circle:cx <- 127
	;DEBUG_VALUE: draw_circle:cy <- 127
	;DEBUG_VALUE: draw_circle:x <- $a
	RET
.Lfunc_end5:
                                        ; -- End function
	.section	.text.sin8,"ax",@progbits
sin8:                                   ; -- Begin function sin8
                                        ; @sin8
.Lfunc_begin6:
	;=== char sin8(char angle) ===
	;  angle = A
; %bb.0:
	;DEBUG_VALUE: sin8:angle <- $a
	;--- V6C_BUILD_PAIR ---
	MVI	H, 0
	MOV	L, A
	LXI	D, sin_lut
	;--- V6C_DAD ---
	DAD	D
	;--- V6C_LOAD8_P ---
	MOV	A, M
	RET
.Lfunc_end6:
                                        ; -- End function
	.section	.text.main,"ax",@progbits
	.globl	main                            ; -- Begin function main
main:                                   ; @main
.Lfunc_begin7:
	;=== void main(void) ===
; %bb.0:
	;APP
	MVI	A, 0xfb
	STA	0x38
	MVI	A, 0xc9
	STA	0x39

	;NO_APP
	;APP
	EI

	;NO_APP
	CALL	v6c_set_palette
	CALL	memset
	MVI	A, 0x64
	;DEBUG_VALUE: i <- 0
.LBB22_1:                               ; =>This Inner Loop Header: Depth=1
	;DEBUG_VALUE: i <- undef
	;--- V6C_SPILL8 ---
	STA	.LLo61_6+1
	CALL	rand
	;DEBUG_VALUE: r1 <- $hl
	;DEBUG_VALUE: x1 <- $l
	;--- V6C_SRL16_BYTE ---
	;DEBUG_VALUE: y1 <- $e
	MOV	A, L
	MOV	B, H
	CALL	draw_line
	;--- V6C_RELOAD8 ---
.LLo61_6:
	MVI	A, 0
	DCR	A
	;--- V6C_BRCOND ---
	JNZ	.LBB22_1
; %bb.2:
	MVI	H, 0xa
	MVI	A, 0x64
.LBB22_3:                               ; =>This Inner Loop Header: Depth=1
	;DEBUG_VALUE: i <- undef
	;--- V6C_SPILL8 ---
	STA	.LLo61_6+1
	;--- V6C_SPILL8 ---
	MOV	A, H
	STA	.LLo61_7+1
	;--- V6C_RELOAD8 ---
	LDA	.LLo61_6+1
	CALL	draw_circle
	;--- V6C_RELOAD8 ---
.LLo61_7:
	MVI	H, 0
	;--- V6C_RELOAD8 ---
	LDA	.LLo61_6+1
	ADI	0xf6
	DCR	H
	;--- V6C_BRCOND ---
	JNZ	.LBB22_3
; %bb.5:
	LXI	H, 0x100
	MOV	E, L
.LBB22_6:                               ; =>This Inner Loop Header: Depth=1
	;DEBUG_VALUE: x <- [DW_OP_consts 256, DW_OP_minus, DW_OP_consts 18446744073709551615, DW_OP_div, DW_OP_stack_value] $hl
	;--- V6C_SPILL16 ---
	SHLD	.LLo61_5+1
	MOV	A, E
	;DEBUG_VALUE: x <- [DW_OP_deref_size 0, DW_OP_consts 256, DW_OP_minus, DW_OP_consts 18446744073709551615, DW_OP_div, DW_OP_stack_value] $sp
	CALL	sin8
	ADI	0x7f
	;DEBUG_VALUE: y <- $a
	MOV	B, A
	;DEBUG_VALUE: y <- $b
	MOV	A, E
	CALL	draw_pixel
	;--- V6C_RELOAD16 ---
.LLo61_5:
	LXI	H, 0
	;DEBUG_VALUE: x <- [DW_OP_consts 256, DW_OP_minus, DW_OP_consts 18446744073709551615, DW_OP_div, DW_OP_stack_value] $hl
	INR	E
	;DEBUG_VALUE: x <- [DW_OP_consts 256, DW_OP_minus, DW_OP_consts 18446744073709551615, DW_OP_div, DW_OP_consts 1, DW_OP_plus, DW_OP_stack_value] $hl
	;--- V6C_DCX16 ---
	DCX	H
	;--- V6C_BR_CC16_IMM ---
	MOV	A, H
	ORA	L
	JNZ	.LBB22_6
; %bb.4:
	RET
.Lfunc_end7:
                                        ; -- End function
	.data
	.globl	__v6c_rand_state                ; @__v6c_rand_state
__v6c_rand_state:
	DW	1                               ; 0x1

palette:                                ; @palette
	.ascii	"\000\021\"3DUfw\210\231\252\273\314\335\356\377"

	.section	.rodata,"a",@progbits
BIT_MASK:                               ; @BIT_MASK
	.ascii	"\200@ \020\b\004\002\001"

sin_lut:                                ; @sin_lut
	.ascii	"\000\003\006\t\f\020\023\026\031\034\037\"%(+.1369<?ADGILNQSUXZ\\^`bdfhjkmnpqstuvxyzz{|}}~~~\177\177\177\177\177\177\177~~~}}|{zzyxvutsqpnmkjhfdb`^\\ZXUSQNLIGDA?<9631.+(%\"\037\034\031\026\023\020\f\t\006\003\000\375\372\367\364\360\355\352\347\344\341\336\333\330\325\322\317\315\312\307\304\301\277\274\271\267\264\262\257\255\253\250\246\244\242\240\236\234\232\230\226\225\223\222\220\217\215\214\213\212\210\207\206\206\205\204\203\203\202\202\202\201\201\201\201\201\201\201\202\202\202\203\203\204\205\206\206\207\210\212\213\214\215\217\220\222\223\225\226\230\232\234\236\240\242\244\246\250\253\255\257\262\264\267\271\274\277\301\304\307\312\315\317\322\325\330\333\336\341\344\347\352\355\360\364\367\372\375"

	.local	__v6c_ss.draw_circle            ; @__v6c_ss.draw_circle
	.comm	__v6c_ss.draw_circle,4,1
	.local	__v6c_ss.main                   ; @__v6c_ss.main
	.comm	__v6c_ss.main,2,1
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
	.addrsig_sym palette
	.addrsig_sym BIT_MASK
