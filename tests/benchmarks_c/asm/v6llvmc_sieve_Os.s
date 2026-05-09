	.text
	.section	.text.main,"ax",@progbits
	.globl	main                            ; -- Begin function main
main:                                   ; @main
; %bb.0:
	LXI	H, flags
.LBB15_1:                               ; =>This Inner Loop Header: Depth=1
	MVI	M, 0
	INX	H
	MVI	A, <(flags+8000)
	CMP	L
	JNZ	.LBB15_1
; %bb.10:                               ;   in Loop: Header=BB15_1 Depth=1
	MVI	A, >(flags+8000)
	CMP	H
	JNZ	.LBB15_1
; %bb.2:
	LXI	H, 4
	SHLD	.LLo61_4+1
	LXI	H, 0x1f3e
	SHLD	.LLo61_0+1
	LXI	H, 2
	LXI	B, 5
	LXI	D, flags+4
	XCHG
	SHLD	.LLo61_2+1
	XCHG
.LBB15_3:                               ; =>This Loop Header: Depth=1
                                        ;     Child Loop BB15_5 Depth 2
	PUSH	H
	MOV	L, C
	MOV	H, B
	SHLD	.LLo61_5+1
	POP	H
	SHLD	.LLo61_1+1
	LXI	D, flags
	DAD	D
	MOV	A, M
	ORA	A
	JNZ	.LBB15_8
; %bb.4:                                ;   in Loop: Header=BB15_3 Depth=1
	LHLD	.LLo61_2+1
	MOV	C, L
	MOV	B, H
	LHLD	.LLo61_4+1
.LBB15_5:                               ;   Parent Loop BB15_3 Depth=1
                                        ; =>  This Inner Loop Header: Depth=2
	SHLD	.LLo61_3+1
	LDAX	B
	ORA	A
	MVI	L, 0
	MOV	A, L
	JNZ	.LBB15_7
; %bb.6:                                ;   in Loop: Header=BB15_5 Depth=2
	INR	A
.LBB15_7:                               ;   in Loop: Header=BB15_5 Depth=2
	MOV	H, L
	MOV	L, A
.LLo61_0:
	LXI	D, 0
	MOV	A, E
	SUB	L
	MOV	E, A
	MOV	A, D
	SBB	H
	MOV	D, A
	XCHG
	SHLD	.LLo61_0+1
	MVI	A, 1
	STAX	B
.LLo61_1:
	LXI	H, 0
	MOV	A, C
	ADD	L
	MOV	C, A
	MOV	A, B
	ADC	H
	MOV	B, A
.LLo61_3:
	LXI	D, 0
	DAD	D
	MVI	A, 0x3f
	SUB	L
	MVI	A, 0x1f
	SBB	H
	JNC	.LBB15_5
.LBB15_8:                               ;   in Loop: Header=BB15_3 Depth=1
	LHLD	.LLo61_1+1
	DAD	H
.LLo61_4:
	LXI	D, 0
	DAD	D
	SHLD	.LLo61_4+1
	LHLD	.LLo61_1+1
.LLo61_5:
	LXI	B, 0
.LLo61_2:
	LXI	D, 0
	XCHG
	DAD	B
	SHLD	.LLo61_2+1
	INX	B
	INX	B
	LHLD	.LLo61_4+1
	XCHG
	INX	D
	XCHG
	SHLD	.LLo61_4+1
	XCHG
	INX	H
	MVI	A, 0x5a
	CMP	L
	JNZ	.LBB15_3
; %bb.11:                               ;   in Loop: Header=BB15_3 Depth=1
	XRA	A
	CMP	H
	JNZ	.LBB15_3
; %bb.9:
	LHLD	.LLo61_0+1
	XCHG
	MOV	L, D
	MOV	H, A
	MOV	A, L
	XRA	E
	MOV	L, A
	MOV	A, H
	XRA	D
	MOV	H, A
	MOV	A, L
	OUT	0xed
	HLT
                                        ; -- End function
	.local	flags                           ; @flags
	.comm	flags,8000,1
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
