	.text
	.section	.text.main,"ax",@progbits
	.globl	main                            ; -- Begin function main
main:                                   ; @main
; %bb.0:
	MVI	A, 7
	STA	__v6c_a.main
	LDA	__v6c_a.main
	MOV	C, A
	ORA	A
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
	STA	.LLo61_3+1
	LXI	H, .LLo61_5+1
	MOV	M, C
	LXI	H, .LLo61_6+1
	MOV	M, C
.LBB15_4:                               ; =>This Loop Header: Depth=1
                                        ;     Child Loop BB15_8 Depth 2
                                        ;     Child Loop BB15_11 Depth 2
                                        ;     Child Loop BB15_13 Depth 2
                                        ;       Child Loop BB15_14 Depth 3
                                        ;     Child Loop BB15_21 Depth 2
                                        ;       Child Loop BB15_23 Depth 3
	LDA	.LLo61_5+1
	CPI	1
	JZ	.LBB15_6
; %bb.7:                                ;   in Loop: Header=BB15_4 Depth=1
	LDA	.LLo61_5+1
.LBB15_8:                               ;   Parent Loop BB15_4 Depth=1
                                        ; =>  This Inner Loop Header: Depth=2
	MVI	L, 0
	MOV	H, L
	MOV	L, A
	DAD	D
	MOV	M, A
	DCR	A
	CPI	1
	JNZ	.LBB15_8
; %bb.5:                                ;   in Loop: Header=BB15_4 Depth=1
	STA	.LLo61_5+1
.LBB15_6:                               ;   in Loop: Header=BB15_4 Depth=1
	XRA	A
	CMP	C
	JZ	.LBB15_9
; %bb.10:                               ;   in Loop: Header=BB15_4 Depth=1
	LXI	H, perm1
	LXI	D, perm
	LDA	.LLo61_6+1
.LBB15_11:                              ;   Parent Loop BB15_4 Depth=1
                                        ; =>  This Inner Loop Header: Depth=2
	MOV	C, M
	XCHG
	MOV	M, C
	XCHG
	INX	D
	INX	H
	DCR	A
	JNZ	.LBB15_11
.LBB15_9:                               ;   in Loop: Header=BB15_4 Depth=1
	LDA	perm
	ORA	A
	JZ	.LBB15_16
; %bb.12:                               ;   in Loop: Header=BB15_4 Depth=1
	MVI	L, 0
	MOV	H, L
.LBB15_13:                              ;   Parent Loop BB15_4 Depth=1
                                        ; =>  This Loop Header: Depth=2
                                        ;       Child Loop BB15_14 Depth 3
	MOV	B, A
	MOV	A, L
	STA	.LLo61_8+1
	MOV	A, B
	LXI	D, perm
	MVI	L, 1
	MOV	A, L
	STA	.LLo61_2+1
	MOV	A, B
	MOV	A, L
.LBB15_14:                              ;   Parent Loop BB15_4 Depth=1
                                        ;     Parent Loop BB15_13 Depth=2
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
	LXI	H, .LLo61_4+1
	MOV	M, C
	POP	H
	XCHG
	MOV	C, M
	XCHG
	PUSH	H
	LXI	H, .LLo61_7+1
	MOV	M, C
	POP	H
.LLo61_4:
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
	JC	.LBB15_14
; %bb.15:                               ;   in Loop: Header=BB15_13 Depth=2
.LLo61_8:
	MVI	L, 0
	INR	L
	LDA	perm
	ORA	A
	JNZ	.LBB15_13
	JMP	.LBB15_17
.LBB15_16:                              ;   in Loop: Header=BB15_4 Depth=1
	MOV	L, A
	MOV	H, L
.LBB15_17:                              ;   in Loop: Header=BB15_4 Depth=1
.LLo61_3:
	MVI	A, 0
	CMP	L
	JNC	.LBB15_19
; %bb.18:                               ;   in Loop: Header=BB15_4 Depth=1
	MOV	A, L
	STA	.LLo61_3+1
.LBB15_19:                              ;   in Loop: Header=BB15_4 Depth=1
	LDA	.LLo61_6+1
	CPI	1
	LDA	.LLo61_5+1
	JZ	.LBB15_20
.LBB15_21:                              ;   Parent Loop BB15_4 Depth=1
                                        ; =>  This Loop Header: Depth=2
                                        ;       Child Loop BB15_23 Depth 3
	MOV	L, A
	SHLD	.LLo61_0+1
	STA	.LLo61_5+1
	ORA	A
	LDA	perm1
	JZ	.LBB15_24
; %bb.22:                               ;   in Loop: Header=BB15_21 Depth=2
	LXI	H, perm1
.LLo61_5:
	MVI	E, 0
	LXI	B, perm1
.LBB15_23:                              ;   Parent Loop BB15_4 Depth=1
                                        ;     Parent Loop BB15_21 Depth=2
                                        ; =>    This Inner Loop Header: Depth=3
	INX	B
	PUSH	PSW
	LDAX	B
	MOV	D, A
	POP	PSW
	MOV	M, D
	DCR	E
	MOV	H, B
	MOV	L, C
	JNZ	.LBB15_23
.LBB15_24:                              ;   in Loop: Header=BB15_21 Depth=2
.LLo61_0:
	LXI	H, 0
	LXI	D, perm1
	DAD	D
	MOV	M, A
	LXI	D, count
	LHLD	.LLo61_0+1
	DAD	D
	SHLD	.LLo61_0+1
	DCR	M
.LLo61_6:
	MVI	C, 0
	MVI	H, 0
	LXI	D, count-1
	JNZ	.LBB15_4
; %bb.25:                               ;   in Loop: Header=BB15_21 Depth=2
	LDA	.LLo61_5+1
	INR	A
	CMP	C
	JNZ	.LBB15_21
.LBB15_20:
	LDA	.LLo61_3+1
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
