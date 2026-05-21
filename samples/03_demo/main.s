	.text
	.section	.text.memset,"ax",@progbits
memset:                                 ; -- Begin function memset
                                        ; @memset
.Lfunc_begin0:
	;=== void memset(void) ===
	;  [folded: dst=0x8000, val=0, n=0x8000]
; %bb.0:
	;DEBUG_VALUE: memset:dst <- -32768
	;DEBUG_VALUE: memset:val <- 0
	;DEBUG_VALUE: memset:n <- -32768
	;DEBUG_VALUE: i <- 0
	LXI	H, 0x8000
.LBB15_1:                               ; =>This Inner Loop Header: Depth=1
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
	JNZ	.LBB15_1
; %bb.2:
	;DEBUG_VALUE: memset:n <- -32768
	;DEBUG_VALUE: memset:val <- 0
	;DEBUG_VALUE: memset:dst <- -32768
	RET
.Lfunc_end0:
                                        ; -- End function
	.section	.text.v6c_set_palette,"ax",@progbits
v6c_set_palette:                        ; -- Begin function v6c_set_palette
                                        ; @v6c_set_palette
.Lfunc_begin1:
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
	;DEBUG_VALUE: rand:__r <- $hl
	RET
.Lfunc_end2:
                                        ; -- End function
	.section	.text.draw_pixel,"ax",@progbits
draw_pixel:                             ; -- Begin function draw_pixel
                                        ; @draw_pixel
.Lfunc_begin3:
	;=== void draw_pixel(char x, char y) ===
	;  x = A
	;  y = B
	;  [folded: plane_addr=0x8000]
; %bb.0:
	;DEBUG_VALUE: draw_pixel:x <- $a
	;DEBUG_VALUE: draw_pixel:y <- $b
	MOV	H, A
	;DEBUG_VALUE: draw_pixel:x <- $h
	MVI	L, 0
	;--- V6C_BUILD_PAIR ---
	MOV	D, L
	MOV	E, B
	;DEBUG_VALUE: draw_pixel:plane_addr <- -32768
	;--- V6C_BUILD_PAIR ---
	MOV	B, L
	MOV	C, H
	;--- V6C_SRL16 ---
	MOV	A, B
	ORA	A
	RAR
	MOV	B, A
	MOV	A, C
	RAR
	MOV	C, A
	MOV	A, B
	ORA	A
	RAR
	MOV	B, A
	MOV	A, C
	RAR
	MOV	C, A
	MOV	A, B
	ORA	A
	RAR
	MOV	B, A
	MOV	A, C
	RAR
	MOV	C, A
	;DEBUG_VALUE: draw_pixel:addr_hi <- $c
	;--- V6C_BUILD_PAIR ---
	MOV	B, C
	MOV	C, L
	;--- V6C_OR16 ---
	MOV	A, C
	ORA	E
	MOV	E, A
	MOV	A, B
	ORA	D
	MOV	D, A
	;DEBUG_VALUE: draw_pixel:byte_index <- $de
	LXI	B, 0x8000
	;--- V6C_OR16 ---
	MOV	A, E
	ORA	C
	MOV	C, A
	MOV	A, D
	ORA	B
	MOV	B, A
	MOV	A, H
	;DEBUG_VALUE: draw_pixel:x <- $a
	CMA
	ANI	7
	;DEBUG_VALUE: draw_pixel:bit_index <- $a
	;--- V6C_BUILD_PAIR ---
	MOV	D, L
	MOV	E, A
	LXI	H, 1
	CALL	__ashlhi3
	MOV	A, L
	;--- V6C_ORA_M_P ---
	MOV	L, C
	MOV	H, B
	ORA	M
	;--- V6C_STORE8_P ---
	STAX	B
	RET
.Lfunc_end3:
                                        ; -- End function
	.section	.text.draw_line,"ax",@progbits
draw_line:                              ; -- Begin function draw_line
                                        ; @draw_line
.Lfunc_begin4:
	;=== void draw_line(char x1, char y1) ===
	;  x1 = A
	;  y1 = B
	;  [folded: x0=127, y0=127, plane_addr=0x8000]
; %bb.0:
	;DEBUG_VALUE: draw_line:x1 <- $a
	;DEBUG_VALUE: draw_line:y1 <- $b
	;--- V6C_SPILL8 ---
	LXI	H, .LLo61_8+1
	MOV	M, B
	;DEBUG_VALUE: draw_line:plane_addr <- -32768
	;DEBUG_VALUE: draw_line:y0 <- 127
	;DEBUG_VALUE: draw_line:x0 <- 127
	;DEBUG_VALUE: draw_line:y1 <- [$sp+0]
	MVI	L, 0
	;--- V6C_BUILD_PAIR ---
	MOV	H, L
	MOV	L, A
	;--- V6C_SPILL8 ---
	STA	.LLo61_5+1
	;DEBUG_VALUE: draw_line:x1 <- [$sp+0]
	CPI	0x7f
	;--- V6C_BRCOND ---
	JNC	.LBB19_2
; %bb.1:
	;DEBUG_VALUE: draw_line:x1 <- [$sp+0]
	;DEBUG_VALUE: draw_line:y1 <- [$sp+0]
	;DEBUG_VALUE: draw_line:x0 <- 127
	;DEBUG_VALUE: draw_line:y0 <- 127
	;DEBUG_VALUE: draw_line:plane_addr <- -32768
	LXI	D, 0x7f
	;--- V6C_XOR16 ---
	MOV	A, L
	XRA	E
	MOV	L, A
	MOV	A, H
	XRA	D
	MOV	H, A
	JMP	.LBB19_3
.LBB19_2:
	;DEBUG_VALUE: draw_line:x1 <- [$sp+0]
	;DEBUG_VALUE: draw_line:y1 <- [$sp+0]
	;DEBUG_VALUE: draw_line:x0 <- 127
	;DEBUG_VALUE: draw_line:y0 <- 127
	;DEBUG_VALUE: draw_line:plane_addr <- -32768
	LXI	D, 0xff81
	;--- V6C_ADD16 ---
	DAD	D
.LBB19_3:
	;DEBUG_VALUE: draw_line:x1 <- [$sp+0]
	;DEBUG_VALUE: draw_line:y1 <- [$sp+0]
	;DEBUG_VALUE: draw_line:x0 <- 127
	;DEBUG_VALUE: draw_line:y0 <- 127
	;DEBUG_VALUE: draw_line:plane_addr <- -32768
	;--- V6C_SPILL16 ---
	SHLD	.LLo61_2+1
	;DEBUG_VALUE: draw_line:dx <- [$sp+0]
	XRA	A
	;--- V6C_RELOAD8 ---
	LXI	H, .LLo61_8+1
	MOV	E, M
	;--- V6C_BUILD_PAIR ---
	MOV	H, A
	MOV	L, E
	MOV	A, E
	CPI	0x7f
	;--- V6C_BRCOND ---
	JNC	.LBB19_5
; %bb.4:
	;DEBUG_VALUE: draw_line:dx <- [$sp+0]
	;DEBUG_VALUE: draw_line:x1 <- [$sp+0]
	;DEBUG_VALUE: draw_line:y1 <- [$sp+0]
	;DEBUG_VALUE: draw_line:x0 <- 127
	;DEBUG_VALUE: draw_line:y0 <- 127
	;DEBUG_VALUE: draw_line:plane_addr <- -32768
	LXI	D, 0xff81
	;--- V6C_ADD16 ---
	DAD	D
	JMP	.LBB19_6
.LBB19_5:
	;DEBUG_VALUE: draw_line:dx <- [$sp+0]
	;DEBUG_VALUE: draw_line:x1 <- [$sp+0]
	;DEBUG_VALUE: draw_line:y1 <- [$sp+0]
	;DEBUG_VALUE: draw_line:x0 <- 127
	;DEBUG_VALUE: draw_line:y0 <- 127
	;DEBUG_VALUE: draw_line:plane_addr <- -32768
	LXI	D, 0x7f
	;--- V6C_SUB16 ---
	MOV	A, E
	SUB	L
	MOV	L, A
	MOV	A, D
	SBB	H
	MOV	H, A
.LBB19_6:
	;DEBUG_VALUE: draw_line:dx <- [$sp+0]
	;DEBUG_VALUE: draw_line:x1 <- [$sp+0]
	;DEBUG_VALUE: draw_line:y1 <- [$sp+0]
	;DEBUG_VALUE: draw_line:x0 <- 127
	;DEBUG_VALUE: draw_line:y0 <- 127
	;DEBUG_VALUE: draw_line:plane_addr <- -32768
	;--- V6C_SPILL16 ---
	SHLD	.LLo61_1+1
	;DEBUG_VALUE: draw_line:x0 <- 127
	;DEBUG_VALUE: draw_line:y0 <- 127
	;DEBUG_VALUE: draw_line:dy <- [$sp+0]
	;DEBUG_VALUE: draw_line:sy <- undef
	;DEBUG_VALUE: draw_line:err <- [DW_OP_LLVM_arg 0, DW_OP_deref, DW_OP_LLVM_arg 1, DW_OP_deref, DW_OP_plus, DW_OP_stack_value] $sp, $sp
	MVI	A, 0x7f
	MOV	B, A
	CALL	draw_pixel
	;DEBUG_VALUE: draw_line:sx <- undef
	;--- V6C_RELOAD8 ---
	LDA	.LLo61_8+1
	;--- V6C_CMP8_ZERO ---
	ORA	A
	MVI	A, 1
	;--- V6C_SPILL8 ---
	STA	.LLo61_4+1
	;--- V6C_SPILL8 ---
	STA	.LLo61_7+1
	JM	.LBB19_8
; %bb.7:
	;DEBUG_VALUE: draw_line:err <- [DW_OP_LLVM_arg 0, DW_OP_deref, DW_OP_LLVM_arg 0, DW_OP_deref, DW_OP_plus, DW_OP_stack_value] $sp
	;DEBUG_VALUE: draw_line:dy <- [$sp+0]
	;DEBUG_VALUE: draw_line:dx <- [$sp+0]
	;DEBUG_VALUE: draw_line:x1 <- [$sp+0]
	;DEBUG_VALUE: draw_line:y1 <- [$sp+0]
	;DEBUG_VALUE: draw_line:x0 <- 127
	;DEBUG_VALUE: draw_line:y0 <- 127
	;DEBUG_VALUE: draw_line:plane_addr <- -32768
	MVI	A, 0xff
	;--- V6C_SPILL8 ---
	STA	.LLo61_7+1
.LBB19_8:
	;DEBUG_VALUE: draw_line:err <- [DW_OP_LLVM_arg 0, DW_OP_deref, DW_OP_LLVM_arg 0, DW_OP_deref, DW_OP_plus, DW_OP_stack_value] $sp
	;DEBUG_VALUE: draw_line:dy <- [$sp+0]
	;DEBUG_VALUE: draw_line:dx <- [$sp+0]
	;DEBUG_VALUE: draw_line:x1 <- [$sp+0]
	;DEBUG_VALUE: draw_line:y1 <- [$sp+0]
	;DEBUG_VALUE: draw_line:x0 <- 127
	;DEBUG_VALUE: draw_line:y0 <- 127
	;DEBUG_VALUE: draw_line:plane_addr <- -32768
	;--- V6C_RELOAD8 ---
	LDA	.LLo61_5+1
	;--- V6C_CMP8_ZERO ---
	ORA	A
	JM	.LBB19_10
; %bb.9:
	;DEBUG_VALUE: draw_line:err <- [DW_OP_LLVM_arg 0, DW_OP_deref, DW_OP_LLVM_arg 0, DW_OP_deref, DW_OP_plus, DW_OP_stack_value] $sp
	;DEBUG_VALUE: draw_line:dy <- [$sp+0]
	;DEBUG_VALUE: draw_line:dx <- [$sp+0]
	;DEBUG_VALUE: draw_line:x1 <- [$sp+0]
	;DEBUG_VALUE: draw_line:y1 <- [$sp+0]
	;DEBUG_VALUE: draw_line:x0 <- 127
	;DEBUG_VALUE: draw_line:y0 <- 127
	;DEBUG_VALUE: draw_line:plane_addr <- -32768
	MVI	A, 0xff
	;--- V6C_SPILL8 ---
	STA	.LLo61_4+1
.LBB19_10:
	;DEBUG_VALUE: draw_line:err <- [DW_OP_LLVM_arg 0, DW_OP_deref, DW_OP_LLVM_arg 0, DW_OP_deref, DW_OP_plus, DW_OP_stack_value] $sp
	;DEBUG_VALUE: draw_line:dy <- [$sp+0]
	;DEBUG_VALUE: draw_line:dx <- [$sp+0]
	;DEBUG_VALUE: draw_line:x1 <- [$sp+0]
	;DEBUG_VALUE: draw_line:y1 <- [$sp+0]
	;DEBUG_VALUE: draw_line:x0 <- 127
	;DEBUG_VALUE: draw_line:y0 <- 127
	;DEBUG_VALUE: draw_line:plane_addr <- -32768
	;--- V6C_RELOAD8 ---
	LDA	.LLo61_8+1
	CPI	0x7f
	;--- V6C_BRCOND ---
	JNZ	.LBB19_12
; %bb.11:
	;DEBUG_VALUE: draw_line:err <- [DW_OP_LLVM_arg 0, DW_OP_deref, DW_OP_LLVM_arg 0, DW_OP_deref, DW_OP_plus, DW_OP_stack_value] $sp
	;DEBUG_VALUE: draw_line:dy <- [$sp+0]
	;DEBUG_VALUE: draw_line:dx <- [$sp+0]
	;DEBUG_VALUE: draw_line:x1 <- [$sp+0]
	;DEBUG_VALUE: draw_line:y1 <- [$sp+0]
	;DEBUG_VALUE: draw_line:x0 <- 127
	;DEBUG_VALUE: draw_line:y0 <- 127
	;DEBUG_VALUE: draw_line:plane_addr <- -32768
	;--- V6C_RELOAD8 ---
	LDA	.LLo61_5+1
	CPI	0x7f
	;--- V6C_BRCOND ---
	RZ
.LBB19_12:
	;DEBUG_VALUE: draw_line:x0 <- 127
	;DEBUG_VALUE: draw_line:y0 <- 127
	;DEBUG_VALUE: draw_line:plane_addr <- -32768
	;--- V6C_RELOAD16 ---
	LHLD	.LLo61_2+1
	;--- V6C_RELOAD16 ---
	XCHG
	LHLD	.LLo61_1+1
	XCHG
	;--- V6C_ADD16 ---
	DAD	D
	MOV	B, H
	MOV	C, L
	;DEBUG_VALUE: draw_line:err <- $bc
	MVI	A, 0x7f
	;--- V6C_SPILL8 ---
	STA	.LLo61_3+1
	;--- V6C_SPILL8 ---
	STA	.LLo61_6+1
.LBB19_13:                              ; =>This Inner Loop Header: Depth=1
	;DEBUG_VALUE: draw_line:err <- $bc
	;DEBUG_VALUE: draw_line:plane_addr <- -32768
	;DEBUG_VALUE: draw_line:x0 <- [$sp+0]
	;DEBUG_VALUE: draw_line:y0 <- [$sp+0]
	;DEBUG_VALUE: draw_line:err <- $bc
	;--- V6C_RELOAD8 ---
.LLo61_3:
	MVI	A, 0
	;DEBUG_VALUE: draw_line:x0 <- $a
	;--- V6C_SPILL8 ---
	STA	.LLo61_3+1
	;DEBUG_VALUE: draw_line:x0 <- [$sp+0]
	;DEBUG_VALUE: draw_line:x0 <- undef
	;--- V6C_ADD16 ---
	MOV	H, B
	MOV	L, C
	DAD	B
	;DEBUG_VALUE: err2 <- $hl
	;--- V6C_RELOAD16 ---
.LLo61_1:
	LXI	D, 0
	;--- V6C_BR_CC16 ---
	MOV	A, L
	SUB	E
	MOV	A, H
	SBB	D
	JM	.LBB19_15
; %bb.14:                               ;   in Loop: Header=BB19_13 Depth=1
	;DEBUG_VALUE: err2 <- $hl
	;DEBUG_VALUE: draw_line:y0 <- [$sp+0]
	;DEBUG_VALUE: draw_line:err <- $bc
	;DEBUG_VALUE: draw_line:plane_addr <- -32768
	;--- V6C_RELOAD8 ---
.LLo61_4:
	MVI	E, 0
	;--- V6C_RELOAD8 ---
	LDA	.LLo61_3+1
	ADD	E
	;DEBUG_VALUE: draw_line:x0 <- undef
	;--- V6C_SPILL8 ---
	STA	.LLo61_3+1
	;DEBUG_VALUE: draw_line:x0 <- [$sp+0]
	;--- V6C_RELOAD16 ---
	XCHG
	LHLD	.LLo61_1+1
	XCHG
	;--- V6C_ADD16 ---
	MOV	A, C
	ADD	E
	MOV	C, A
	MOV	A, B
	ADC	D
	MOV	B, A
	;DEBUG_VALUE: draw_line:err <- $bc
.LBB19_15:                              ;   in Loop: Header=BB19_13 Depth=1
	;DEBUG_VALUE: draw_line:y0 <- [$sp+0]
	;DEBUG_VALUE: draw_line:err <- $bc
	;DEBUG_VALUE: draw_line:plane_addr <- -32768
	;DEBUG_VALUE: draw_line:x0 <- [$sp+0]
	;DEBUG_VALUE: draw_line:err <- $bc
	;--- V6C_RELOAD16 ---
.LLo61_2:
	LXI	D, 0
	;--- V6C_BR_CC16 ---
	MOV	A, E
	SUB	L
	MOV	A, D
	SBB	H
	JM	.LBB19_17
; %bb.16:                               ;   in Loop: Header=BB19_13 Depth=1
	;DEBUG_VALUE: draw_line:y0 <- [$sp+0]
	;DEBUG_VALUE: draw_line:x0 <- [$sp+0]
	;DEBUG_VALUE: draw_line:err <- $bc
	;DEBUG_VALUE: draw_line:plane_addr <- -32768
	;--- V6C_RELOAD8 ---
.LLo61_7:
	MVI	L, 0
	;--- V6C_RELOAD8 ---
	LDA	.LLo61_6+1
	ADD	L
	;DEBUG_VALUE: draw_line:y0 <- undef
	;--- V6C_SPILL8 ---
	STA	.LLo61_6+1
	;DEBUG_VALUE: draw_line:y0 <- [$sp+0]
	;--- V6C_RELOAD16 ---
	LHLD	.LLo61_2+1
	;--- V6C_ADD16 ---
	DAD	B
	MOV	B, H
	MOV	C, L
	;DEBUG_VALUE: draw_line:err <- $bc
.LBB19_17:                              ;   in Loop: Header=BB19_13 Depth=1
	;DEBUG_VALUE: draw_line:y0 <- [$sp+0]
	;DEBUG_VALUE: draw_line:x0 <- [$sp+0]
	;DEBUG_VALUE: draw_line:err <- $bc
	;DEBUG_VALUE: draw_line:plane_addr <- -32768
	;DEBUG_VALUE: draw_line:x0 <- [$sp+0]
	;DEBUG_VALUE: draw_line:y0 <- [$sp+0]
	;DEBUG_VALUE: draw_line:err <- $bc
	;--- V6C_SPILL16 ---
	MOV	L, C
	MOV	H, B
	SHLD	.LLo61_0+1
	;--- V6C_RELOAD8 ---
	LDA	.LLo61_3+1
	;DEBUG_VALUE: draw_line:x0 <- $a
	;--- V6C_SPILL8 ---
	STA	.LLo61_3+1
	;DEBUG_VALUE: draw_line:err <- [$sp+0]
	;DEBUG_VALUE: draw_line:x0 <- [$sp+0]
	;--- V6C_RELOAD8 ---
.LLo61_6:
	MVI	L, 0
	;--- V6C_SPILL8 ---
	MOV	B, A
	MOV	A, L
	STA	.LLo61_6+1
	MOV	A, B
	;--- V6C_RELOAD8 ---
	LXI	H, .LLo61_6+1
	MOV	B, M
	CALL	draw_pixel
	;--- V6C_RELOAD16 ---
.LLo61_0:
	LXI	B, 0
	;DEBUG_VALUE: draw_line:err <- $bc
	;--- V6C_RELOAD8 ---
.LLo61_8:
	MVI	L, 0
	;--- V6C_RELOAD8 ---
	LDA	.LLo61_6+1
	CMP	L
	;--- V6C_BRCOND ---
	JNZ	.LBB19_13
; %bb.18:                               ;   in Loop: Header=BB19_13 Depth=1
	;DEBUG_VALUE: draw_line:y0 <- [$sp+0]
	;DEBUG_VALUE: draw_line:x0 <- [$sp+0]
	;DEBUG_VALUE: draw_line:err <- $bc
	;DEBUG_VALUE: draw_line:plane_addr <- -32768
	;--- V6C_RELOAD8 ---
.LLo61_5:
	MVI	L, 0
	;--- V6C_RELOAD8 ---
	LDA	.LLo61_3+1
	CMP	L
	;--- V6C_BRCOND ---
	JNZ	.LBB19_13
; %bb.19:
	;DEBUG_VALUE: draw_line:y0 <- [$sp+0]
	;DEBUG_VALUE: draw_line:x0 <- [$sp+0]
	;DEBUG_VALUE: draw_line:err <- $bc
	;DEBUG_VALUE: draw_line:plane_addr <- -32768
	RET
.Lfunc_end4:
                                        ; -- End function
	.section	.text.main,"ax",@progbits
	.globl	main                            ; -- Begin function main
main:                                   ; @main
.Lfunc_begin5:
	;=== void main(void) ===
	;  [folded: sp=0x100]
; %bb.0:
	;DEBUG_VALUE: v6c_set_sp:sp <- 256
	LXI	H, 0xfffd
	DAD	SP
	SPHL
	;APP
	LXI	SP, 0x100
	;NO_APP
	;APP
	MVI	A, 0xfb
	STA	0x38
	MVI	A, 0xc9
	STA	0x39

	;NO_APP
	;APP
	EI

	;NO_APP
	CALL	memset
	CALL	v6c_set_palette
	MVI	A, 0x64
	;DEBUG_VALUE: i <- 0
.LBB20_1:                               ; =>This Inner Loop Header: Depth=1
	;DEBUG_VALUE: i <- undef
	;--- V6C_SPILL8 ---
	LXI	H, 2
	DAD	SP
	MOV	M, A
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
	LXI	H, 2
	DAD	SP
	MOV	M, C
	INX	H
	MOV	M, B
	POP	H
	JC	.LBB20_3
; %bb.2:                                ;   in Loop: Header=BB20_1 Depth=1
	;--- V6C_SPILL16 ---
	PUSH	H
	LXI	H, 2
	DAD	SP
	MOV	M, E
	INX	H
	MOV	M, D
	POP	H
.LBB20_3:                               ;   in Loop: Header=BB20_1 Depth=1
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
	PUSH	H
	LXI	H, 4
	DAD	SP
	MOV	A, M
	POP	H
	LXI	D, 0xfa
	JC	.LBB20_5
; %bb.4:                                ;   in Loop: Header=BB20_1 Depth=1
	XCHG
.LBB20_5:                               ;   in Loop: Header=BB20_1 Depth=1
	MOV	A, E
	ADI	3
	;DEBUG_VALUE: x <- $a
	MOV	E, A
	;DEBUG_VALUE: x <- $e
	;--- V6C_RELOAD16 ---
	PUSH	D
	LXI	H, 2
	DAD	SP
	MOV	E, M
	INX	H
	MOV	D, M
	XCHG
	POP	D
	MOV	A, L
	ADI	3
	;DEBUG_VALUE: y <- $a
	MOV	B, A
	;DEBUG_VALUE: y <- $b
	MOV	A, E
	CALL	draw_line
	;DEBUG_VALUE: i <- undef
	;--- V6C_RELOAD8 ---
	LXI	H, 2
	DAD	SP
	MOV	A, M
	DCR	A
	;--- V6C_BRCOND ---
	JNZ	.LBB20_1
; %bb.6:
	;APP
	DI

	;NO_APP
	;APP
	HLT

	;NO_APP
	LXI	H, 3
	DAD	SP
	SPHL
	RET
.Lfunc_end5:
                                        ; -- End function
	.data
	.globl	__v6c_rand_state                ; @__v6c_rand_state
__v6c_rand_state:
	DW	1                               ; 0x1

	.globl	font                            ; @font
font:
	.ascii	"\000\030$B~BB\000\000|B|BB|\000\000<B@@B<\000\000xDBBDx\000\000~@|@@~\000\000~@|@@@\000\000<B@NB<\000\000BB~BBB"

	.globl	palette                         ; @palette
palette:
	.ascii	"\000\021\"3DUfw\210\231\252\273\314\335\356\377"

	.section	.bss,"aw",@nobits
	.globl	test                            ; @test
test:
	DB	0                               ; 0x0

	.local	__v6c_ss.draw_line              ; @__v6c_ss.draw_line
	.comm	__v6c_ss.draw_line,10,1
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
