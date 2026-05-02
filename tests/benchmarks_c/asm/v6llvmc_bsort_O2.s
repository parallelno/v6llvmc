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
	MVI	A, 0xf
	JMP	.LBB0_1
.LBB0_5:                                ;   in Loop: Header=BB0_1 Depth=1
.LLo61_1:
	MVI	A, 0
	DCR	A
	JZ	.LBB0_6
.LBB0_1:                                ; =>This Loop Header: Depth=1
                                        ;     Child Loop BB0_2 Depth 2
	LXI	D, __v6c_a.main
	STA	.LLo61_1+1
	LXI	H, __v6c_a.main
	JMP	.LBB0_2
.LBB0_4:                                ;   in Loop: Header=BB0_2 Depth=2
.LLo61_0:
	MVI	A, 0
	DCR	A
	MOV	D, H
	MOV	E, L
	JZ	.LBB0_5
.LBB0_2:                                ;   Parent Loop BB0_1 Depth=1
                                        ; =>  This Inner Loop Header: Depth=2
	STA	.LLo61_0+1
	LDAX	D
	MOV	C, A
	INX	H
	MOV	A, M
	STA	.LLo61_2+1
	CMP	C
	JNC	.LBB0_4
; %bb.3:                                ;   in Loop: Header=BB0_2 Depth=2
.LLo61_2:
	MVI	A, 0
	STAX	D
	INX	D
	MOV	A, C
	STAX	D
	JMP	.LBB0_4
.LBB0_6:
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
	.addrsig_sym __v6c_a.main
