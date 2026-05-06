	.text
	.section	.text.__mulqi3,"ax",@progbits
__mulqi3:                               ; -- Begin function __mulqi3
                                        ; @__mulqi3
; %bb.0:
	;APP
	MOV	E, B
	MVI	D, 0
	LXI	H, 0
	MVI	B, 8
.Ltmp0:
	DAD	H
	RLC

	JNC	.Ltmp1
	DAD	D
.Ltmp1:
	DCR	B
	JNZ	.Ltmp0
	MOV	A, L
	RET


	;NO_APP
                                        ; -- End function
	.section	.text.__v6c_mulqihi3,"ax",@progbits
__v6c_mulqihi3:                         ; -- Begin function __v6c_mulqihi3
                                        ; @__v6c_mulqihi3
; %bb.0:
	;APP
	MOV	E, B
	MVI	D, 0
	LXI	H, 0
	MVI	B, 8
.Ltmp2:
	DAD	H
	RLC

	JNC	.Ltmp3
	DAD	D
.Ltmp3:
	DCR	B
	JNZ	.Ltmp2
	RET


	;NO_APP
                                        ; -- End function
	.section	.text.__mulhi3,"ax",@progbits
__mulhi3:                               ; -- Begin function __mulhi3
                                        ; @__mulhi3
; %bb.0:
	;APP
	XCHG

	MOV	A, H
	MOV	C, L
	LXI	H, 0
	MVI	B, 8
.Ltmp4:
	DAD	H
	RLC

	JNC	.Ltmp5
	DAD	D
.Ltmp5:
	DCR	B
	JNZ	.Ltmp4
	MOV	A, C
	MVI	B, 8
.Ltmp6:
	DAD	H
	RLC

	JNC	.Ltmp7
	DAD	D
.Ltmp7:
	DCR	B
	JNZ	.Ltmp6
	RET


	;NO_APP
                                        ; -- End function
	.section	.text.__v6c_udivmod16_body,"ax",@progbits
__v6c_udivmod16_body:                   ; -- Begin function __v6c_udivmod16_body
                                        ; @__v6c_udivmod16_body
; %bb.0:
	;APP
	MOV	A, D
	ORA	E
	JNZ	.Ltmp8
	LXI	H, 0xffff
	LXI	B, 0
	RET

.Ltmp8:
	LXI	B, 0
	MVI	A, 0x10
	PUSH	PSW
.Ltmp9:
	DAD	H
	MOV	A, C
	RAL

	MOV	C, A
	MOV	A, B
	RAL

	MOV	B, A
	MOV	A, C
	SUB	E
	MOV	A, B
	SBB	D
	JC	.Ltmp10
	MOV	A, C
	SUB	E
	MOV	C, A
	MOV	A, B
	SBB	D
	MOV	B, A
	INX	H
.Ltmp10:
	POP	PSW
	DCR	A
	PUSH	PSW
	JNZ	.Ltmp9
	POP	PSW
	RET


	;NO_APP
                                        ; -- End function
	.section	.text.__udivhi3,"ax",@progbits
__udivhi3:                              ; -- Begin function __udivhi3
                                        ; @__udivhi3
; %bb.0:
	;APP
	CALL	__v6c_udivmod16_body
	RET


	;NO_APP
                                        ; -- End function
	.section	.text.__umodhi3,"ax",@progbits
__umodhi3:                              ; -- Begin function __umodhi3
                                        ; @__umodhi3
; %bb.0:
	;APP
	CALL	__v6c_udivmod16_body
	MOV	H, B
	MOV	L, C
	RET


	;NO_APP
                                        ; -- End function
	.section	.text.__udivmodhi4,"ax",@progbits
__udivmodhi4:                           ; -- Begin function __udivmodhi4
                                        ; @__udivmodhi4
; %bb.0:
	;APP
	PUSH	B
	CALL	__v6c_udivmod16_body
	XTHL

	MOV	M, C
	INX	H
	MOV	M, B
	POP	H
	RET


	;NO_APP
                                        ; -- End function
	.section	.text.__divmodhi4,"ax",@progbits
__divmodhi4:                            ; -- Begin function __divmodhi4
                                        ; @__divmodhi4
; %bb.0:
	;APP
	PUSH	B
	MOV	A, H
	PUSH	PSW
	MOV	A, H
	XRA	D
	PUSH	PSW
	MOV	A, H
	ORA	A
	JP	.Ltmp11
	CALL	__v6c_neg_hl_body
.Ltmp11:
	MOV	A, D
	ORA	A
	JP	.Ltmp12
	CALL	__v6c_neg_de_body
.Ltmp12:
	CALL	__v6c_udivmod16_body
	POP	PSW
	ORA	A
	JP	.Ltmp13
	CALL	__v6c_neg_hl_body
.Ltmp13:
	POP	PSW
	ORA	A
	JP	.Ltmp14
	MOV	A, C
	CMA

	MOV	C, A
	MOV	A, B
	CMA

	MOV	B, A
	INX	B
.Ltmp14:
	XTHL

	MOV	M, C
	INX	H
	MOV	M, B
	POP	H
	RET


	;NO_APP
                                        ; -- End function
	.section	.text.__v6c_neg_hl_body,"ax",@progbits
__v6c_neg_hl_body:                      ; -- Begin function __v6c_neg_hl_body
                                        ; @__v6c_neg_hl_body
; %bb.0:
	;APP
	MOV	A, L
	CMA

	MOV	L, A
	MOV	A, H
	CMA

	MOV	H, A
	INX	H
	RET


	;NO_APP
                                        ; -- End function
	.section	.text.__v6c_neg_de_body,"ax",@progbits
__v6c_neg_de_body:                      ; -- Begin function __v6c_neg_de_body
                                        ; @__v6c_neg_de_body
; %bb.0:
	;APP
	MOV	A, E
	CMA

	MOV	E, A
	MOV	A, D
	CMA

	MOV	D, A
	INX	D
	RET


	;NO_APP
                                        ; -- End function
	.section	.text.__divhi3,"ax",@progbits
__divhi3:                               ; -- Begin function __divhi3
                                        ; @__divhi3
; %bb.0:
	;APP
	MOV	A, H
	XRA	D
	PUSH	PSW
	MOV	A, H
	ORA	A
	JP	.Ltmp15
	CALL	__v6c_neg_hl_body
.Ltmp15:
	MOV	A, D
	ORA	A
	JP	.Ltmp16
	CALL	__v6c_neg_de_body
.Ltmp16:
	CALL	__v6c_udivmod16_body
	POP	PSW
	ORA	A
	JP	.Ltmp17
	CALL	__v6c_neg_hl_body
.Ltmp17:
	RET


	;NO_APP
                                        ; -- End function
	.section	.text.__modhi3,"ax",@progbits
__modhi3:                               ; -- Begin function __modhi3
                                        ; @__modhi3
; %bb.0:
	;APP
	MOV	A, H
	PUSH	PSW
	ORA	A
	JP	.Ltmp18
	CALL	__v6c_neg_hl_body
.Ltmp18:
	MOV	A, D
	ORA	A
	JP	.Ltmp19
	CALL	__v6c_neg_de_body
.Ltmp19:
	CALL	__v6c_udivmod16_body
	MOV	H, B
	MOV	L, C
	POP	PSW
	ORA	A
	JP	.Ltmp20
	CALL	__v6c_neg_hl_body
.Ltmp20:
	RET


	;NO_APP
                                        ; -- End function
	.section	.text.__ashlhi3,"ax",@progbits
__ashlhi3:                              ; -- Begin function __ashlhi3
                                        ; @__ashlhi3
; %bb.0:
	;APP
	MOV	A, E
	ANI	0xf
	JZ	.Ltmp21
	CPI	0x10
	JNC	.Ltmp22
	MOV	E, A
.Ltmp23:
	DAD	H
	DCR	E
	JNZ	.Ltmp23
.Ltmp21:
	RET

.Ltmp22:
	LXI	H, 0
	RET


	;NO_APP
                                        ; -- End function
	.section	.text.__lshrhi3,"ax",@progbits
__lshrhi3:                              ; -- Begin function __lshrhi3
                                        ; @__lshrhi3
; %bb.0:
	;APP
	MOV	A, E
	ANI	0xf
	JZ	.Ltmp24
	CPI	0x10
	JNC	.Ltmp25
	MOV	E, A
.Ltmp26:
	ORA	A
	MOV	A, H
	RAR

	MOV	H, A
	MOV	A, L
	RAR

	MOV	L, A
	DCR	E
	JNZ	.Ltmp26
.Ltmp24:
	RET

.Ltmp25:
	LXI	H, 0
	RET


	;NO_APP
                                        ; -- End function
	.section	.text.__ashrhi3,"ax",@progbits
__ashrhi3:                              ; -- Begin function __ashrhi3
                                        ; @__ashrhi3
; %bb.0:
	;APP
	MOV	A, E
	ANI	0xf
	JZ	.Ltmp27
	CPI	0x10
	JNC	.Ltmp28
	MOV	E, A
.Ltmp29:
	MOV	A, H
	RAL

	MOV	A, H
	RAR

	MOV	H, A
	MOV	A, L
	RAR

	MOV	L, A
	DCR	E
	JNZ	.Ltmp29
.Ltmp27:
	RET

.Ltmp28:
	MOV	A, H
	RAL

	SBB	A
	MOV	H, A
	MOV	L, A
	RET


	;NO_APP
                                        ; -- End function
	.section	.text.init_buf,"ax",@progbits
init_buf:                               ; -- Begin function init_buf
                                        ; @init_buf
; %bb.0:
	LXI	H, buf
	MVI	A, 0xfc
.LBB15_1:                               ; =>This Inner Loop Header: Depth=1
	MVI	M, 1
	INX	H
	DCR	A
	JNZ	.LBB15_1
; %bb.2:
	LXI	H, 0
	SHLD	buf
	RET
                                        ; -- End function
	.section	.text.cross_off,"ax",@progbits
cross_off:                              ; -- Begin function cross_off
                                        ; @cross_off
; %bb.0:
	MVI	L, 0
	MOV	H, L
	MOV	L, A
	SHLD	.LLo61_0+1
	CPI	0x7e
	RNC
.LBB16_1:
	LHLD	.LLo61_0+1
	DAD	H
	LXI	B, buf
.LBB16_2:                               ; =>This Inner Loop Header: Depth=1
.LLo61_0:
	LXI	D, 0
	XCHG
	DAD	D
	XCHG
	DAD	B
	MVI	M, 0
	MOV	H, D
	MOV	L, E
	MVI	A, 0xfb
	SUB	E
	MVI	A, 0
	SBB	D
	JNC	.LBB16_2
; %bb.3:
	RET
                                        ; -- End function
	.section	.text.count_set,"ax",@progbits
count_set:                              ; -- Begin function count_set
                                        ; @count_set
; %bb.0:
	XRA	A
	LXI	H, buf
	MVI	C, 0xfc
	JMP	.LBB17_1
.LBB17_3:                               ;   in Loop: Header=BB17_1 Depth=1
	MOV	A, D
	ADD	E
	MOV	D, A
	INX	H
	MOV	A, C
	DCR	A
	MOV	C, A
	MOV	A, D
	RZ
.LBB17_1:                               ; =>This Inner Loop Header: Depth=1
	MOV	D, A
	MOV	A, M
	ORA	A
	MVI	E, 0
	JZ	.LBB17_3
; %bb.2:                                ;   in Loop: Header=BB17_1 Depth=1
	INR	E
	JMP	.LBB17_3
                                        ; -- End function
	.section	.text.main,"ax",@progbits
	.globl	main                            ; -- Begin function main
main:                                   ; @main
; %bb.0:
	CALL	init_buf
	LDA	buf+2
	ORA	A
	JZ	.LBB18_2
; %bb.1:
	MVI	A, 2
	CALL	cross_off
.LBB18_2:
	LDA	buf+3
	ORA	A
	JZ	.LBB18_4
; %bb.3:
	MVI	A, 3
	CALL	cross_off
.LBB18_4:
	LDA	buf+4
	ORA	A
	JZ	.LBB18_6
; %bb.5:
	MVI	A, 4
	CALL	cross_off
.LBB18_6:
	LDA	buf+5
	ORA	A
	JZ	.LBB18_8
; %bb.7:
	MVI	A, 5
	CALL	cross_off
.LBB18_8:
	LDA	buf+6
	ORA	A
	JZ	.LBB18_10
; %bb.9:
	MVI	A, 6
	CALL	cross_off
.LBB18_10:
	LDA	buf+7
	ORA	A
	JZ	.LBB18_12
; %bb.11:
	MVI	A, 7
	CALL	cross_off
.LBB18_12:
	LDA	buf+8
	ORA	A
	JZ	.LBB18_14
; %bb.13:
	MVI	A, 8
	CALL	cross_off
.LBB18_14:
	LDA	buf+9
	ORA	A
	JZ	.LBB18_16
; %bb.15:
	MVI	A, 9
	CALL	cross_off
.LBB18_16:
	LDA	buf+10
	ORA	A
	JZ	.LBB18_18
; %bb.17:
	MVI	A, 0xa
	CALL	cross_off
.LBB18_18:
	LDA	buf+11
	ORA	A
	JZ	.LBB18_20
; %bb.19:
	MVI	A, 0xb
	CALL	cross_off
.LBB18_20:
	LDA	buf+12
	ORA	A
	JZ	.LBB18_22
; %bb.21:
	MVI	A, 0xc
	CALL	cross_off
.LBB18_22:
	LDA	buf+13
	ORA	A
	JZ	.LBB18_24
; %bb.23:
	MVI	A, 0xd
	CALL	cross_off
.LBB18_24:
	LDA	buf+14
	ORA	A
	JZ	.LBB18_26
; %bb.25:
	MVI	A, 0xe
	CALL	cross_off
.LBB18_26:
	LDA	buf+15
	ORA	A
	JZ	.LBB18_28
; %bb.27:
	MVI	A, 0xf
	CALL	cross_off
.LBB18_28:
	CALL	count_set
	OUT	0xed
	HLT
                                        ; -- End function
	.local	buf                             ; @buf
	.comm	buf,252,1
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
