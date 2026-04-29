	.text
	.section	.text.main,"ax",@progbits
	.globl	main                            ; -- Begin function main
main:                                   ; @main
; %bb.0:
	LXI	H, __v6c_a.main
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
	LXI	H, __v6c_a.main
	SHLD	__v6c_ss.main+5
	LXI	H, 0
	SHLD	__v6c_ss.main+1
	LDA	__v6c_a.main
	STA	__v6c_ss.main
	LXI	H, __v6c_a.main
	SHLD	__v6c_ss.main+3
	LXI	D, __v6c_a.main
.LBB0_4:                                ;   Parent Loop BB0_3 Depth=1
                                        ; =>  This Inner Loop Header: Depth=2
	INX	D
	LDAX	D
	LXI	H, __v6c_ss.main
	CMP	M
	LHLD	__v6c_ss.main+3
	XCHG
	JNC	.LBB0_6
; %bb.5:                                ;   in Loop: Header=BB0_4 Depth=2
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
.LBB0_6:                                ;   in Loop: Header=BB0_4 Depth=2
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
	JNZ	.LBB0_4
; %bb.12:                               ;   in Loop: Header=BB0_4 Depth=2
	MOV	A, H
	CMP	B
	JNZ	.LBB0_4
; %bb.7:                                ;   in Loop: Header=BB0_3 Depth=1
	LHLD	__v6c_ss.main+7
	DCX	H
	SHLD	__v6c_ss.main+7
	MOV	A, H
	ORA	L
	JNZ	.LBB0_3
; %bb.8:
	LXI	H, __v6c_a.main
	MOV	C, A
	LXI	D, __v6c_a.main+16
.LBB0_9:                                ; =>This Inner Loop Header: Depth=1
	MOV	A, C
	ADD	M
	MOV	C, A
	INX	H
	MOV	A, L
	CMP	E
	JNZ	.LBB0_9
; %bb.13:                               ;   in Loop: Header=BB0_9 Depth=1
	MOV	A, H
	CMP	D
	JNZ	.LBB0_9
; %bb.10:
	MOV	A, C
	OUT	0xed
	HLT
                                        ; -- End function
	.section	.rodata.cst16,"aM",@progbits,16
INIT:                                   ; @INIT
	.ascii	"\r\310\007c*\001\372@\264\021X!\005\336d\233"

	.local	__v6c_a.main                    ; @__v6c_a.main
	.comm	__v6c_a.main,16,1
	.local	__v6c_ss.main                   ; @__v6c_ss.main
	.comm	__v6c_ss.main,9,1
	.addrsig
	.addrsig_sym __v6c_a.main
