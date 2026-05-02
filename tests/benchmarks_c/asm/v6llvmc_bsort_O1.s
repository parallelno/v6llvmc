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
	SHLD	.LLo61_2+1
.LBB0_3:                                ; =>This Loop Header: Depth=1
                                        ;     Child Loop BB0_4 Depth 2
	LXI	H, __v6c_a.main
	SHLD	.LLo61_3+1
	LXI	H, 0
	SHLD	.LLo61_0+1
	LXI	H, __v6c_a.main
	SHLD	.LLo61_1+1
	LXI	B, __v6c_a.main
.LBB0_4:                                ;   Parent Loop BB0_3 Depth=1
                                        ; =>  This Inner Loop Header: Depth=2
.LLo61_3:
	LXI	D, 0
	LDAX	D
	MOV	L, A
	INX	B
	LDAX	B
	PUSH	PSW
	MOV	A, L
	STA	.LLo61_4+1
	POP	PSW
	CMP	L
	MOV	H, B
	MOV	L, C
	JNC	.LBB0_6
; %bb.5:                                ;   in Loop: Header=BB0_4 Depth=2
	STAX	D
.LLo61_1:
	LXI	B, 0
	INX	B
.LLo61_4:
	MVI	A, 0
	STAX	B
.LBB0_6:                                ;   in Loop: Header=BB0_4 Depth=2
	INX	D
	XCHG
	SHLD	.LLo61_3+1
	XCHG
.LLo61_0:
	LXI	D, 0
	INX	D
	SHLD	.LLo61_1+1
	MOV	B, H
	MOV	C, L
.LLo61_2:
	LXI	H, 0
	XCHG
	SHLD	.LLo61_0+1
	XCHG
	MOV	A, L
	CMP	E
	JNZ	.LBB0_4
; %bb.12:                               ;   in Loop: Header=BB0_4 Depth=2
	MOV	A, H
	CMP	D
	JNZ	.LBB0_4
; %bb.7:                                ;   in Loop: Header=BB0_3 Depth=1
	LHLD	.LLo61_2+1
	DCX	H
	SHLD	.LLo61_2+1
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
	.addrsig
	.addrsig_sym __v6c_a.main
