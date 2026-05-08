	.text
	.section	.text.main,"ax",@progbits
	.globl	main                            ; -- Begin function main
main:                                   ; @main
; %bb.0:
	LXI	H, 0x9b64
	SHLD	__v6c_a.main+14
	LXI	H, 0xde05
	SHLD	__v6c_a.main+12
	LXI	H, 0x2158
	SHLD	__v6c_a.main+10
	LXI	H, 0x11b4
	SHLD	__v6c_a.main+8
	LXI	H, 0x40fa
	SHLD	__v6c_a.main+6
	LXI	H, 0x12a
	SHLD	__v6c_a.main+4
	LXI	H, 0x6307
	SHLD	__v6c_a.main+2
	LXI	H, 0xc80d
	SHLD	__v6c_a.main
	MVI	L, 0xf
	JMP	.LBB15_1
.LBB15_5:                               ;   in Loop: Header=BB15_1 Depth=1
.LLo61_0:
	MVI	L, 0
	DCR	L
	JZ	.LBB15_6
.LBB15_1:                               ; =>This Loop Header: Depth=1
                                        ;     Child Loop BB15_2 Depth 2
	LXI	B, __v6c_a.main
	MOV	A, L
	STA	.LLo61_0+1
	LXI	D, __v6c_a.main
	JMP	.LBB15_2
.LBB15_4:                               ;   in Loop: Header=BB15_2 Depth=2
	DCR	L
	MOV	B, D
	MOV	C, E
	JZ	.LBB15_5
.LBB15_2:                               ;   Parent Loop BB15_1 Depth=1
                                        ; =>  This Inner Loop Header: Depth=2
	LDAX	B
	MOV	H, A
	INX	D
	LDAX	D
	CMP	H
	JNC	.LBB15_4
; %bb.3:                                ;   in Loop: Header=BB15_2 Depth=2
	STAX	B
	INX	B
	MOV	A, H
	STAX	B
	JMP	.LBB15_4
.LBB15_6:
	LXI	H, __v6c_a.main
	LDA	__v6c_a.main+1
	ADD	M
	LXI	H, __v6c_a.main+2
	ADD	M
	INX	H
	ADD	M
	INX	H
	ADD	M
	INX	H
	ADD	M
	INX	H
	ADD	M
	INX	H
	ADD	M
	INX	H
	ADD	M
	INX	H
	ADD	M
	INX	H
	ADD	M
	INX	H
	ADD	M
	INX	H
	ADD	M
	INX	H
	ADD	M
	INX	H
	ADD	M
	INX	H
	ADD	M
	OUT	0xed
	HLT
                                        ; -- End function
	.local	__v6c_a.main                    ; @__v6c_a.main
	.comm	__v6c_a.main,16,1
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
