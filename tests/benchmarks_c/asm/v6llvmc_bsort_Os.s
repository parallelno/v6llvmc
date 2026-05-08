	.text
	.section	.text.main,"ax",@progbits
	.globl	main                            ; -- Begin function main
main:                                   ; @main
; %bb.0:
	LXI	H, INIT
	LXI	D, __v6c_a.main
	MVI	A, 0x10
.LBB15_1:                               ; =>This Inner Loop Header: Depth=1
	MOV	C, M
	PUSH	H
	MOV	H, D
	MOV	L, E
	MOV	M, C
	POP	H
	DCR	A
	INX	D
	INX	H
	JNZ	.LBB15_1
; %bb.2:
	MVI	A, 0xf
.LBB15_3:                               ; =>This Loop Header: Depth=1
                                        ;     Child Loop BB15_4 Depth 2
	LXI	D, __v6c_a.main
	STA	.LLo61_1+1
	LXI	H, __v6c_a.main
.LBB15_4:                               ;   Parent Loop BB15_3 Depth=1
                                        ; =>  This Inner Loop Header: Depth=2
	STA	.LLo61_0+1
	LDAX	D
	MOV	C, A
	INX	H
	MOV	A, M
	STA	.LLo61_2+1
	CMP	C
	JNC	.LBB15_6
; %bb.5:                                ;   in Loop: Header=BB15_4 Depth=2
.LLo61_2:
	MVI	A, 0
	STAX	D
	INX	D
	MOV	A, C
	STAX	D
.LBB15_6:                               ;   in Loop: Header=BB15_4 Depth=2
.LLo61_0:
	MVI	A, 0
	DCR	A
	MOV	D, H
	MOV	E, L
	JNZ	.LBB15_4
; %bb.7:                                ;   in Loop: Header=BB15_3 Depth=1
.LLo61_1:
	MVI	A, 0
	DCR	A
	JNZ	.LBB15_3
; %bb.8:
	MVI	E, 0
	LXI	H, __v6c_a.main
	MVI	A, 0x10
.LBB15_9:                               ; =>This Inner Loop Header: Depth=1
	MOV	D, A
	MOV	A, E
	ADD	M
	MOV	E, A
	MOV	A, D
	DCR	A
	INX	H
	JNZ	.LBB15_9
; %bb.10:
	MOV	A, E
	OUT	0xed
	HLT
                                        ; -- End function
	.section	.rodata.cst16,"aM",@progbits,16
INIT:                                   ; @INIT
	.ascii	"\r\310\007c*\001\372@\264\021X!\005\336d\233"

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
