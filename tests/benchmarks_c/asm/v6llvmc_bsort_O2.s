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
	LXI	H, 0xf
	SHLD	.LLo61_1+1
.LBB0_1:                                ; =>This Loop Header: Depth=1
                                        ;     Child Loop BB0_2 Depth 2
	LXI	H, __v6c_a.main
	SHLD	.LLo61_3+1
	LXI	H, 0
	SHLD	.LLo61_2+1
	LDA	__v6c_a.main
	STA	.LLo61_4+1
	LXI	H, __v6c_a.main
	SHLD	.LLo61_0+1
	LXI	D, __v6c_a.main
.LBB0_2:                                ;   Parent Loop BB0_1 Depth=1
                                        ; =>  This Inner Loop Header: Depth=2
	INX	D
	LDAX	D
.LLo61_4:
	MVI	L, 0
	CMP	L
	XCHG
.LLo61_0:
	LXI	D, 0
	JNC	.LBB0_4
; %bb.3:                                ;   in Loop: Header=BB0_2 Depth=2
	STAX	D
.LLo61_3:
	LXI	B, 0
	INX	B
	LDA	.LLo61_4+1
	STAX	B
.LBB0_4:                                ;   in Loop: Header=BB0_2 Depth=2
.LLo61_2:
	LXI	B, 0
	INX	B
	INX	D
	XCHG
	SHLD	.LLo61_0+1
	XCHG
	STA	.LLo61_4+1
	SHLD	.LLo61_3+1
	XCHG
.LLo61_1:
	LXI	H, 0
	PUSH	H
	MOV	L, C
	MOV	H, B
	SHLD	.LLo61_2+1
	POP	H
	MOV	A, L
	CMP	C
	JNZ	.LBB0_2
; %bb.7:                                ;   in Loop: Header=BB0_2 Depth=2
	MOV	A, H
	CMP	B
	JNZ	.LBB0_2
; %bb.5:                                ;   in Loop: Header=BB0_1 Depth=1
	LHLD	.LLo61_1+1
	DCX	H
	SHLD	.LLo61_1+1
	MOV	A, H
	ORA	L
	JNZ	.LBB0_1
; %bb.6:
	LXI	H, __v6c_a.main
	LDA	__v6c_a.main+1
	ADD	M
	LXI	H, __v6c_a.main+2
	ADD	M
	LXI	H, __v6c_a.main+3
	ADD	M
	LXI	H, __v6c_a.main+4
	ADD	M
	LXI	H, __v6c_a.main+5
	ADD	M
	LXI	H, __v6c_a.main+6
	ADD	M
	LXI	H, __v6c_a.main+7
	ADD	M
	LXI	H, __v6c_a.main+8
	ADD	M
	LXI	H, __v6c_a.main+9
	ADD	M
	LXI	H, __v6c_a.main+10
	ADD	M
	LXI	H, __v6c_a.main+11
	ADD	M
	LXI	H, __v6c_a.main+12
	ADD	M
	LXI	H, __v6c_a.main+13
	ADD	M
	LXI	H, __v6c_a.main+14
	ADD	M
	LXI	H, __v6c_a.main+15
	ADD	M
	OUT	0xed
	HLT
                                        ; -- End function
	.local	__v6c_a.main                    ; @__v6c_a.main
	.comm	__v6c_a.main,16,1
	.addrsig
	.addrsig_sym __v6c_a.main
