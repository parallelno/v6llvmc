	.text
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
	JMP	.LBB15_2
.LBB15_4:                               ;   in Loop: Header=BB15_2 Depth=2
	DCX	B
	MOV	A, B
	ORA	C
	JZ	.LBB15_5
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
	JMP	.LBB15_4
.LBB15_5:                               ;   in Loop: Header=BB15_1 Depth=1
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
	JMP	.LBB15_6
.LBB15_8:                               ;   in Loop: Header=BB15_6 Depth=2
	DCX	B
	MOV	A, B
	ORA	C
	JZ	.LBB15_9
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
	JMP	.LBB15_8
.LBB15_9:                               ;   in Loop: Header=BB15_1 Depth=1
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
