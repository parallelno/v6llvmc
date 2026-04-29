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
	LDA	__v6c_a.main+1
	MOV	D, E
	MOV	E, A
	LXI	B, 0xffff
	PUSH	H
	MOV	L, C
	MOV	H, B
	SHLD	.LLo61_2+1
	POP	H
	LXI	B, 0x18
	JMP	.LBB0_1
.LBB0_34:                               ;   in Loop: Header=BB0_1 Depth=1
	SHLD	.LLo61_2+1
	MOV	B, D
	MOV	C, E
	DCX	B
.LLo61_3:
	LXI	H, 0
.LLo61_1:
	LXI	D, 0
	MOV	A, B
	ORA	C
	JZ	.LBB0_35
.LBB0_1:                                ; =>This Inner Loop Header: Depth=1
	XCHG
	SHLD	.LLo61_3+1
	XCHG
	DAD	D
	XCHG
	LXI	H, 0xff
	XCHG
	SHLD	.LLo61_0+1
	SHLD	.LLo61_1+1
	XCHG
	MOV	A, E
	ANA	L
	MOV	L, A
	MOV	A, D
	ANA	H
	MOV	H, A
.LLo61_2:
	LXI	D, 0
	MOV	A, L
	XRA	E
	MOV	L, A
	MOV	A, H
	XRA	D
	MOV	H, A
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
	JZ	.LBB0_3
; %bb.2:                                ;   in Loop: Header=BB0_1 Depth=1
	LXI	D, 0xa001
	MOV	A, L
	XRA	E
	MOV	L, A
	MOV	A, H
	XRA	D
	MOV	H, A
.LBB0_3:                                ;   in Loop: Header=BB0_1 Depth=1
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
	JZ	.LBB0_5
; %bb.4:                                ;   in Loop: Header=BB0_1 Depth=1
	LXI	D, 0xa001
	MOV	A, L
	XRA	E
	MOV	L, A
	MOV	A, H
	XRA	D
	MOV	H, A
.LBB0_5:                                ;   in Loop: Header=BB0_1 Depth=1
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
	JZ	.LBB0_7
; %bb.6:                                ;   in Loop: Header=BB0_1 Depth=1
	LXI	D, 0xa001
	MOV	A, L
	XRA	E
	MOV	L, A
	MOV	A, H
	XRA	D
	MOV	H, A
.LBB0_7:                                ;   in Loop: Header=BB0_1 Depth=1
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
	JZ	.LBB0_9
; %bb.8:                                ;   in Loop: Header=BB0_1 Depth=1
	LXI	D, 0xa001
	MOV	A, L
	XRA	E
	MOV	L, A
	MOV	A, H
	XRA	D
	MOV	H, A
.LBB0_9:                                ;   in Loop: Header=BB0_1 Depth=1
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
	JZ	.LBB0_11
; %bb.10:                               ;   in Loop: Header=BB0_1 Depth=1
	LXI	D, 0xa001
	MOV	A, L
	XRA	E
	MOV	L, A
	MOV	A, H
	XRA	D
	MOV	H, A
.LBB0_11:                               ;   in Loop: Header=BB0_1 Depth=1
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
	JZ	.LBB0_13
; %bb.12:                               ;   in Loop: Header=BB0_1 Depth=1
	LXI	D, 0xa001
	MOV	A, L
	XRA	E
	MOV	L, A
	MOV	A, H
	XRA	D
	MOV	H, A
.LBB0_13:                               ;   in Loop: Header=BB0_1 Depth=1
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
	JZ	.LBB0_15
; %bb.14:                               ;   in Loop: Header=BB0_1 Depth=1
	LXI	D, 0xa001
	MOV	A, L
	XRA	E
	MOV	L, A
	MOV	A, H
	XRA	D
	MOV	H, A
.LBB0_15:                               ;   in Loop: Header=BB0_1 Depth=1
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
	JZ	.LBB0_17
; %bb.16:                               ;   in Loop: Header=BB0_1 Depth=1
	LXI	D, 0xa001
	MOV	A, L
	XRA	E
	MOV	L, A
	MOV	A, H
	XRA	D
	MOV	H, A
.LBB0_17:                               ;   in Loop: Header=BB0_1 Depth=1
.LLo61_0:
	LXI	D, 0
	MOV	E, D
	MVI	D, 0
	MOV	A, L
	XRA	E
	MOV	L, A
	MOV	A, H
	XRA	D
	MOV	H, A
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
	JZ	.LBB0_19
; %bb.18:                               ;   in Loop: Header=BB0_1 Depth=1
	LXI	D, 0xa001
	MOV	A, L
	XRA	E
	MOV	L, A
	MOV	A, H
	XRA	D
	MOV	H, A
.LBB0_19:                               ;   in Loop: Header=BB0_1 Depth=1
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
	JZ	.LBB0_21
; %bb.20:                               ;   in Loop: Header=BB0_1 Depth=1
	LXI	D, 0xa001
	MOV	A, L
	XRA	E
	MOV	L, A
	MOV	A, H
	XRA	D
	MOV	H, A
.LBB0_21:                               ;   in Loop: Header=BB0_1 Depth=1
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
	JZ	.LBB0_23
; %bb.22:                               ;   in Loop: Header=BB0_1 Depth=1
	LXI	D, 0xa001
	MOV	A, L
	XRA	E
	MOV	L, A
	MOV	A, H
	XRA	D
	MOV	H, A
.LBB0_23:                               ;   in Loop: Header=BB0_1 Depth=1
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
	JZ	.LBB0_25
; %bb.24:                               ;   in Loop: Header=BB0_1 Depth=1
	LXI	D, 0xa001
	MOV	A, L
	XRA	E
	MOV	L, A
	MOV	A, H
	XRA	D
	MOV	H, A
.LBB0_25:                               ;   in Loop: Header=BB0_1 Depth=1
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
	JZ	.LBB0_27
; %bb.26:                               ;   in Loop: Header=BB0_1 Depth=1
	LXI	D, 0xa001
	MOV	A, L
	XRA	E
	MOV	L, A
	MOV	A, H
	XRA	D
	MOV	H, A
.LBB0_27:                               ;   in Loop: Header=BB0_1 Depth=1
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
	JZ	.LBB0_29
; %bb.28:                               ;   in Loop: Header=BB0_1 Depth=1
	LXI	D, 0xa001
	MOV	A, L
	XRA	E
	MOV	L, A
	MOV	A, H
	XRA	D
	MOV	H, A
.LBB0_29:                               ;   in Loop: Header=BB0_1 Depth=1
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
	JNZ	.LBB0_30
; %bb.31:                               ;   in Loop: Header=BB0_1 Depth=1
	MOV	D, B
	MOV	E, C
	JMP	.LBB0_32
.LBB0_30:                               ;   in Loop: Header=BB0_1 Depth=1
	MOV	D, B
	MOV	E, C
	LXI	B, 0xa001
	MOV	A, L
	XRA	C
	MOV	L, A
	MOV	A, H
	XRA	B
	MOV	H, A
.LBB0_32:                               ;   in Loop: Header=BB0_1 Depth=1
	LXI	B, 1
	MOV	A, L
	ANA	C
	MOV	C, A
	MOV	A, H
	ANA	B
	MOV	B, A
	MOV	A, H
	ORA	A
	RAR
	MOV	H, A
	MOV	A, L
	RAR
	MOV	L, A
	MOV	A, B
	ORA	C
	JZ	.LBB0_34
; %bb.33:                               ;   in Loop: Header=BB0_1 Depth=1
	MOV	B, H
	MOV	C, L
	LXI	H, 0xa001
	MOV	A, C
	XRA	L
	MOV	C, A
	MOV	A, B
	XRA	H
	MOV	B, A
	MOV	L, C
	MOV	H, B
	JMP	.LBB0_34
.LBB0_35:
	LHLD	.LLo61_2+1
	MOV	A, L
	OUT	0xed
	HLT
                                        ; -- End function
	.local	__v6c_a.main                    ; @__v6c_a.main
	.comm	__v6c_a.main,2,1
	.addrsig
	.addrsig_sym __v6c_a.main
