	.text
	.section	.text.main,"ax",@progbits
	.globl	main                            ; -- Begin function main
main:                                   ; @main
; %bb.0:
	MVI	A, 0
	STA	__v6c_a.main
	MOV	E, A
	INR	A
	STA	__v6c_a.main+1
	LDA	__v6c_a.main
	MOV	H, E
	MOV	L, A
	SHLD	__v6c_ss.main+6
	LDA	__v6c_a.main+1
	MOV	B, E
	MOV	C, A
	LXI	H, 0xffff
	LXI	D, 0
.LBB0_1:                                ; =>This Loop Header: Depth=1
                                        ;     Child Loop BB0_2 Depth 2
                                        ;     Child Loop BB0_6 Depth 2
	XCHG
	SHLD	__v6c_ss.main+2
	XCHG
	PUSH	H
	LXI	H, __v6c_ss.main+4
	MOV	M, C
	INX	H
	MOV	M, B
	POP	H
	XCHG
	LHLD	__v6c_ss.main+6
	XCHG
	MOV	A, E
	ADD	C
	MOV	C, A
	MOV	A, D
	ADC	B
	MOV	B, A
	LXI	D, 0xff
	PUSH	H
	LXI	H, __v6c_ss.main
	MOV	M, C
	INX	H
	MOV	M, B
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
.LBB0_2:                                ;   Parent Loop BB0_1 Depth=1
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
	JZ	.LBB0_4
; %bb.3:                                ;   in Loop: Header=BB0_2 Depth=2
	LXI	D, 0xa001
	MOV	A, L
	XRA	E
	MOV	L, A
	MOV	A, H
	XRA	D
	MOV	H, A
.LBB0_4:                                ;   in Loop: Header=BB0_2 Depth=2
	DCX	B
	MOV	A, B
	ORA	C
	JNZ	.LBB0_2
; %bb.5:                                ;   in Loop: Header=BB0_1 Depth=1
	XCHG
	LHLD	__v6c_ss.main
	XCHG
	MOV	E, D
	MOV	D, B
	MOV	A, L
	XRA	E
	MOV	L, A
	MOV	A, H
	XRA	D
	MOV	H, A
	LXI	B, 8
.LBB0_6:                                ;   Parent Loop BB0_1 Depth=1
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
	JZ	.LBB0_8
; %bb.7:                                ;   in Loop: Header=BB0_6 Depth=2
	LXI	D, 0xa001
	MOV	A, L
	XRA	E
	MOV	L, A
	MOV	A, H
	XRA	D
	MOV	H, A
.LBB0_8:                                ;   in Loop: Header=BB0_6 Depth=2
	DCX	B
	MOV	A, B
	ORA	C
	JNZ	.LBB0_6
; %bb.9:                                ;   in Loop: Header=BB0_1 Depth=1
	XCHG
	LHLD	__v6c_ss.main+2
	XCHG
	INX	D
	PUSH	H
	LXI	H, __v6c_ss.main+4
	MOV	C, M
	INX	H
	MOV	B, M
	POP	H
	PUSH	H
	LXI	H, __v6c_ss.main+6
	MOV	M, C
	INX	H
	MOV	M, B
	POP	H
	PUSH	H
	LXI	H, __v6c_ss.main
	MOV	C, M
	INX	H
	MOV	B, M
	POP	H
	MVI	A, 0x18
	CMP	E
	JNZ	.LBB0_1
; %bb.11:                               ;   in Loop: Header=BB0_1 Depth=1
	MVI	A, 0
	CMP	D
	JNZ	.LBB0_1
; %bb.10:
	MOV	A, L
	OUT	0xed
	HLT
                                        ; -- End function
	.local	__v6c_a.main                    ; @__v6c_a.main
	.comm	__v6c_a.main,2,1
	.local	__v6c_ss.main                   ; @__v6c_ss.main
	.comm	__v6c_ss.main,8,1
	.addrsig
	.addrsig_sym __v6c_a.main
