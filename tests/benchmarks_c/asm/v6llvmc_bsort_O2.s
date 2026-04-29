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
	SHLD	__v6c_ss.main+7
.LBB0_1:                                ; =>This Loop Header: Depth=1
                                        ;     Child Loop BB0_2 Depth 2
	LXI	H, __v6c_a.main
	SHLD	__v6c_ss.main+5
	LXI	H, 0
	SHLD	__v6c_ss.main+1
	LDA	__v6c_a.main
	STA	__v6c_ss.main
	LXI	H, __v6c_a.main
	SHLD	__v6c_ss.main+3
	LXI	D, __v6c_a.main
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
	.local	__v6c_ss.main                   ; @__v6c_ss.main
	.comm	__v6c_ss.main,9,1
	.addrsig
	.addrsig_sym __v6c_a.main
