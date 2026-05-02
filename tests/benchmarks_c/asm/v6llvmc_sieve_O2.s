	.text
	.section	.text.init_buf,"ax",@progbits
init_buf:                               ; -- Begin function init_buf
                                        ; @init_buf
; %bb.0:
	LXI	H, buf
	MVI	A, 0xfc
.LBB0_1:                                ; =>This Inner Loop Header: Depth=1
	MVI	M, 1
	INX	H
	DCR	A
	JNZ	.LBB0_1
; %bb.2:
	LXI	H, 0
	SHLD	buf
	RET
                                        ; -- End function
	.section	.text.cross_off,"ax",@progbits
cross_off:                              ; -- Begin function cross_off
                                        ; @cross_off
; %bb.0:
	MVI	L, 0
	MOV	H, L
	MOV	L, A
	SHLD	.LLo61_0+1
	CPI	0x7e
	RNC
.LBB1_1:
	LHLD	.LLo61_0+1
	DAD	H
	LXI	B, buf
.LBB1_2:                                ; =>This Inner Loop Header: Depth=1
.LLo61_0:
	LXI	D, 0
	XCHG
	DAD	D
	XCHG
	DAD	B
	MVI	M, 0
	MOV	H, D
	MOV	L, E
	MVI	A, 0xfb
	SUB	E
	MVI	A, 0
	SBB	D
	JNC	.LBB1_2
; %bb.3:
	RET
                                        ; -- End function
	.section	.text.count_set,"ax",@progbits
count_set:                              ; -- Begin function count_set
                                        ; @count_set
; %bb.0:
	XRA	A
	LXI	H, buf
	MVI	C, 0xfc
	JMP	.LBB2_1
.LBB2_3:                                ;   in Loop: Header=BB2_1 Depth=1
	MOV	A, D
	ADD	E
	MOV	D, A
	INX	H
	MOV	A, C
	DCR	A
	MOV	C, A
	MOV	A, D
	RZ
.LBB2_1:                                ; =>This Inner Loop Header: Depth=1
	MOV	D, A
	MOV	A, M
	ORA	A
	MVI	E, 0
	JZ	.LBB2_3
; %bb.2:                                ;   in Loop: Header=BB2_1 Depth=1
	INR	E
	JMP	.LBB2_3
                                        ; -- End function
	.section	.text.main,"ax",@progbits
	.globl	main                            ; -- Begin function main
main:                                   ; @main
; %bb.0:
	CALL	init_buf
	LDA	buf+2
	ORA	A
	JZ	.LBB3_2
; %bb.1:
	MVI	A, 2
	CALL	cross_off
.LBB3_2:
	LDA	buf+3
	ORA	A
	JZ	.LBB3_4
; %bb.3:
	MVI	A, 3
	CALL	cross_off
.LBB3_4:
	LDA	buf+4
	ORA	A
	JZ	.LBB3_6
; %bb.5:
	MVI	A, 4
	CALL	cross_off
.LBB3_6:
	LDA	buf+5
	ORA	A
	JZ	.LBB3_8
; %bb.7:
	MVI	A, 5
	CALL	cross_off
.LBB3_8:
	LDA	buf+6
	ORA	A
	JZ	.LBB3_10
; %bb.9:
	MVI	A, 6
	CALL	cross_off
.LBB3_10:
	LDA	buf+7
	ORA	A
	JZ	.LBB3_12
; %bb.11:
	MVI	A, 7
	CALL	cross_off
.LBB3_12:
	LDA	buf+8
	ORA	A
	JZ	.LBB3_14
; %bb.13:
	MVI	A, 8
	CALL	cross_off
.LBB3_14:
	LDA	buf+9
	ORA	A
	JZ	.LBB3_16
; %bb.15:
	MVI	A, 9
	CALL	cross_off
.LBB3_16:
	LDA	buf+10
	ORA	A
	JZ	.LBB3_18
; %bb.17:
	MVI	A, 0xa
	CALL	cross_off
.LBB3_18:
	LDA	buf+11
	ORA	A
	JZ	.LBB3_20
; %bb.19:
	MVI	A, 0xb
	CALL	cross_off
.LBB3_20:
	LDA	buf+12
	ORA	A
	JZ	.LBB3_22
; %bb.21:
	MVI	A, 0xc
	CALL	cross_off
.LBB3_22:
	LDA	buf+13
	ORA	A
	JZ	.LBB3_24
; %bb.23:
	MVI	A, 0xd
	CALL	cross_off
.LBB3_24:
	LDA	buf+14
	ORA	A
	JZ	.LBB3_26
; %bb.25:
	MVI	A, 0xe
	CALL	cross_off
.LBB3_26:
	LDA	buf+15
	ORA	A
	JZ	.LBB3_28
; %bb.27:
	MVI	A, 0xf
	CALL	cross_off
.LBB3_28:
	CALL	count_set
	OUT	0xed
	HLT
                                        ; -- End function
	.local	buf                             ; @buf
	.comm	buf,252,1
	.addrsig
