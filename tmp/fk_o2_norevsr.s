	.text
	.section	.text.main,"ax",@progbits
	.globl	main                            ; -- Begin function main
main:                                   ; @main
; %bb.0:
	MVI	A, 7
	STA	__v6c_a.main
	LDA	__v6c_a.main
	MOV	C, A
	# CMP8_ZERO A
	JZ	.LBB15_3
; %bb.1:
	MVI	E, 0
	LXI	H, perm1
.LBB15_2:                               ; =>This Inner Loop Header: Depth=1
	MOV	M, E
	INR	E
	MOV	A, C
	CMP	E
	INX	H
	JNZ	.LBB15_2
.LBB15_3:
	LXI	D, count-1
	XRA	A
	STA	.LLo61_5+1
	MOV	A, C
	STA	.LLo61_8+1
.LBB15_4:                               ; =>This Loop Header: Depth=1
                                        ;     Child Loop BB15_6 Depth 2
                                        ;     Child Loop BB15_9 Depth 2
                                        ;     Child Loop BB15_11 Depth 2
                                        ;       Child Loop BB15_12 Depth 3
                                        ;     Child Loop BB15_20 Depth 2
                                        ;       Child Loop BB15_22 Depth 3
	CPI	1
	MVI	C, 0
	JZ	.LBB15_5
.LBB15_6:                               ;   Parent Loop BB15_4 Depth=1
                                        ; =>  This Inner Loop Header: Depth=2
	MOV	H, C
	MOV	L, A
	DAD	D
	MOV	M, A
	DCR	A
	CPI	1
	JNZ	.LBB15_6
.LBB15_5:                               ;   in Loop: Header=BB15_4 Depth=1
	LDA	.LLo61_8+1
	# CMP8_ZERO A
	JZ	.LBB15_7
; %bb.8:                                ;   in Loop: Header=BB15_4 Depth=1
	LXI	H, perm1
	LXI	D, perm
	LDA	.LLo61_8+1
.LBB15_9:                               ;   Parent Loop BB15_4 Depth=1
                                        ; =>  This Inner Loop Header: Depth=2
	MOV	C, M
	XCHG
	MOV	M, C
	XCHG
	INX	D
	INX	H
	DCR	A
	JNZ	.LBB15_9
.LBB15_7:                               ;   in Loop: Header=BB15_4 Depth=1
	LDA	perm
	# CMP8_ZERO A
	JZ	.LBB15_14
; %bb.10:                               ;   in Loop: Header=BB15_4 Depth=1
	MVI	L, 0
	MOV	H, L
.LBB15_11:                              ;   Parent Loop BB15_4 Depth=1
                                        ; =>  This Loop Header: Depth=2
                                        ;       Child Loop BB15_12 Depth 3
	MOV	B, A
	MOV	A, L
	STA	.LLo61_4+1
	MOV	A, B
	LXI	D, perm
	MVI	L, 1
	MOV	A, L
	STA	.LLo61_2+1
	MOV	A, B
	MOV	A, L
.LBB15_12:                              ;   Parent Loop BB15_4 Depth=1
                                        ;     Parent Loop BB15_11 Depth=2
                                        ; =>    This Inner Loop Header: Depth=3
	XCHG
	SHLD	.LLo61_1+1
	XCHG
	MOV	L, B
	LXI	D, perm
	DAD	D
.LLo61_1:
	LXI	D, 0
	MOV	C, M
	PUSH	H
	LXI	H, .LLo61_3+1
	MOV	M, C
	POP	H
	XCHG
	MOV	C, M
	XCHG
	PUSH	H
	LXI	H, .LLo61_7+1
	MOV	M, C
	POP	H
.LLo61_3:
	MVI	C, 0
	XCHG
	MOV	M, C
	XCHG
.LLo61_7:
	MVI	C, 0
	MOV	M, C
	MVI	H, 0
	DCR	B
	MOV	L, A
	INR	L
.LLo61_2:
	MVI	A, 0
	CMP	B
	INX	D
	MOV	A, L
	MOV	C, A
	MOV	A, L
	STA	.LLo61_2+1
	MOV	A, C
	JC	.LBB15_12
; %bb.13:                               ;   in Loop: Header=BB15_11 Depth=2
.LLo61_4:
	MVI	L, 0
	INR	L
	LDA	perm
	# CMP8_ZERO A
	JNZ	.LBB15_11
	JMP	.LBB15_15
.LBB15_14:                              ;   in Loop: Header=BB15_4 Depth=1
	MVI	L, 0
	MOV	H, L
.LBB15_15:                              ;   in Loop: Header=BB15_4 Depth=1
.LLo61_5:
	MVI	A, 0
	CMP	L
	JNC	.LBB15_17
; %bb.16:                               ;   in Loop: Header=BB15_4 Depth=1
	MOV	A, L
	STA	.LLo61_5+1
.LBB15_17:                              ;   in Loop: Header=BB15_4 Depth=1
	LDA	.LLo61_8+1
	CPI	1
	JZ	.LBB15_18
; %bb.19:                               ;   in Loop: Header=BB15_4 Depth=1
	MVI	A, 1
.LBB15_20:                              ;   Parent Loop BB15_4 Depth=1
                                        ; =>  This Loop Header: Depth=2
                                        ;       Child Loop BB15_22 Depth 3
	MOV	L, A
	SHLD	.LLo61_0+1
	STA	.LLo61_6+1
	# CMP8_ZERO A
	LDA	perm1
	STA	.LLo61_3+1
	JZ	.LBB15_23
; %bb.21:                               ;   in Loop: Header=BB15_20 Depth=2
	LXI	H, perm1
.LLo61_6:
	MVI	E, 0
	LXI	B, perm1
.LBB15_22:                              ;   Parent Loop BB15_4 Depth=1
                                        ;     Parent Loop BB15_20 Depth=2
                                        ; =>    This Inner Loop Header: Depth=3
	INX	B
	LDAX	B
	MOV	D, A
	MOV	M, D
	DCR	E
	MOV	H, B
	MOV	L, C
	JNZ	.LBB15_22
.LBB15_23:                              ;   in Loop: Header=BB15_20 Depth=2
.LLo61_0:
	LXI	H, 0
	LXI	D, perm1
	DAD	D
	LDA	.LLo61_3+1
	MOV	M, A
	LXI	D, count
	LHLD	.LLo61_0+1
	DAD	D
	SHLD	.LLo61_0+1
	DCR	M
	MVI	H, 0
	LXI	D, count-1
	LDA	.LLo61_6+1
	JNZ	.LBB15_4
; %bb.24:                               ;   in Loop: Header=BB15_20 Depth=2
	INR	A
	JNZ	.LBB15_20
.LBB15_18:
	LDA	.LLo61_5+1
	OUT	0xed
	HLT
                                        ; -- End function
	.local	perm1                           ; @perm1
	.comm	perm1,7,1
	.local	count                           ; @count
	.comm	count,7,1
	.local	perm                            ; @perm
	.comm	perm,7,1
	.local	__v6c_a.main                    ; @__v6c_a.main
	.comm	__v6c_a.main,1,1
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
