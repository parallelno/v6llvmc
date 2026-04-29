	.text
	.section	.text.main,"ax",@progbits
	.globl	main                            ; -- Begin function main
main:                                   ; @main
; %bb.0:
	LXI	H, 0x9b64
	SHLD	a+14
	LXI	H, 0xde05
	SHLD	a+12
	LXI	H, 0x2158
	SHLD	a+10
	LXI	H, 0x11b4
	SHLD	a+8
	LXI	H, 0x40fa
	SHLD	a+6
	LXI	H, 0x12a
	SHLD	a+4
	LXI	H, 0x6307
	SHLD	a+2
	LXI	H, 0xc80d
	SHLD	a
	LXI	H, 0xf
	SHLD	__v6c_ss.main+7
.LBB0_1:                                ; =>This Loop Header: Depth=1
                                        ;     Child Loop BB0_2 Depth 2
	LXI	H, a
	SHLD	__v6c_ss.main+5
	LXI	H, 0
	SHLD	__v6c_ss.main+1
	LDA	a
	STA	__v6c_ss.main
	LXI	H, a
	SHLD	__v6c_ss.main+3
	LXI	D, a
.LBB0_2:                                ;   Parent Loop BB0_1 Depth=1
                                        ; =>  This Inner Loop Header: Depth=2
	INX	D
	LDAX	D
	LXI	H, __v6c_ss.main
	CMP	M
	LHLD	__v6c_ss.main+3
	XCHG
	JNC	.LBB0_4
; %bb.3:                                ;   in Loop: Header=BB0_2 Depth=2
	STAX	D
	PUSH	H
	LXI	H, __v6c_ss.main+5
	MOV	C, M
	INX	H
	MOV	B, M
	POP	H
	INX	B
	LDA	__v6c_ss.main
	STAX	B
.LBB0_4:                                ;   in Loop: Header=BB0_2 Depth=2
	PUSH	H
	LXI	H, __v6c_ss.main+1
	MOV	C, M
	INX	H
	MOV	B, M
	POP	H
	INX	B
	INX	D
	XCHG
	SHLD	__v6c_ss.main+3
	XCHG
	STA	__v6c_ss.main
	SHLD	__v6c_ss.main+5
	XCHG
	LHLD	__v6c_ss.main+7
	PUSH	H
	LXI	H, __v6c_ss.main+1
	MOV	M, C
	INX	H
	MOV	M, B
	POP	H
	MOV	A, L
	CMP	C
	JNZ	.LBB0_2
; %bb.7:                                ;   in Loop: Header=BB0_2 Depth=2
	MOV	A, H
	CMP	B
	JNZ	.LBB0_2
; %bb.5:                                ;   in Loop: Header=BB0_1 Depth=1
	LHLD	__v6c_ss.main+7
	DCX	H
	SHLD	__v6c_ss.main+7
	MOV	A, H
	ORA	L
	JNZ	.LBB0_1
; %bb.6:
	LXI	H, a
	LDA	a+1
	ADD	M
	LXI	H, a+2
	ADD	M
	LXI	H, a+3
	ADD	M
	LXI	H, a+4
	ADD	M
	LXI	H, a+5
	ADD	M
	LXI	H, a+6
	ADD	M
	LXI	H, a+7
	ADD	M
	LXI	H, a+8
	ADD	M
	LXI	H, a+9
	ADD	M
	LXI	H, a+10
	ADD	M
	LXI	H, a+11
	ADD	M
	LXI	H, a+12
	ADD	M
	LXI	H, a+13
	ADD	M
	LXI	H, a+14
	ADD	M
	LXI	H, a+15
	ADD	M
	OUT	0xed
	HLT
                                        ; -- End function
	.local	a                               ; @a
	.comm	a,16,1
	.local	__v6c_ss.main                   ; @__v6c_ss.main
	.comm	__v6c_ss.main,9,1
	.addrsig
