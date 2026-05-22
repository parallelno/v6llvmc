	.text
	.section	.text.rand,"ax",@progbits
rand:                                   ; -- Begin function rand
                                        ; @rand
.Lfunc_begin0:
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
	;DEBUG_VALUE: rand:__r <- $hl
	RET
.Lfunc_end0:
                                        ; -- End function
	.section	.text.draw_pixel,"ax",@progbits
draw_pixel:                             ; -- Begin function draw_pixel
                                        ; @draw_pixel
.Lfunc_begin1:
	;=== void draw_pixel(char x, char y) ===
	;  x = A
	;  y = B
	;  [folded: plane_addr=0x8000]
; %bb.0:
	;DEBUG_VALUE: draw_pixel:x <- $a
	;DEBUG_VALUE: draw_pixel:y <- $b
	;DEBUG_VALUE: draw_pixel:plane_addr <- -32768
	;DEBUG_VALUE: draw_pixel:addr_x_reg <- $a
	;DEBUG_VALUE: draw_pixel:addr_y_reg <- $b
	;DEBUG_VALUE: draw_pixel:addr_reg <- -128
	MVI	H, 0x80
	MOV	L, B
	;DEBUG_VALUE: draw_pixel:addr_y_reg <- $l
	;DEBUG_VALUE: draw_pixel:y <- $l
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
.Lfunc_end1:
                                        ; -- End function
	.section	.text.draw_line,"ax",@progbits
draw_line:                              ; -- Begin function draw_line
                                        ; @draw_line
.Lfunc_begin2:
	;=== void draw_line(char x1, char y1) ===
	;  x1 = A
	;  y1 = B
	;  [folded: x0=127, y0=127, plane_addr=0x8000]
; %bb.0:
	;DEBUG_VALUE: draw_line:x1 <- $a
	;DEBUG_VALUE: draw_line:y1 <- $b
	;--- V6C_SPILL8 ---
	LXI	H, .LLo61_1+1
	MOV	M, B
	;DEBUG_VALUE: draw_line:plane_addr <- -32768
	;DEBUG_VALUE: draw_line:y0 <- 127
	;DEBUG_VALUE: draw_line:x0 <- 127
	;DEBUG_VALUE: draw_line:y1 <- [$sp+0]
	;--- V6C_SPILL8 ---
	STA	.LLo61_4+1
	;DEBUG_VALUE: draw_line:x1 <- [$sp+0]
	CPI	0x7f
	;--- V6C_BRCOND ---
	JNC	.LBB17_1
.LBB17_13:
	;DEBUG_VALUE: draw_line:plane_addr <- -32768
	RET
.LBB17_1:
	;DEBUG_VALUE: draw_line:x1 <- [$sp+0]
	;DEBUG_VALUE: draw_line:y1 <- [$sp+0]
	;DEBUG_VALUE: draw_line:x0 <- 127
	;DEBUG_VALUE: draw_line:y0 <- 127
	;DEBUG_VALUE: draw_line:plane_addr <- -32768
	;--- V6C_RELOAD8 ---
	LXI	H, .LLo61_1+1
	MOV	L, M
	;--- V6C_CMP8_ZERO ---
	XRA	A
	CMP	L
	JP	.LBB17_2
; %bb.3:
	;DEBUG_VALUE: draw_line:x1 <- [$sp+0]
	;DEBUG_VALUE: draw_line:y1 <- [$sp+0]
	;DEBUG_VALUE: draw_line:x0 <- 127
	;DEBUG_VALUE: draw_line:y0 <- 127
	;DEBUG_VALUE: draw_line:plane_addr <- -32768
	;--- V6C_RELOAD8 ---
	LDA	.LLo61_1+1
	ADI	0x81
	JMP	.LBB17_4
.LBB17_2:
	;DEBUG_VALUE: draw_line:x1 <- [$sp+0]
	;DEBUG_VALUE: draw_line:y1 <- [$sp+0]
	;DEBUG_VALUE: draw_line:x0 <- 127
	;DEBUG_VALUE: draw_line:y0 <- 127
	;DEBUG_VALUE: draw_line:plane_addr <- -32768
	;--- V6C_RELOAD8 ---
	LDA	.LLo61_1+1
	XRI	0x7f
.LBB17_4:
	;DEBUG_VALUE: draw_line:x1 <- [$sp+0]
	;DEBUG_VALUE: draw_line:y1 <- [$sp+0]
	;DEBUG_VALUE: draw_line:x0 <- 127
	;DEBUG_VALUE: draw_line:y0 <- 127
	;DEBUG_VALUE: draw_line:plane_addr <- -32768
	;--- V6C_SPILL8 ---
	STA	.LLo61_2+1
	;DEBUG_VALUE: draw_line:dy <- [$sp+0]
	;DEBUG_VALUE: draw_line:dx <- undef
	;--- V6C_RELOAD8 ---
	LDA	.LLo61_1+1
	CPI	0x7f
	;--- V6C_BRCOND ---
	RC
.LBB17_5:
	;DEBUG_VALUE: draw_line:x0 <- 127
	;DEBUG_VALUE: draw_line:y0 <- 127
	;DEBUG_VALUE: draw_line:plane_addr <- -32768
	;--- V6C_RELOAD8 ---
	LDA	.LLo61_4+1
	ADI	0x81
	;DEBUG_VALUE: draw_line:dx <- $a
	MOV	L, A
	;DEBUG_VALUE: draw_line:dx <- $l
	;--- V6C_RELOAD8 ---
	MOV	B, A
	LDA	.LLo61_2+1
	MOV	H, A
	MOV	A, B
	;--- V6C_SPILL8 ---
	MOV	A, L
	STA	.LLo61_5+1
	MOV	A, B
	;DEBUG_VALUE: draw_line:dx <- [$sp+0]
	CMP	H
	;--- V6C_BRCOND ---
	RC
.LBB17_6:
	;DEBUG_VALUE: draw_line:x0 <- 127
	;DEBUG_VALUE: draw_line:y0 <- 127
	;DEBUG_VALUE: draw_line:plane_addr <- -32768
	;DEBUG_VALUE: draw_line:x0 <- 127
	;DEBUG_VALUE: draw_line:y0 <- 127
	;DEBUG_VALUE: draw_line:err <- [$sp+0]
	MVI	A, 0x7f
	MOV	B, A
	CALL	draw_pixel
	;--- V6C_RELOAD8 ---
	LDA	.LLo61_1+1
	CPI	0x7f
	;--- V6C_BRCOND ---
	RZ
.LBB17_7:
	;DEBUG_VALUE: draw_line:x0 <- 127
	;DEBUG_VALUE: draw_line:y0 <- 127
	;DEBUG_VALUE: draw_line:plane_addr <- -32768
	;--- V6C_RELOAD8 ---
	LDA	.LLo61_4+1
	CPI	0x7f
	;--- V6C_BRCOND ---
	RZ
.LBB17_8:
	;DEBUG_VALUE: draw_line:x0 <- 127
	;DEBUG_VALUE: draw_line:y0 <- 127
	;DEBUG_VALUE: draw_line:plane_addr <- -32768
	MVI	A, 0x7f
	;--- V6C_SPILL8 ---
	STA	.LLo61_0+1
	MVI	E, 0x80
	;--- V6C_RELOAD8 ---
	LDA	.LLo61_5+1
.LBB17_9:                               ; =>This Inner Loop Header: Depth=1
	;DEBUG_VALUE: draw_line:plane_addr <- -32768
	;DEBUG_VALUE: draw_line:x0 <- $e
	;DEBUG_VALUE: draw_line:y0 <- [$sp+0]
	;DEBUG_VALUE: draw_line:err <- $l
	;--- V6C_RELOAD8 ---
	;DEBUG_VALUE: draw_line:err <- $a
.LLo61_2:
	SUI	0
	;DEBUG_VALUE: draw_line:err <- $a
	MOV	D, A
	;DEBUG_VALUE: draw_line:err <- $d
	MVI	L, 0
	XRA	A
	;--- V6C_SPILL8 ---
	STA	.LLo61_3+1
	;--- V6C_BUILD_PAIR ---
	MOV	H, L
	MOV	L, D
	;--- V6C_SRL16 ---
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
	MOV	H, A
	MOV	A, L
	RAR
	MOV	L, A
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
	MOV	H, A
	MOV	A, L
	RAR
	MOV	L, A
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
	MOV	H, A
	MOV	A, L
	RAR
	MOV	L, A
	MOV	A, H
	ORA	A
	RAR
	MOV	H, A
	MOV	A, L
	RAR
	MOV	L, A
                                        ; kill: def $l killed $l killed $hl
	;--- V6C_RELOAD8 ---
.LLo61_0:
	MVI	A, 0
	;DEBUG_VALUE: draw_line:y0 <- $a
	ADD	L
	;DEBUG_VALUE: draw_line:y0 <- $a
	MOV	B, A
	;DEBUG_VALUE: draw_line:y0 <- $b
	MOV	A, E
	;--- V6C_SPILL8 ---
	LXI	H, .LLo61_0+1
	MOV	M, B
	;DEBUG_VALUE: draw_line:y0 <- [$sp+0]
	CALL	draw_pixel
	MOV	H, D
	;DEBUG_VALUE: draw_line:err <- $h
	;--- V6C_CMP8_ZERO ---
	XRA	A
	CMP	D
	JP	.LBB17_11
; %bb.10:                               ;   in Loop: Header=BB17_9 Depth=1
	;DEBUG_VALUE: draw_line:err <- $h
	;DEBUG_VALUE: draw_line:y0 <- [$sp+0]
	;DEBUG_VALUE: draw_line:x0 <- $e
	;DEBUG_VALUE: draw_line:plane_addr <- -32768
	;--- V6C_RELOAD8 ---
.LLo61_5:
	MVI	A, 0
	;--- V6C_SPILL8 ---
	STA	.LLo61_3+1
.LBB17_11:                              ;   in Loop: Header=BB17_9 Depth=1
	;DEBUG_VALUE: draw_line:err <- $h
	;DEBUG_VALUE: draw_line:y0 <- [$sp+0]
	;DEBUG_VALUE: draw_line:x0 <- $e
	;DEBUG_VALUE: draw_line:plane_addr <- -32768
	;DEBUG_VALUE: draw_line:err <- undef
	;--- V6C_RELOAD8 ---
.LLo61_1:
	MVI	L, 0
	;--- V6C_RELOAD8 ---
	LDA	.LLo61_0+1
	CMP	L
	MOV	A, H
	;--- V6C_BRCOND ---
	RZ
.LBB17_12:                              ;   in Loop: Header=BB17_9 Depth=1
	;DEBUG_VALUE: draw_line:x0 <- $e
	;DEBUG_VALUE: draw_line:plane_addr <- -32768
	;--- V6C_RELOAD8 ---
.LLo61_3:
	ADI	0
	;DEBUG_VALUE: draw_line:err <- $a
	MOV	L, E
	INR	L
	MOV	H, A
	;DEBUG_VALUE: draw_line:err <- $h
	;--- V6C_RELOAD8 ---
.LLo61_4:
	MVI	A, 0
	CMP	E
	MOV	A, H
	;DEBUG_VALUE: draw_line:err <- $a
	MOV	E, L
	;--- V6C_BRCOND ---
	JNZ	.LBB17_9
	JMP	.LBB17_13
.Lfunc_end2:
                                        ; -- End function
	.section	.text.main,"ax",@progbits
	.globl	main                            ; -- Begin function main
main:                                   ; @main
.Lfunc_begin3:
	;=== void main(void) ===
; %bb.0:
	;DEBUG_VALUE: i <- 0
	MVI	A, 0x64
.LBB18_1:                               ; =>This Inner Loop Header: Depth=1
	;DEBUG_VALUE: i <- undef
	;--- V6C_SPILL8 ---
	STA	.LLo61_7+1
	CALL	rand
	;DEBUG_VALUE: lo <- [DW_OP_LLVM_convert 16 7, DW_OP_LLVM_convert 8 7, DW_OP_stack_value] $hl
	;DEBUG_VALUE: r <- $hl
	LXI	D, 0xff
	;--- V6C_AND16 ---
	MOV	A, L
	ANA	E
	MOV	E, A
	MOV	A, H
	ANA	D
	MOV	D, A
	;--- V6C_CMP16_IMM ---
	MVI	A, 0xf9
	SUB	E
	MVI	A, 0
	SBB	D
	LXI	B, 0xfa
	;--- V6C_SPILL16 ---
	PUSH	H
	MOV	L, C
	MOV	H, B
	SHLD	.LLo61_6+1
	POP	H
	JC	.LBB18_3
; %bb.2:                                ;   in Loop: Header=BB18_1 Depth=1
	;--- V6C_SPILL16 ---
	XCHG
	SHLD	.LLo61_6+1
	XCHG
.LBB18_3:                               ;   in Loop: Header=BB18_1 Depth=1
	;--- V6C_SRL16 ---
	MOV	L, H
	MVI	H, 0
	;DEBUG_VALUE: hi <- [DW_OP_LLVM_convert 16 7, DW_OP_LLVM_convert 8 7, DW_OP_stack_value] $hl
	;--- V6C_CMP16_IMM ---
	MVI	A, 0xf9
	SUB	L
	MOV	A, H
	SBB	H
	;--- V6C_RELOAD8 ---
.LLo61_7:
	MVI	A, 0
	LXI	D, 0xfa
	JC	.LBB18_5
; %bb.4:                                ;   in Loop: Header=BB18_1 Depth=1
	;DEBUG_VALUE: hi <- [DW_OP_LLVM_convert 16 7, DW_OP_LLVM_convert 8 7, DW_OP_stack_value] $hl
	XCHG
.LBB18_5:                               ;   in Loop: Header=BB18_1 Depth=1
	MOV	A, E
	ADI	3
	;DEBUG_VALUE: x <- $a
	MOV	E, A
	;DEBUG_VALUE: x <- $e
	;--- V6C_RELOAD16 ---
.LLo61_6:
	LXI	H, 0
	MOV	A, L
	ADI	3
	;DEBUG_VALUE: y <- $a
	MOV	B, A
	;DEBUG_VALUE: y <- $b
	MOV	A, E
	CALL	draw_line
	;DEBUG_VALUE: i <- undef
	;--- V6C_RELOAD8 ---
	LDA	.LLo61_7+1
	DCR	A
	;--- V6C_BRCOND ---
	JNZ	.LBB18_1
; %bb.6:
	RET
.Lfunc_end3:
                                        ; -- End function
	.data
	.globl	__v6c_rand_state                ; @__v6c_rand_state
__v6c_rand_state:
	DW	1                               ; 0x1

	.globl	font                            ; @font
font:
	.ascii	"\000\030$B~BB\000\000|B|BB|\000\000<B@@B<\000\000xDBBDx\000\000~@|@@~\000\000~@|@@@\000\000<B@NB<\000\000BB~BBB"

	.section	.rodata,"a",@progbits
	.globl	BIT_MASK                        ; @BIT_MASK
BIT_MASK:
	.ascii	"\200@ \020\b\004\002\001"

	.data
	.globl	palette                         ; @palette
palette:
	.ascii	"\000\021\"3DUfw\210\231\252\273\314\335\356\377"

	.section	.bss,"aw",@nobits
	.globl	test                            ; @test
test:
	DB	0                               ; 0x0

	.local	__v6c_ss.draw_line              ; @__v6c_ss.draw_line
	.comm	__v6c_ss.draw_line,5,1
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
