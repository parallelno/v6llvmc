	.text
	.section	.text.main,"ax",@progbits
	.globl	main                            ; -- Begin function main
main:                                   ; @main
; %bb.0:
	LXI	H, a
	LXI	D, INIT
.LBB0_1:                                ; =>This Inner Loop Header: Depth=1
	LDAX	D
	MOV	M, A
	INX	H
	INX	D
	MVI	A, <(INIT+16)
	CMP	E
	JNZ	.LBB0_1
; %bb.11:                               ;   in Loop: Header=BB0_1 Depth=1
	MVI	A, >(INIT+16)
	CMP	D
	JNZ	.LBB0_1
; %bb.2:
	LXI	H, 0xf
	SHLD	__v6c_ss.main+7
.LBB0_3:                                ; =>This Loop Header: Depth=1
                                        ;     Child Loop BB0_4 Depth 2
	LXI	H, a
	SHLD	__v6c_ss.main+2
	LXI	H, 0
	SHLD	__v6c_ss.main
	LXI	H, a
	SHLD	__v6c_ss.main+4
	LXI	B, a
.LBB0_4:                                ;   Parent Loop BB0_3 Depth=1
                                        ; =>  This Inner Loop Header: Depth=2
	LHLD	__v6c_ss.main+2
	XCHG
	LDAX	D
	MOV	L, A
	INX	B
	LDAX	B
	PUSH	PSW
	MOV	A, L
	STA	__v6c_ss.main+6
	POP	PSW
	CMP	L
	MOV	H, B
	MOV	L, C
	JNC	.LBB0_6
; %bb.5:                                ;   in Loop: Header=BB0_4 Depth=2
	STAX	D
	PUSH	H
	LXI	H, __v6c_ss.main+4
	MOV	C, M
	INX	H
	MOV	B, M
	POP	H
	INX	B
	LDA	__v6c_ss.main+6
	STAX	B
.LBB0_6:                                ;   in Loop: Header=BB0_4 Depth=2
	INX	D
	XCHG
	SHLD	__v6c_ss.main+2
	LHLD	__v6c_ss.main
	XCHG
	INX	D
	SHLD	__v6c_ss.main+4
	MOV	B, H
	MOV	C, L
	LHLD	__v6c_ss.main+7
	XCHG
	SHLD	__v6c_ss.main
	XCHG
	MOV	A, L
	CMP	E
	JNZ	.LBB0_4
; %bb.12:                               ;   in Loop: Header=BB0_4 Depth=2
	MOV	A, H
	CMP	D
	JNZ	.LBB0_4
; %bb.7:                                ;   in Loop: Header=BB0_3 Depth=1
	LHLD	__v6c_ss.main+7
	DCX	H
	SHLD	__v6c_ss.main+7
	MOV	A, H
	ORA	L
	JNZ	.LBB0_3
; %bb.8:
	LXI	H, a
	MOV	E, A
.LBB0_9:                                ; =>This Inner Loop Header: Depth=1
	MOV	A, E
	ADD	M
	MOV	E, A
	INX	H
	MVI	A, <(a+16)
	CMP	L
	JNZ	.LBB0_9
; %bb.13:                               ;   in Loop: Header=BB0_9 Depth=1
	MVI	A, >(a+16)
	CMP	H
	JNZ	.LBB0_9
; %bb.10:
	MOV	A, E
	OUT	0xed
	HLT
                                        ; -- End function
	.section	.rodata.cst16,"aM",@progbits,16
INIT:                                   ; @INIT
	.ascii	"\r\310\007c*\001\372@\264\021X!\005\336d\233"

	.local	a                               ; @a
	.comm	a,16,1
	.local	__v6c_ss.main                   ; @__v6c_ss.main
	.comm	__v6c_ss.main,9,1
	.addrsig
