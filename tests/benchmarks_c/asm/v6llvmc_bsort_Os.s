	.text
	.section	.text.main,"ax",@progbits
	.globl	main                            ; -- Begin function main
main:                                   ; @main
; %bb.0:
	LXI	H, INIT
	LXI	D, __v6c_a.main
	MVI	A, 0x10
.LBB0_1:                                ; =>This Inner Loop Header: Depth=1
	MOV	C, M
	PUSH	H
	MOV	H, D
	MOV	L, E
	MOV	M, C
	POP	H
	INX	D
	INX	H
	DCR	A
	JNZ	.LBB0_1
; %bb.2:
	MVI	A, 0xf
.LBB0_3:                                ; =>This Loop Header: Depth=1
                                        ;     Child Loop BB0_4 Depth 2
	LXI	D, __v6c_a.main
	STA	.LLo61_1+1
	LXI	H, __v6c_a.main
.LBB0_4:                                ;   Parent Loop BB0_3 Depth=1
                                        ; =>  This Inner Loop Header: Depth=2
	STA	.LLo61_0+1
	LDAX	D
	MOV	C, A
	INX	H
	MOV	A, M
	STA	.LLo61_2+1
	CMP	C
	JNC	.LBB0_6
; %bb.5:                                ;   in Loop: Header=BB0_4 Depth=2
.LLo61_2:
	MVI	A, 0
	STAX	D
	INX	D
	MOV	A, C
	STAX	D
.LBB0_6:                                ;   in Loop: Header=BB0_4 Depth=2
.LLo61_0:
	MVI	A, 0
	DCR	A
	MOV	D, H
	MOV	E, L
	JNZ	.LBB0_4
; %bb.7:                                ;   in Loop: Header=BB0_3 Depth=1
.LLo61_1:
	MVI	A, 0
	DCR	A
	JNZ	.LBB0_3
; %bb.8:
	MVI	E, 0
	LXI	H, __v6c_a.main
	MVI	A, 0x10
.LBB0_9:                                ; =>This Inner Loop Header: Depth=1
	MOV	D, A
	MOV	A, E
	ADD	M
	MOV	E, A
	MOV	A, D
	INX	H
	DCR	A
	JNZ	.LBB0_9
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
	.addrsig_sym __v6c_a.main
