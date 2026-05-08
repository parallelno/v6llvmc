	.text
	.section	.text.main,"ax",@progbits
	.globl	main                            ; -- Begin function main
main:                                   ; @main
; %bb.0:
	LXI	H, 0xace1
	SHLD	__v6c_a.main
	LXI	H, 0
	LXI	D, 0x1000
	LDA	__v6c_a.main
	MOV	C, A
	LDA	__v6c_a.main+1
	MOV	B, A
.LBB15_1:                               ; =>This Inner Loop Header: Depth=1
	SHLD	.LLo61_0+1
	MOV	H, B
	MOV	L, C
	LXI	B, 1
	MOV	A, L
	ANA	C
	MOV	C, A
	MOV	A, H
	ANA	B
	MOV	B, A
	PUSH	H
	MOV	L, C
	MOV	H, B
	SHLD	.LLo61_1+1
	POP	H
	MOV	B, H
	MOV	C, L
	MOV	A, B
	ORA	A
	RAR
	MOV	B, A
	MOV	A, C
	RAR
	MOV	C, A
.LLo61_1:
	LXI	H, 0
	MOV	A, H
	ORA	L
	JNZ	.LBB15_2
; %bb.3:                                ;   in Loop: Header=BB15_1 Depth=1
	LHLD	.LLo61_0+1
	JMP	.LBB15_4
.LBB15_2:                               ;   in Loop: Header=BB15_1 Depth=1
	LXI	H, 0xb400
	MOV	A, C
	XRA	L
	MOV	C, A
	MOV	A, B
	XRA	H
	MOV	B, A
.LLo61_0:
	LXI	H, 0
.LBB15_4:                               ;   in Loop: Header=BB15_1 Depth=1
	MOV	A, C
	XRA	L
	MOV	L, A
	MOV	A, B
	XRA	H
	MOV	H, A
	DCX	D
	MOV	A, D
	ORA	E
	JNZ	.LBB15_1
; %bb.5:
	MOV	E, H
	MOV	A, E
	XRA	L
	MOV	L, A
	MOV	A, D
	XRA	H
	MOV	H, A
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
