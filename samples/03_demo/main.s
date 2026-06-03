	.text
	.section	.text.v6c_set_empty_interrupt_handler,"ax",@progbits
v6c_set_empty_interrupt_handler:        ; -- Begin function v6c_set_empty_interrupt_handler
                                        ; @v6c_set_empty_interrupt_handler
.Lfunc_begin0:
	;=== void v6c_set_empty_interrupt_handler(void) ===
	;  [folded: handler=@v6c_empty_interrupt_handler]
; %bb.0:
	LXI	H, v6c_empty_interrupt_handler
	;DEBUG_VALUE: v6c_set_interrupt_handler:handler <- $hl
	;DEBUG_VALUE: v6c_set_interrupt_handler:_handler <- $hl
	;APP
	SHLD	INT_ADDR

	;NO_APP
	RET
.Lfunc_end0:
                                        ; -- End function
	.section	.text.memset,"ax",@progbits
memset:                                 ; -- Begin function memset
                                        ; @memset
.Lfunc_begin1:
	;=== void* memset(void* dst, int val, int n) ===
	;  dst = HL
	;  val = DE
	;  n = BC
; %bb.0:
	;DEBUG_VALUE: memset:dst <- $hl
	;DEBUG_VALUE: memset:val <- $de
	;DEBUG_VALUE: memset:n <- $bc
	;DEBUG_VALUE: memset:p <- $hl
	;--- V6C_SPILL16 ---
	XCHG
	SHLD	.LLo61_0+1
	XCHG
	;DEBUG_VALUE: memset:val <- [$sp+0]
	MOV	D, B
	MOV	E, C
	;DEBUG_VALUE: memset:n <- $de
	;--- V6C_SPILL16 ---
	SHLD	.LLo61_1+1
	;DEBUG_VALUE: i <- 0
	;DEBUG_VALUE: memset:p <- [$sp+0]
	;DEBUG_VALUE: memset:dst <- [$sp+0]
	;--- V6C_BR_CC16_IMM ---
	MOV	A, D
	ORA	E
	JZ	.LBB17_1
; %bb.2:
	;DEBUG_VALUE: memset:dst <- [$sp+0]
	;DEBUG_VALUE: memset:p <- [$sp+0]
	;DEBUG_VALUE: i <- 0
	;DEBUG_VALUE: memset:n <- $de
	;DEBUG_VALUE: memset:val <- [$sp+0]
	LXI	B, 0
	;--- V6C_RELOAD16 ---
	LHLD	.LLo61_1+1
	;--- V6C_SPILL16 ---
	XCHG
	SHLD	.LLo61_2+1
	XCHG
.LBB17_3:                               ; =>This Inner Loop Header: Depth=1
	;DEBUG_VALUE: memset:dst <- [$sp+0]
	;DEBUG_VALUE: memset:p <- [$sp+0]
	;DEBUG_VALUE: memset:val <- [$sp+0]
	;DEBUG_VALUE: i <- $bc
	;--- V6C_RELOAD16 ---
.LLo61_0:
	LXI	D, 0
	;--- V6C_STORE8_P ---
	MOV	M, E
	;--- V6C_RELOAD16 ---
.LLo61_2:
	LXI	D, 0
	;--- V6C_INX16 ---
	INX	H
	;--- V6C_INX16 ---
	INX	B
	;DEBUG_VALUE: i <- $bc
	;--- V6C_BR_CC16 ---
	MOV	A, C
	SUB	E
	MOV	A, B
	SBB	D
	JC	.LBB17_3
.LBB17_1:
	;DEBUG_VALUE: memset:dst <- [$sp+0]
	;DEBUG_VALUE: memset:p <- [$sp+0]
	;DEBUG_VALUE: memset:val <- [$sp+0]
	;--- V6C_RELOAD16 ---
.LLo61_1:
	LXI	H, 0
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
.Ltmp0:
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
	;=== void draw_pixel(char x, char y, char scr_addr_hi) ===
	;  x = A
	;  y = B
	;  scr_addr_hi = C
; %bb.0:
	;DEBUG_VALUE: draw_pixel:x <- $a
	;DEBUG_VALUE: draw_pixel:y <- $b
	;DEBUG_VALUE: draw_pixel:scr_addr_hi <- $c
	;DEBUG_VALUE: draw_pixel:_x <- $a
	;DEBUG_VALUE: draw_pixel:_y <- $b
	;DEBUG_VALUE: draw_pixel:_scr_addr_hi <- $c
	MOV	L, B
	;DEBUG_VALUE: draw_pixel:_y <- $l
	;DEBUG_VALUE: draw_pixel:y <- $l
	MOV	H, C
	;DEBUG_VALUE: draw_pixel:_scr_addr_hi <- $h
	;DEBUG_VALUE: draw_pixel:scr_addr_hi <- $h
	;APP
	MOV	C, A
	RRC

	RRC

	RRC

	ANI	0x1f
	ADD	H
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
	;  [folded: value=127, cy=127, scr_addr_hi=-96]
; %bb.0:
	;DEBUG_VALUE: draw_circle:r <- $a
	;DEBUG_VALUE: draw_circle:x <- $a
	MOV	L, A
	;DEBUG_VALUE: draw_circle:y <- 0
	;DEBUG_VALUE: draw_circle:scr_addr_hi <- -96
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
	STA	.LLo61_7+1
	;DEBUG_VALUE: draw_circle:t1 <- [$sp+0]
	MOV	A, L
	;DEBUG_VALUE: draw_circle:x <- $a
	;DEBUG_VALUE: draw_circle:r <- $a
	MVI	D, 0
.LBB21_1:                               ; =>This Inner Loop Header: Depth=1
	;DEBUG_VALUE: draw_circle:t1 <- [$sp+0]
	;DEBUG_VALUE: draw_circle:cx <- 127
	;DEBUG_VALUE: draw_circle:cy <- 127
	;DEBUG_VALUE: draw_circle:scr_addr_hi <- -96
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
	STA	.LLo61_3+1
	;DEBUG_VALUE: draw_scale_x_4_3:value <- [$sp+0]
	;DEBUG_VALUE: draw_circle:x <- [$sp+0]
	ANI	3
	MVI	L, 0
	JZ	.LBB21_3
; %bb.2:                                ;   in Loop: Header=BB21_1 Depth=1
	;DEBUG_VALUE: draw_circle:x <- [$sp+0]
	;DEBUG_VALUE: draw_scale_x_4_3:value <- [$sp+0]
	;DEBUG_VALUE: draw_circle:y <- $d
	;DEBUG_VALUE: draw_circle:t1 <- [$sp+0]
	;DEBUG_VALUE: draw_circle:cx <- 127
	;DEBUG_VALUE: draw_circle:cy <- 127
	;DEBUG_VALUE: draw_circle:scr_addr_hi <- -96
	MVI	L, 1
.LBB21_3:                               ;   in Loop: Header=BB21_1 Depth=1
	;DEBUG_VALUE: draw_circle:x <- [$sp+0]
	;DEBUG_VALUE: draw_scale_x_4_3:value <- [$sp+0]
	;DEBUG_VALUE: draw_circle:y <- $d
	;DEBUG_VALUE: draw_circle:t1 <- [$sp+0]
	;DEBUG_VALUE: draw_circle:cx <- 127
	;DEBUG_VALUE: draw_circle:cy <- 127
	;DEBUG_VALUE: draw_circle:scr_addr_hi <- -96
	MOV	A, H
	ADD	L
	;DEBUG_VALUE: sx <- $a
	;--- V6C_SPILL8 ---
	STA	.LLo61_4+1
	;DEBUG_VALUE: sx <- [$sp+0]
	ADI	0x7f
	MOV	L, A
	;--- V6C_SPILL8 ---
	STA	.LLo61_5+1
	MOV	A, D
	ADI	0x7f
	;--- V6C_SPILL8 ---
	MOV	B, A
	MOV	A, D
	STA	.LLo61_6+1
	MOV	D, B
	MOV	A, L
	MVI	C, 0xa0
	CALL	draw_pixel
	;--- V6C_RELOAD8 ---
.LLo61_4:
	MVI	A, 0
	;DEBUG_VALUE: sx <- $a
	XRI	0x7f
	;--- V6C_SPILL8 ---
	STA	.LLo61_4+1
	;--- V6C_RELOAD8 ---
	LDA	.LLo61_4+1
	MOV	B, D
	MVI	C, 0xa0
	CALL	draw_pixel
	;--- V6C_RELOAD8 ---
	LDA	.LLo61_5+1
	MOV	B, E
	MVI	C, 0xa0
	CALL	draw_pixel
	;--- V6C_RELOAD8 ---
	LDA	.LLo61_4+1
	;--- V6C_SPILL8 ---
	LXI	H, .LLo61_5+1
	MOV	M, E
	MOV	B, E
	MVI	C, 0xa0
	CALL	draw_pixel
	;--- V6C_RELOAD8 ---
.LLo61_6:
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
	JZ	.LBB21_5
; %bb.4:                                ;   in Loop: Header=BB21_1 Depth=1
	;DEBUG_VALUE: draw_scale_x_4_3:value <- [$sp+0]
	;DEBUG_VALUE: draw_circle:x <- [$sp+0]
	;DEBUG_VALUE: draw_scale_x_4_3:value <- [$sp+0]
	;DEBUG_VALUE: draw_circle:t1 <- [$sp+0]
	;DEBUG_VALUE: draw_circle:cx <- 127
	;DEBUG_VALUE: draw_circle:cy <- 127
	;DEBUG_VALUE: draw_circle:scr_addr_hi <- -96
	MVI	H, 1
.LBB21_5:                               ;   in Loop: Header=BB21_1 Depth=1
	;DEBUG_VALUE: draw_scale_x_4_3:value <- [$sp+0]
	;DEBUG_VALUE: draw_circle:x <- [$sp+0]
	;DEBUG_VALUE: draw_circle:t1 <- [$sp+0]
	;DEBUG_VALUE: draw_circle:cx <- 127
	;DEBUG_VALUE: draw_circle:cy <- 127
	;DEBUG_VALUE: draw_circle:scr_addr_hi <- -96
	MOV	A, L
	ADD	H
	;DEBUG_VALUE: sy <- $a
	MOV	E, A
	;DEBUG_VALUE: sy <- $e
	ADI	0x7f
	;--- V6C_SPILL8 ---
	STA	.LLo61_4+1
	;--- V6C_RELOAD8 ---
	LDA	.LLo61_3+1
	ADI	0x7f
	MOV	D, A
	;--- V6C_RELOAD8 ---
	LDA	.LLo61_4+1
	MOV	B, D
	MVI	C, 0xa0
	CALL	draw_pixel
	MOV	A, E
	;DEBUG_VALUE: sy <- $a
	XRI	0x7f
	MOV	E, A
	MOV	B, D
	MVI	C, 0xa0
	CALL	draw_pixel
	;--- V6C_RELOAD8 ---
	LDA	.LLo61_3+1
	XRI	0x7f
	MOV	D, A
	;--- V6C_RELOAD8 ---
	LDA	.LLo61_4+1
	MOV	B, D
	MVI	C, 0xa0
	CALL	draw_pixel
	MOV	A, E
	MOV	B, D
	MVI	C, 0xa0
	CALL	draw_pixel
	;--- V6C_RELOAD8 ---
	LXI	H, .LLo61_6+1
	MOV	L, M
	INR	L
	;DEBUG_VALUE: draw_circle:t1 <- [DW_OP_LLVM_arg 0, DW_OP_LLVM_arg 1, DW_OP_deref, DW_OP_plus, DW_OP_stack_value] $l, $sp
	;DEBUG_VALUE: draw_circle:y <- $l
	;--- V6C_RELOAD8 ---
.LLo61_7:
	MVI	A, 0
	;DEBUG_VALUE: draw_circle:t1 <- [DW_OP_LLVM_arg 0, DW_OP_LLVM_arg 1, DW_OP_plus, DW_OP_stack_value] $l, $a
	;--- V6C_SPILL8 ---
	MOV	B, A
	MOV	A, L
	STA	.LLo61_6+1
	MOV	A, B
	ADD	L
	;DEBUG_VALUE: draw_circle:y <- [$sp+0]
	MVI	C, 0
	;--- V6C_RELOAD8 ---
.LLo61_3:
	MVI	L, 0
	;--- V6C_BUILD_PAIR ---
	MOV	H, C
	;--- V6C_SPILL8 ---
	STA	.LLo61_7+1
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
	JM	.LBB21_7
; %bb.6:                                ;   in Loop: Header=BB21_1 Depth=1
	;DEBUG_VALUE: t2 <- $hl
	;DEBUG_VALUE: draw_circle:y <- [$sp+0]
	;DEBUG_VALUE: draw_scale_x_4_3:value <- [$sp+0]
	;DEBUG_VALUE: draw_circle:x <- [$sp+0]
	;DEBUG_VALUE: draw_circle:cx <- 127
	;DEBUG_VALUE: draw_circle:cy <- 127
	;DEBUG_VALUE: draw_circle:scr_addr_hi <- -96
	MOV	A, L
	;--- V6C_SPILL8 ---
	STA	.LLo61_7+1
.LBB21_7:                               ;   in Loop: Header=BB21_1 Depth=1
	;DEBUG_VALUE: t2 <- $hl
	;DEBUG_VALUE: draw_circle:y <- [$sp+0]
	;DEBUG_VALUE: draw_circle:x <- [$sp+0]
	;DEBUG_VALUE: draw_circle:cx <- 127
	;DEBUG_VALUE: draw_circle:cy <- 127
	;DEBUG_VALUE: draw_circle:scr_addr_hi <- -96
	;DEBUG_VALUE: draw_circle:t1 <- [$sp+0]
	MVI	L, 0
	;--- V6C_RELOAD8 ---
.LLo61_5:
	MVI	E, 0
	JM	.LBB21_9
; %bb.8:                                ;   in Loop: Header=BB21_1 Depth=1
	;DEBUG_VALUE: draw_circle:y <- [$sp+0]
	;DEBUG_VALUE: draw_circle:x <- [$sp+0]
	;DEBUG_VALUE: draw_circle:t1 <- [$sp+0]
	;DEBUG_VALUE: draw_circle:cx <- 127
	;DEBUG_VALUE: draw_circle:cy <- 127
	;DEBUG_VALUE: draw_circle:scr_addr_hi <- -96
	MVI	L, 1
.LBB21_9:                               ;   in Loop: Header=BB21_1 Depth=1
	;DEBUG_VALUE: draw_circle:y <- [$sp+0]
	;DEBUG_VALUE: draw_circle:x <- [$sp+0]
	;DEBUG_VALUE: draw_circle:t1 <- [$sp+0]
	;DEBUG_VALUE: draw_circle:cx <- 127
	;DEBUG_VALUE: draw_circle:cy <- 127
	;DEBUG_VALUE: draw_circle:scr_addr_hi <- -96
	;--- V6C_RELOAD8 ---
	LDA	.LLo61_3+1
	SUB	L
	;DEBUG_VALUE: draw_circle:x <- $a
	DCR	E
	;--- V6C_RELOAD8 ---
	LXI	H, .LLo61_6+1
	MOV	D, M
	CMP	D
	;--- V6C_BRCOND ---
	JNC	.LBB21_1
; %bb.10:
	;DEBUG_VALUE: draw_circle:y <- [$sp+0]
	;DEBUG_VALUE: draw_circle:t1 <- [$sp+0]
	;DEBUG_VALUE: draw_circle:cx <- 127
	;DEBUG_VALUE: draw_circle:cy <- 127
	;DEBUG_VALUE: draw_circle:scr_addr_hi <- -96
	;DEBUG_VALUE: draw_circle:x <- $a
	RET
.Lfunc_end5:
                                        ; -- End function
	.section	.text.sin8,"ax",@progbits
sin8:                                   ; -- Begin function sin8
                                        ; @sin8
.Lfunc_begin6:
	;=== int sin8(int angle) ===
	;  angle = HL
; %bb.0:
	;DEBUG_VALUE: sin8:angle <- $hl
	LXI	B, 0x168
	LXI	D, 0x168
	CALL	__modhi3
	;DEBUG_VALUE: sin8:r <- $hl
	;--- V6C_CMP16_SIGN ---
	XRA	A
	ADD	H
	JP	.LBB22_2
; %bb.1:
	;DEBUG_VALUE: sin8:r <- $hl
	;--- V6C_ADD16 ---
	DAD	B
.LBB22_2:
	;DEBUG_VALUE: sin8:r <- $hl
	;DEBUG_VALUE: sin8:a <- $hl
	;--- V6C_BR_CC16_IMM ---
	MVI	A, 0x59
	SUB	L
	MVI	A, 0
	SBB	H
	JNC	.LBB22_9
; %bb.3:
	;DEBUG_VALUE: sin8:a <- $hl
	;DEBUG_VALUE: sin8:r <- $hl
	;--- V6C_BR_CC16_IMM ---
	MVI	A, 0xb3
	SUB	L
	MVI	A, 0
	SBB	H
	JC	.LBB22_4
; %bb.8:
	;DEBUG_VALUE: sin8:a <- $hl
	;DEBUG_VALUE: sin8:r <- $hl
	LXI	D, 0xb4
	;--- V6C_SUB16 ---
	MOV	A, E
	SUB	L
	MOV	L, A
	MOV	A, D
	SBB	H
	MOV	H, A
	;DEBUG_VALUE: sin8:neg <- 0
	;DEBUG_VALUE: sin8:idx <- [DW_OP_LLVM_arg 0, DW_OP_LLVM_arg 1, DW_OP_LLVM_convert 16 7, DW_OP_LLVM_convert 8 7, DW_OP_minus, DW_OP_stack_value] -76, $hl
.LBB22_9:
	;DEBUG_VALUE: sin8:idx <- $hl
	;DEBUG_VALUE: sin8:neg <- undef
	;DEBUG_VALUE: sin_quarter:deg <- $hl
	;DEBUG_VALUE: sin_quarter:_hl <- $hl
	;APP
	DAD	H
	LXI	D, sin_q_lut
	DAD	D
	MOV	A, M
	INX	H
	MOV	H, M
	MOV	L, A

	;NO_APP
	;DEBUG_VALUE: sin8:v <- $hl
	;DEBUG_VALUE: sin_quarter:_hl <- $hl
	RET
.LBB22_4:
	;DEBUG_VALUE: sin8:a <- $hl
	;DEBUG_VALUE: sin8:r <- $hl
	;--- V6C_CMP16_IMM ---
	MVI	A, 0xd
	SUB	L
	MVI	A, 1
	SBB	H
	JC	.LBB22_5
; %bb.6:
	;DEBUG_VALUE: sin8:a <- $hl
	;DEBUG_VALUE: sin8:r <- $hl
	LXI	D, 0x4c
	;--- V6C_ADD16 ---
	DAD	D
	JMP	.LBB22_7
.LBB22_5:
	;DEBUG_VALUE: sin8:a <- $hl
	;DEBUG_VALUE: sin8:r <- $hl
	LXI	D, 0x68
	;--- V6C_SUB16 ---
	MOV	A, E
	SUB	L
	MOV	L, A
	MOV	A, D
	SBB	H
	MOV	H, A
.LBB22_7:
	;DEBUG_VALUE: sin8:idx <- $hl
	;DEBUG_VALUE: sin8:neg <- undef
	;DEBUG_VALUE: sin_quarter:deg <- $hl
	;--- V6C_AND16_IMM ---
	MVI	H, 0
	;DEBUG_VALUE: sin_quarter:_hl <- $hl
	;APP
	DAD	H
	LXI	D, sin_q_lut
	DAD	D
	MOV	A, M
	INX	H
	MOV	H, M
	MOV	L, A

	;NO_APP
	;DEBUG_VALUE: sin8:v <- $hl
	;DEBUG_VALUE: sin_quarter:_hl <- $hl
	;--- V6C_NEG16 ---
	XRA	A
	SUB	L
	MOV	L, A
	SBB	A
	SUB	H
	MOV	H, A
	RET
.Lfunc_end6:
                                        ; -- End function
	.section	.text.memcpy,"ax",@progbits
memcpy:                                 ; -- Begin function memcpy
                                        ; @memcpy
.Lfunc_begin7:
	;=== void memcpy(void* dst, void* src) ===
	;  dst = HL
	;  src = DE
	;  [folded: n=8]
; %bb.0:
	;DEBUG_VALUE: memcpy:dst <- $hl
	;DEBUG_VALUE: memcpy:src <- $de
	;DEBUG_VALUE: memcpy:n <- 8
	;DEBUG_VALUE: memcpy:dst_reg <- $hl
	;DEBUG_VALUE: memcpy:src_reg <- $de
	;DEBUG_VALUE: memcpy:n_reg <- 8
	LXI	B, 8
	;APP
	PUSH	H
.Ltmp1:
	MOV	A, B
	ORA	C
	JZ	.Ltmp2
	LDAX	D
	MOV	M, A
	INX	H
	INX	D
	DCX	B
	JMP	.Ltmp1
.Ltmp2:
	POP	H
	RET


	;NO_APP
	RET
.Lfunc_end7:
                                        ; -- End function
	.section	.text.draw_text,"ax",@progbits
draw_text:                              ; -- Begin function draw_text
                                        ; @draw_text
.Lfunc_begin8:
	;=== void draw_text(void* text, char y) ===
	;  text = HL
	;  y = A
	;  [folded: x=64, scr_addr_hi=-64]
; %bb.0:
	;DEBUG_VALUE: draw_text:y <- $a
	;DEBUG_VALUE: draw_text:text <- $hl
	;DEBUG_VALUE: draw_text:addr_base <- [DW_OP_LLVM_convert 8 7, DW_OP_LLVM_convert 16 7, DW_OP_constu 18446744073709537280, DW_OP_or, DW_OP_stack_value] $a
	MOV	B, H
	MOV	C, L
	;DEBUG_VALUE: draw_text:scr_addr_hi <- -64
	;DEBUG_VALUE: draw_text:x <- 64
	;DEBUG_VALUE: draw_text:text <- $bc
	;--- V6C_LOAD8_P ---
	MOV	D, A
	LDAX	B
	MOV	E, A
	MOV	A, D
	;DEBUG_VALUE: draw_text:c <- $e
	;--- V6C_CMP8_ZERO ---
	INR	E
	DCR	E
	;DEBUG_VALUE: draw_text:font <- undef
	;--- V6C_BRCOND ---
	RZ
.LBB24_1:
	;DEBUG_VALUE: draw_text:text <- $bc
	;DEBUG_VALUE: draw_text:x <- 64
	;DEBUG_VALUE: draw_text:scr_addr_hi <- -64
	;--- V6C_BUILD_PAIR ---
	MVI	H, 0
	MOV	L, A
	;DEBUG_VALUE: draw_text:addr_base <- [DW_OP_constu 18446744073709537280, DW_OP_or, DW_OP_stack_value] $hl
	;--- V6C_INX16 ---
	INX	B
	;--- V6C_OR16_IMM ---
	MVI	A, 0xc8
	ORA	H
	MOV	H, A
	;DEBUG_VALUE: draw_text:addr_base <- $hl
.LBB24_2:                               ; =>This Inner Loop Header: Depth=1
	;DEBUG_VALUE: draw_text:addr_base <- $hl
	;DEBUG_VALUE: draw_text:x <- 64
	;DEBUG_VALUE: draw_text:scr_addr_hi <- -64
	;DEBUG_VALUE: draw_text:addr_base <- $hl
	;DEBUG_VALUE: draw_text:text <- [DW_OP_constu 1, DW_OP_minus, DW_OP_stack_value] $bc
	;--- V6C_SPILL16 ---
	PUSH	H
	MOV	L, C
	MOV	H, B
	SHLD	.LLo61_8+1
	POP	H
	;--- V6C_BUILD_PAIR ---
	MVI	D, 0
	;--- V6C_SHL16_DAD ---
	XCHG
	DAD	H
	DAD	H
	DAD	H
	LXI	B, __font-256
	;DEBUG_VALUE: draw_text:text <- [DW_OP_constu 1, DW_OP_minus, DW_OP_stack_value] $bc
	;--- V6C_ADD16 ---
	DAD	B
	XCHG
	;DEBUG_VALUE: char_data <- $de
	;DEBUG_VALUE: draw_text:text <- [DW_OP_deref_size 0, DW_OP_constu 1, DW_OP_minus, DW_OP_stack_value] $sp
	CALL	memcpy
	;--- V6C_RELOAD16 ---
.LLo61_8:
	LXI	B, 0
	;DEBUG_VALUE: draw_text:text <- [DW_OP_constu 1, DW_OP_minus, DW_OP_stack_value] $bc
	LXI	D, 0x100
	;--- V6C_ADD16 ---
	DAD	D
	;--- V6C_LOAD8_P ---
	LDAX	B
	MOV	E, A
	;DEBUG_VALUE: draw_text:addr_base <- $hl
	;--- V6C_INX16 ---
	INX	B
	;DEBUG_VALUE: draw_text:c <- $e
	;DEBUG_VALUE: draw_text:text <- $bc
	;--- V6C_CMP8_ZERO ---
	XRA	A
	CMP	E
	;--- V6C_BRCOND ---
	JNZ	.LBB24_2
; %bb.3:
	;DEBUG_VALUE: draw_text:addr_base <- $hl
	;DEBUG_VALUE: draw_text:c <- $e
	;DEBUG_VALUE: draw_text:text <- $bc
	;DEBUG_VALUE: draw_text:x <- 64
	;DEBUG_VALUE: draw_text:scr_addr_hi <- -64
	RET
.Lfunc_end8:
                                        ; -- End function
	.section	.text.fill_rect,"ax",@progbits
fill_rect:                              ; -- Begin function fill_rect
                                        ; @fill_rect
.Lfunc_begin9:
	;=== void fill_rect(char x, char y, char width, char scr_addr_hi) ===
	;  x = A
	;  y = B
	;  width = C
	;  scr_addr_hi = D
	;  [folded: height=32]
; %bb.0:
	;DEBUG_VALUE: fill_rect:x <- $a
	;DEBUG_VALUE: fill_rect:y <- $b
	;DEBUG_VALUE: fill_rect:width <- $c
	;DEBUG_VALUE: fill_rect:scr_addr_hi <- $d
	;--- V6C_SPILL8 ---
	LXI	H, .LLo61_15+1
	MOV	M, D
	;DEBUG_VALUE: fill_rect:scr_addr_hi <- [$sp+0]
	;--- V6C_SPILL8 ---
	LXI	H, .LLo61_17+1
	MOV	M, B
	;DEBUG_VALUE: fill_rect:y <- [$sp+0]
	MOV	L, A
	;DEBUG_VALUE: fill_rect:height <- 32
	;DEBUG_VALUE: fill_rect:x <- $l
	;--- V6C_BUILD_PAIR ---
	MVI	D, 0
	MOV	E, C
	MOV	H, D
	LXI	B, 7
	;--- V6C_ADD16 ---
	XCHG
	DAD	B
	;--- V6C_SPILL16 ---
	SHLD	.LLo61_13+1
	XCHG
	;--- V6C_BUILD_PAIR ---
	;--- V6C_ADD16 ---
	PUSH	H
	DAD	D
	MOV	C, L
	;--- V6C_AND16_IMM ---
	MVI	A, 7
	ANA	C
	LXI	D, REQ_BIT_MASK_R
	;--- V6C_DAD ---
	MOV	H, B
	MOV	L, A
	DAD	D
	XCHG
	POP	H
	;--- V6C_SPILL16 ---
	XCHG
	SHLD	.LLo61_10+1
	XCHG
	MOV	E, L
	;--- V6C_AND16_IMM ---
	MVI	A, 7
	ANA	E
	MOV	E, A
	MOV	D, B
	;--- V6C_RELOAD16 ---
.LLo61_13:
	LXI	B, 0
	;--- V6C_ADD16 ---
	MOV	A, C
	ADD	E
	MOV	C, A
	MOV	A, B
	ADC	D
	;--- V6C_SPILL16 ---
	PUSH	H
	MOV	L, C
	MOV	H, A
	SHLD	.LLo61_13+1
	LXI	B, REQ_BIT_MASK_L
	;--- V6C_DAD ---
	XCHG
	DAD	B
	XCHG
	POP	H
	;--- V6C_SPILL16 ---
	XCHG
	SHLD	.LLo61_11+1
	XCHG
	;--- V6C_RELOAD8 ---
	LDA	.LLo61_17+1
	;DEBUG_VALUE: fill_rect:y <- $a
	;--- V6C_BUILD_PAIR ---
	MVI	D, 0
	MOV	E, A
	;--- V6C_RELOAD8 ---
.LLo61_15:
	MVI	A, 0
	;DEBUG_VALUE: fill_rect:scr_addr_hi <- $a
	;--- V6C_BUILD_PAIR ---
	;--- V6C_SHL16_BYTE ---
	MOV	B, A
	MOV	C, D
	;--- V6C_SHL16_DAD ---
	DAD	H
	DAD	H
	DAD	H
	DAD	H
	DAD	H
	;--- V6C_AND16_IMM ---
	MOV	L, C
	MVI	A, 0x1f
	ANA	H
	MOV	H, A
	;--- V6C_SPILL16 ---
	PUSH	H
	MOV	H, B
	SHLD	.LLo61_12+1
	POP	H
	;--- V6C_SPILL16 ---
	SHLD	.LLo61_14+1
	;--- V6C_ADD16 ---
	DAD	B
	;--- V6C_SPILL16 ---
	XCHG
	SHLD	.LLo61_9+1
	XCHG
	;--- V6C_OR16 ---
	MOV	A, L
	ORA	E
	MOV	L, A
	MOV	A, H
	ORA	D
	MOV	H, A
	;DEBUG_VALUE: fill_rect:addr_base <- $hl
	;--- V6C_RELOAD16 ---
.LLo61_11:
	LXI	D, 0
	;--- V6C_LOAD8_P ---
	LDAX	D
	MOV	E, A
	;DEBUG_VALUE: fill_rect:fill_bits_l <- $e
	;--- V6C_RELOAD16 ---
	PUSH	H
	LHLD	.LLo61_10+1
	MOV	C, L
	MOV	B, H
	;--- V6C_LOAD8_P ---
	LDAX	B
	MOV	D, A
	;DEBUG_VALUE: fill_rect:fill_bits_r <- $d
	;--- V6C_RELOAD16 ---
	LHLD	.LLo61_13+1
	MOV	B, H
	;--- V6C_SRL16_24BIT ---
	XRA	A
	DAD	H
	ADC	A
	DAD	H
	ADC	A
	DAD	H
	ADC	A
	DAD	H
	ADC	A
	DAD	H
	ADC	A
	MOV	C, H
	MOV	B, A
	POP	H
	;DEBUG_VALUE: fill_rect:total_cols <- $bc
	;--- V6C_BR_CC16_IMM ---
	MVI	A, 1
	CMP	C
	JNZ	.LBB25_1
; %bb.7:
	;DEBUG_VALUE: fill_rect:total_cols <- $bc
	;DEBUG_VALUE: fill_rect:fill_bits_r <- $d
	;DEBUG_VALUE: fill_rect:fill_bits_l <- $e
	;DEBUG_VALUE: fill_rect:height <- 32
	XRA	A
	CMP	B
	JZ	.LBB25_5
.LBB25_1:
	;DEBUG_VALUE: fill_rect:total_cols <- $bc
	;DEBUG_VALUE: fill_rect:fill_bits_r <- $d
	;DEBUG_VALUE: fill_rect:fill_bits_l <- $e
	;DEBUG_VALUE: fill_rect:height <- 32
	;--- V6C_SPILL8 ---
	MOV	A, D
	STA	.LLo61_16+1
	;--- V6C_BUILD_PAIR ---
	MVI	D, 0
	;--- V6C_SPILL16 ---
	SHLD	.LLo61_13+1
	;--- V6C_SPILL16 ---
	PUSH	H
	MOV	L, C
	MOV	H, B
	SHLD	.LLo61_10+1
	POP	H
	LXI	B, 0x20
	CALL	memset
	;--- V6C_RELOAD16 ---
	LHLD	.LLo61_10+1
	XCHG
	;DEBUG_VALUE: i <- 1
	;--- V6C_DCX16 ---
	DCX	D
	MOV	A, E
	ANI	0xfe
	;--- V6C_BRCOND ---
	JZ	.LBB25_2
; %bb.3:
	;DEBUG_VALUE: i <- 1
	;DEBUG_VALUE: fill_rect:height <- 32
	;--- V6C_RELOAD16 ---
.LLo61_12:
	LXI	H, 0
	;--- V6C_RELOAD16 ---
.LLo61_14:
	LXI	B, 0
	;--- V6C_ADD16 ---
	DAD	B
	;--- V6C_RELOAD16 ---
	PUSH	H
	LHLD	.LLo61_9+1
	MOV	C, L
	MOV	B, H
	POP	H
	;--- V6C_ADD16 ---
	DAD	B
	LXI	B, 0x100
	;--- V6C_ADD16 ---
	DAD	B
	MOV	A, B
	;--- V6C_SPILL16 ---
	XCHG
	SHLD	.LLo61_10+1
	XCHG
.LBB25_4:                               ; =>This Inner Loop Header: Depth=1
	;DEBUG_VALUE: fill_rect:height <- 32
	;DEBUG_VALUE: i <- $a
	;--- V6C_SPILL8 ---
	STA	.LLo61_17+1
	;--- V6C_SPILL16 ---
	SHLD	.LLo61_9+1
	;--- V6C_RELOAD16 ---
	LHLD	.LLo61_9+1
	LXI	D, 0xff
	LXI	B, 0x20
	;DEBUG_VALUE: i <- [$sp+0]
	CALL	memset
	;--- V6C_RELOAD16 ---
.LLo61_10:
	LXI	D, 0
	LXI	H, 0x100
	;--- V6C_RELOAD16 ---
.LLo61_9:
	LXI	B, 0
	;--- V6C_ADD16 ---
	DAD	B
	MOV	C, L
	;--- V6C_RELOAD8 ---
.LLo61_17:
	MVI	A, 0
	;DEBUG_VALUE: i <- $a
	;--- V6C_SPILL16 ---
	SHLD	.LLo61_9+1
	;--- V6C_RELOAD16 ---
	LHLD	.LLo61_9+1
	INR	A
	;DEBUG_VALUE: i <- $a
	CMP	E
	;--- V6C_BRCOND ---
	JC	.LBB25_4
.LBB25_2:
	;DEBUG_VALUE: fill_rect:height <- 32
	;--- V6C_SHL16_BYTE ---
	MOV	D, E
	MVI	E, 0
	;--- V6C_RELOAD16 ---
	LHLD	.LLo61_13+1
	;--- V6C_ADD16 ---
	DAD	D
	;--- V6C_RELOAD8 ---
.LLo61_16:
	MVI	E, 0
	JMP	.LBB25_6
.LBB25_5:
	;DEBUG_VALUE: fill_rect:total_cols <- $bc
	;DEBUG_VALUE: fill_rect:fill_bits_r <- $d
	;DEBUG_VALUE: fill_rect:fill_bits_l <- $e
	;DEBUG_VALUE: fill_rect:height <- 32
	MOV	A, D
	ANA	E
	MOV	E, A
.LBB25_6:
	;DEBUG_VALUE: fill_rect:height <- 32
	;--- V6C_BUILD_PAIR ---
	MVI	D, 0
	LXI	B, 0x20
	JMP	memset
.Lfunc_end9:
                                        ; -- End function
	.section	.text.main,"ax",@progbits
	.globl	main                            ; -- Begin function main
main:                                   ; @main
.Lfunc_begin10:
	;=== void main(void) ===
; %bb.0:
	LXI	H, 0xfff8
	DAD	SP
	SPHL
	CALL	v6c_set_empty_interrupt_handler
	;APP
	EI

	;NO_APP
	LXI	H, 0x8000
	LXI	D, 0
	LXI	B, 0x8000
	CALL	memset
	MVI	A, 0x64
	;DEBUG_VALUE: i <- 0
.LBB26_1:                               ; =>This Inner Loop Header: Depth=1
	;DEBUG_VALUE: i <- undef
	;--- V6C_SPILL8 ---
	LXI	H, 6
	DAD	SP
	MOV	M, A
	CALL	rand
	;DEBUG_VALUE: r1 <- $hl
	;DEBUG_VALUE: x1 <- $l
	;--- V6C_SRL16_BYTE ---
	;DEBUG_VALUE: y1 <- $e
	MOV	A, L
	MOV	B, H
	CALL	draw_line
	;--- V6C_RELOAD8 ---
	LXI	H, 6
	DAD	SP
	MOV	A, M
	DCR	A
	;--- V6C_BRCOND ---
	JNZ	.LBB26_1
; %bb.2:
	MVI	H, 0xa
	MVI	A, 0x64
.LBB26_3:                               ; =>This Inner Loop Header: Depth=1
	;DEBUG_VALUE: i <- undef
	;--- V6C_SPILL8 ---
	PUSH	H
	LXI	H, 8
	DAD	SP
	MOV	M, A
	POP	H
	;--- V6C_SPILL8 ---
	XCHG
	LXI	H, 5
	DAD	SP
	MOV	M, D
	XCHG
	;--- V6C_RELOAD8 ---
	PUSH	H
	LXI	H, 8
	DAD	SP
	MOV	A, M
	POP	H
	CALL	draw_circle
	;--- V6C_RELOAD8 ---
	MOV	D, L
	LXI	H, 5
	DAD	SP
	MOV	H, M
	MOV	L, D
	;--- V6C_RELOAD8 ---
	PUSH	H
	LXI	H, 8
	DAD	SP
	MOV	A, M
	POP	H
	ADI	0xf6
	DCR	H
	;--- V6C_BRCOND ---
	JNZ	.LBB26_3
; %bb.4:
	XRA	A
	LXI	H, 0
.LBB26_5:                               ; =>This Loop Header: Depth=1
                                        ;     Child Loop BB26_6 Depth 2
	;DEBUG_VALUE: i <- $a
	;DEBUG_VALUE: x <- 0
	MOV	D, A
	;DEBUG_VALUE: i <- $d
	ADI	0x7f
	;--- V6C_SPILL8 ---
	PUSH	H
	LXI	H, 4
	DAD	SP
	MOV	M, A
	;--- V6C_SPILL8 ---
	LXI	H, 2
	DAD	SP
	MOV	M, D
	;DEBUG_VALUE: i <- [$sp+0]
	MOV	A, D
	ADD	A
	ADD	A
	ADD	A
	ADD	A
	ADD	A
	ORI	0x80
	;--- V6C_SPILL8 ---
	LXI	H, 3
	DAD	SP
	MOV	M, A
	POP	H
	MVI	E, 0
	LXI	B, 0
	;--- V6C_SPILL16 ---
	PUSH	D
	XCHG
	LXI	H, 8
	DAD	SP
	MOV	M, E
	INX	H
	MOV	M, D
	POP	D
.LBB26_6:                               ;   Parent Loop BB26_5 Depth=1
                                        ; =>  This Inner Loop Header: Depth=2
	;DEBUG_VALUE: x <- $bc
	;--- V6C_SPILL16 ---
	LXI	H, 3
	DAD	SP
	MOV	M, C
	INX	H
	MOV	M, B
	;--- V6C_SPILL8 ---
	LXI	H, 5
	DAD	SP
	MOV	M, E
	;--- V6C_RELOAD16 ---
	LXI	H, 6
	DAD	SP
	MOV	E, M
	INX	H
	MOV	D, M
	XCHG
	;--- V6C_ADD16 ---
	DAD	B
	;DEBUG_VALUE: x <- [DW_OP_plus_uconst 3] [$sp+0]
	CALL	sin8
	;--- V6C_SRA16_RAM_LO ---
	MOV	A, H
	RLC
	SBB	A
	;--- V6C_SRL16_RAM_LO ---
	RLC
	RLC
	ANI	3
	MOV	E, A
	MVI	D, 0
	;--- V6C_ADD16 ---
	DAD	D
	;--- V6C_RELOAD8 ---
	PUSH	H
	LXI	H, 7
	DAD	SP
	MOV	E, M
	POP	H
	;--- V6C_SRL16_RAR ---
	MOV	A, H
	ORA	A
	RAR
	MOV	H, A
	MOV	A, L
	RAR
	MOV	L, A
	MOV	A, H
	ORA	A
	RAR
	MOV	A, L
	RAR
	MOV	L, A
                                        ; kill: def $l killed $l killed $hl
	;--- V6C_RELOAD8 ---
	PUSH	D
	MOV	D, L
	LXI	H, 4
	DAD	SP
	MOV	H, M
	MOV	A, D
	POP	D
	ADD	H
	;DEBUG_VALUE: y <- $a
	MOV	B, A
	;DEBUG_VALUE: y <- $b
	MOV	A, E
	;--- V6C_RELOAD8 ---
	LXI	H, 1
	DAD	SP
	MOV	C, M
	CALL	draw_pixel
	;--- V6C_RELOAD16 ---
	LXI	H, 3
	DAD	SP
	MOV	C, M
	INX	H
	MOV	B, M
	;DEBUG_VALUE: x <- $bc
	;--- V6C_RELOAD16 ---
	PUSH	D
	LXI	H, 8
	DAD	SP
	MOV	E, M
	INX	H
	MOV	D, M
	POP	D
	INR	E
	;--- V6C_INX16 ---
	INX	B
	;DEBUG_VALUE: x <- $bc
	;--- V6C_BR_CC16_IMM ---
	XRA	A
	CMP	C
	JNZ	.LBB26_6
; %bb.11:                               ;   in Loop: Header=BB26_6 Depth=2
	;DEBUG_VALUE: x <- $bc
	INR	A
	CMP	B
	JNZ	.LBB26_6
; %bb.7:                                ;   in Loop: Header=BB26_5 Depth=1
	;--- V6C_INX16 ---
	INX	H
	;--- V6C_RELOAD8 ---
	PUSH	H
	LXI	H, 2
	DAD	SP
	MOV	A, M
	POP	H
	INR	A
	;DEBUG_VALUE: i <- $a
	CPI	0xb
	;--- V6C_BRCOND ---
	JNZ	.LBB26_5
; %bb.9:
	;DEBUG_VALUE: i <- $a
	MVI	D, 3
	MVI	A, 0x3c
	MVI	H, 0x80
	MVI	E, 0x28
.LBB26_10:                              ; =>This Inner Loop Header: Depth=1
	;DEBUG_VALUE: i <- undef
	;--- V6C_SPILL8 ---
	PUSH	H
	LXI	H, 7
	DAD	SP
	MOV	M, D
	;--- V6C_SPILL8 ---
	LXI	H, 8
	DAD	SP
	MOV	M, A
	ADI	0x8c
	MOV	C, A
	MOV	A, E
	;--- V6C_SPILL8 ---
	LXI	H, 4
	DAD	SP
	MOV	M, A
	;--- V6C_RELOAD8 ---
	LXI	H, 8
	DAD	SP
	MOV	B, M
	POP	H
	MOV	D, H
	;--- V6C_SPILL8 ---
	PUSH	H
	LXI	H, 5
	DAD	SP
	MOV	M, D
	POP	H
	CALL	fill_rect
	;--- V6C_RELOAD8 ---
	PUSH	H
	LXI	H, 7
	DAD	SP
	MOV	D, M
	;--- V6C_RELOAD8 ---
	LXI	H, 4
	DAD	SP
	MOV	A, M
	ADI	0xfc
	MOV	E, A
	;--- V6C_RELOAD8 ---
	LXI	H, 5
	DAD	SP
	MOV	A, M
	POP	H
	ADI	0x20
	MOV	H, A
	;--- V6C_RELOAD8 ---
	PUSH	H
	LXI	H, 8
	DAD	SP
	MOV	A, M
	POP	H
	ADI	0xf8
	DCR	D
	;--- V6C_BRCOND ---
	JNZ	.LBB26_10
; %bb.8:
	LXI	H, .str
	MVI	A, 0xf0
	CALL	draw_text
	LXI	H, .str.1
	MVI	A, 0xe4
	CALL	draw_text
	LXI	H, .str.2
	MVI	A, 0xd8
	CALL	draw_text
	LXI	H, .str.3
	MVI	A, 0xcc
	CALL	draw_text
	LXI	H, 8
	DAD	SP
	SPHL
	RET
.Lfunc_end10:
                                        ; -- End function
	.section	.text.v6c_empty_interrupt_handler,"ax",@progbits
v6c_empty_interrupt_handler:            ; -- Begin function v6c_empty_interrupt_handler
                                        ; @v6c_empty_interrupt_handler
.Lfunc_begin11:
	;=== void v6c_empty_interrupt_handler(void) ===
; %bb.0:
	;APP
	EI

	;NO_APP
	RET
.Lfunc_end11:
                                        ; -- End function
	.data
	.globl	__v6c_rand_state                ; @__v6c_rand_state
__v6c_rand_state:
	DW	1                               ; 0x1

	.section	.rodata,"a",@progbits
__font:                                 ; @__font
	.ascii	"\b\000\b\b\b\b\b\b"
	.ascii	"\000\000\000\000\000$$$"
	.ascii	"\000$$~$~$$"
	.ascii	"\b>H<\022|\b\000"
	.ascii	"bd\b\020&F\000\000"
	.ascii	"4JD8DJ4\000"
	.ascii	"\000\000\000\000\000\b\b\b"
	.ascii	"\004\b\020\020\020\b\004\000"
	.ascii	"\020\b\004\004\004\b\020\000"
	.ascii	"\000\b*\034*\b\000\000"
	.ascii	"\000\b\b>\b\b\000\000"
	.ascii	"\020\b\b\000\000\000\000\000"
	.ascii	"\000\000\000>\000\000\000\000"
	.ascii	"\b\000\000\000\000\000\000\000"
	.ascii	"\002\004\b\020 @\000\000"
	.ascii	"<BFJRbB<"
	.ascii	">\b\b\b\b\030\b\b"
	.ascii	"~@ \020\b\004B<"
	.ascii	"<B\002\034\002\002B<"
	.ascii	"\004\004~D$\024\f\f"
	.ascii	"<B\002\002|@@~"
	.ascii	"<BB|@@B<"
	.ascii	"  \020\b\004\002\002~"
	.ascii	"<BB<BBB<"
	.ascii	"<B\002\002>BB<"
	.ascii	"\000\000\030\030\000\030\030\000"
	.ascii	"\020\b\030\030\000\030\030\000"
	.ascii	"\004\b\020 \020\b\004\000"
	.ascii	"\000\000~\000~\000\000\000"
	.ascii	"\020\b\004\002\004\b\020\000"
	.ascii	"\b\000\b\004\002!!\036"
	.ascii	"<@^R^BB<"
	.ascii	"BB~BB$$\030"
	.ascii	"|BB|BBB|"
	.ascii	"<B@@@@B<"
	.ascii	"xDBBBBDx"
	.ascii	"~@@|@@@~"
	.ascii	"@@@|@@@~"
	.ascii	"<BFB@@B<"
	.ascii	"BBB~BBBB"
	.ascii	"<\b\b\b\b\b\b<"
	.ascii	"0H\b\b\b\b\b\036"
	.ascii	"BDHpHDBB"
	.ascii	"~@@@@@@@"
	.ascii	"BBBBZfBB"
	.ascii	"BBFJRbBB"
	.ascii	"<BBBBBB<"
	.ascii	"@@@|BBB|"
	.ascii	":DJBBBB<"
	.ascii	"BDH|BBB|"
	.ascii	"<B\002<@BB<"
	.ascii	"\b\b\b\b\b\b\b~"
	.ascii	"<BBBBBBB"
	.ascii	"\030$$BBBBB"
	.ascii	"BBfZBBBB"
	.ascii	"BB$\030\030$BB"
	.ascii	"\b\b\b\030$BBB"
	.ascii	"~@ \020\b\004\002~"

	.data
	.globl	__font_ptr                      ; @__font_ptr
__font_ptr:
	DW	__font

	.section	.rodata.str1.1,"aMS",@progbits,1
.str:                                   ; @.str
	.ascii	" !\"#$%&'()*+,-./\000"

.str.1:                                 ; @.str.1
	.ascii	"0123456789:;<=>?\000"

.str.2:                                 ; @.str.2
	.ascii	"@ABCDEFGHIJKLMNO\000"

.str.3:                                 ; @.str.3
	.ascii	"PQRSTUVWXYZ\000"

	.section	.rodata,"a",@progbits
BIT_MASK:                               ; @BIT_MASK
	.ascii	"\200@ \020\b\004\002\001"

sin_q_lut:                              ; @sin_q_lut
	DW	0                               ; 0x0
	DW	4                               ; 0x4
	DW	9                               ; 0x9
	DW	13                              ; 0xd
	DW	18                              ; 0x12
	DW	22                              ; 0x16
	DW	27                              ; 0x1b
	DW	31                              ; 0x1f
	DW	36                              ; 0x24
	DW	40                              ; 0x28
	DW	44                              ; 0x2c
	DW	49                              ; 0x31
	DW	53                              ; 0x35
	DW	58                              ; 0x3a
	DW	62                              ; 0x3e
	DW	66                              ; 0x42
	DW	71                              ; 0x47
	DW	75                              ; 0x4b
	DW	79                              ; 0x4f
	DW	83                              ; 0x53
	DW	88                              ; 0x58
	DW	92                              ; 0x5c
	DW	96                              ; 0x60
	DW	100                             ; 0x64
	DW	104                             ; 0x68
	DW	108                             ; 0x6c
	DW	112                             ; 0x70
	DW	116                             ; 0x74
	DW	120                             ; 0x78
	DW	124                             ; 0x7c
	DW	128                             ; 0x80
	DW	132                             ; 0x84
	DW	136                             ; 0x88
	DW	139                             ; 0x8b
	DW	143                             ; 0x8f
	DW	147                             ; 0x93
	DW	150                             ; 0x96
	DW	154                             ; 0x9a
	DW	158                             ; 0x9e
	DW	161                             ; 0xa1
	DW	165                             ; 0xa5
	DW	168                             ; 0xa8
	DW	171                             ; 0xab
	DW	175                             ; 0xaf
	DW	178                             ; 0xb2
	DW	181                             ; 0xb5
	DW	184                             ; 0xb8
	DW	187                             ; 0xbb
	DW	190                             ; 0xbe
	DW	193                             ; 0xc1
	DW	196                             ; 0xc4
	DW	199                             ; 0xc7
	DW	202                             ; 0xca
	DW	204                             ; 0xcc
	DW	207                             ; 0xcf
	DW	210                             ; 0xd2
	DW	212                             ; 0xd4
	DW	215                             ; 0xd7
	DW	217                             ; 0xd9
	DW	219                             ; 0xdb
	DW	222                             ; 0xde
	DW	224                             ; 0xe0
	DW	226                             ; 0xe2
	DW	228                             ; 0xe4
	DW	230                             ; 0xe6
	DW	232                             ; 0xe8
	DW	234                             ; 0xea
	DW	236                             ; 0xec
	DW	237                             ; 0xed
	DW	239                             ; 0xef
	DW	241                             ; 0xf1
	DW	242                             ; 0xf2
	DW	243                             ; 0xf3
	DW	245                             ; 0xf5
	DW	246                             ; 0xf6
	DW	247                             ; 0xf7
	DW	248                             ; 0xf8
	DW	249                             ; 0xf9
	DW	250                             ; 0xfa
	DW	251                             ; 0xfb
	DW	252                             ; 0xfc
	DW	253                             ; 0xfd
	DW	254                             ; 0xfe
	DW	254                             ; 0xfe
	DW	255                             ; 0xff
	DW	255                             ; 0xff
	DW	255                             ; 0xff
	DW	256                             ; 0x100
	DW	256                             ; 0x100
	DW	256                             ; 0x100
	DW	256                             ; 0x100

	.section	.rodata.cst8,"aM",@progbits,8
REQ_BIT_MASK_L:                         ; @REQ_BIT_MASK_L
	.ascii	"\377\177?\037\017\007\003\001"

REQ_BIT_MASK_R:                         ; @REQ_BIT_MASK_R
	.ascii	"\200\300\340\360\370\374\376\377"

	.local	__v6c_ss.memset                 ; @__v6c_ss.memset
	.comm	__v6c_ss.memset,4,1
	.local	__v6c_ss.draw_circle            ; @__v6c_ss.draw_circle
	.comm	__v6c_ss.draw_circle,4,1
	.local	__v6c_ss.draw_text              ; @__v6c_ss.draw_text
	.comm	__v6c_ss.draw_text,2,1
	.local	__v6c_ss.fill_rect              ; @__v6c_ss.fill_rect
	.comm	__v6c_ss.fill_rect,4,1
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
	.addrsig_sym v6c_interrupt
	.addrsig_sym v6c_empty_interrupt_handler
	.addrsig_sym __font
	.addrsig_sym BIT_MASK
	.addrsig_sym sin_q_lut
