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
	.section	.text.main,"ax",@progbits
	.globl	main                            ; -- Begin function main
main:                                   ; @main
; %bb.0:
	XRA	A
	STA	__v6c_a.main
	MOV	E, A
	INR	A
	STA	__v6c_a.main+1
	LDA	__v6c_a.main
	MOV	H, E
	MOV	L, A
	SHLD	.LLo61_4+1
	LDA	__v6c_a.main+1
	MOV	B, E
	MOV	C, A
	LXI	H, 0xffff
	LXI	D, 0
.LBB15_1:                               ; =>This Loop Header: Depth=1
                                        ;     Child Loop BB15_2 Depth 2
                                        ;     Child Loop BB15_6 Depth 2
	XCHG
	SHLD	.LLo61_3+1
	XCHG
	PUSH	H
	MOV	L, C
	MOV	H, B
	SHLD	.LLo61_2+1
	POP	H
.LLo61_4:
	LXI	D, 0
	MOV	A, E
	ADD	C
	MOV	C, A
	MOV	A, D
	ADC	B
	MOV	B, A
	LXI	D, 0xff
	PUSH	H
	MOV	L, C
	MOV	H, B
	SHLD	.LLo61_0+1
	SHLD	.LLo61_1+1
	POP	H
	MOV	A, C
	ANA	E
	MOV	C, A
	MOV	A, B
	ANA	D
	MOV	B, A
	MOV	A, C
	XRA	L
	MOV	L, A
	MOV	A, B
	XRA	H
	MOV	H, A
	LXI	B, 8
.LBB15_2:                               ;   Parent Loop BB15_1 Depth=1
                                        ; =>  This Inner Loop Header: Depth=2
	LXI	D, 1
	MOV	A, L
	ANA	E
	MOV	E, A
	MOV	A, H
	ANA	D
	MOV	D, A
	MOV	A, H
	ORA	A
	RAR
	MOV	H, A
	MOV	A, L
	RAR
	MOV	L, A
	MOV	A, D
	ORA	E
	JZ	.LBB15_4
; %bb.3:                                ;   in Loop: Header=BB15_2 Depth=2
	LXI	D, 0xa001
	MOV	A, L
	XRA	E
	MOV	L, A
	MOV	A, H
	XRA	D
	MOV	H, A
.LBB15_4:                               ;   in Loop: Header=BB15_2 Depth=2
	DCX	B
	MOV	A, B
	ORA	C
	JNZ	.LBB15_2
; %bb.5:                                ;   in Loop: Header=BB15_1 Depth=1
.LLo61_1:
	LXI	D, 0
	MOV	E, D
	MOV	D, B
	MOV	A, L
	XRA	E
	MOV	L, A
	MOV	A, H
	XRA	D
	MOV	H, A
	LXI	B, 8
.LBB15_6:                               ;   Parent Loop BB15_1 Depth=1
                                        ; =>  This Inner Loop Header: Depth=2
	LXI	D, 1
	MOV	A, L
	ANA	E
	MOV	E, A
	MOV	A, H
	ANA	D
	MOV	D, A
	MOV	A, H
	ORA	A
	RAR
	MOV	H, A
	MOV	A, L
	RAR
	MOV	L, A
	MOV	A, D
	ORA	E
	JZ	.LBB15_8
; %bb.7:                                ;   in Loop: Header=BB15_6 Depth=2
	LXI	D, 0xa001
	MOV	A, L
	XRA	E
	MOV	L, A
	MOV	A, H
	XRA	D
	MOV	H, A
.LBB15_8:                               ;   in Loop: Header=BB15_6 Depth=2
	DCX	B
	MOV	A, B
	ORA	C
	JNZ	.LBB15_6
; %bb.9:                                ;   in Loop: Header=BB15_1 Depth=1
.LLo61_3:
	LXI	D, 0
	INX	D
.LLo61_2:
	LXI	B, 0
	PUSH	H
	MOV	L, C
	MOV	H, B
	SHLD	.LLo61_4+1
	POP	H
.LLo61_0:
	LXI	B, 0
	MVI	A, 0x18
	CMP	E
	JNZ	.LBB15_1
; %bb.11:                               ;   in Loop: Header=BB15_1 Depth=1
	XRA	A
	CMP	D
	JNZ	.LBB15_1
; %bb.10:
	MOV	A, L
	OUT	0xed
	HLT
                                        ; -- End function
	.local	__v6c_a.main                    ; @__v6c_a.main
	.comm	__v6c_a.main,2,1
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
	.addrsig_sym __v6c_a.main
