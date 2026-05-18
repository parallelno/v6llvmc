	.text
	.section	.text.main,"ax",@progbits
	.globl	main                            ; -- Begin function main
main:                                   ; @main
; %bb.0:
	LXI	H, __v6c_a.main
	MVI	E, 0xff
	MVI	A, 7
.LBB15_1:                               ; =>This Inner Loop Header: Depth=1
	MOV	M, A
	ADI	0x1f
	INX	H
	DCR	E
	JNZ	.LBB15_1
; %bb.2:
	MVI	L, 0xfe
.LBB15_3:                               ; =>This Loop Header: Depth=1
                                        ;     Child Loop BB15_4 Depth 2
	LXI	B, __v6c_a.main
	MOV	A, L
	STA	.LLo61_0+1
	LXI	D, __v6c_a.main
.LBB15_4:                               ;   Parent Loop BB15_3 Depth=1
                                        ; =>  This Inner Loop Header: Depth=2
	LDAX	B
	MOV	H, A
	INX	D
	LDAX	D
	CMP	H
	JNC	.LBB15_6
; %bb.5:                                ;   in Loop: Header=BB15_4 Depth=2
	STAX	B
	INX	B
	MOV	A, H
	STAX	B
.LBB15_6:                               ;   in Loop: Header=BB15_4 Depth=2
	DCR	L
	MOV	B, D
	MOV	C, E
	JNZ	.LBB15_4
; %bb.7:                                ;   in Loop: Header=BB15_3 Depth=1
.LLo61_0:
	MVI	L, 0
	DCR	L
	JNZ	.LBB15_3
; %bb.8:
	XRA	A
	LXI	H, __v6c_a.main
	MVI	E, 0xff
.LBB15_9:                               ; =>This Inner Loop Header: Depth=1
	ADD	M
	INX	H
	DCR	E
	JNZ	.LBB15_9
; %bb.10:
	OUT	0xed
	HLT
                                        ; -- End function
	.local	__v6c_a.main                    ; @__v6c_a.main
	.comm	__v6c_a.main,255,1
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
