	.text
	.section	.text.init_buf,"ax",@progbits
init_buf:                               ; -- Begin function init_buf
                                        ; @init_buf
; %bb.0:
	LXI	H, buf
	MVI	A, 0xfc
.LBB15_1:                               ; =>This Inner Loop Header: Depth=1
	DCR	A
	MVI	M, 1
	INX	H
	JNZ	.LBB15_1
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
.LBB16_1:
	LHLD	.LLo61_0+1
	DAD	H
	LXI	B, buf
.LBB16_2:                               ; =>This Inner Loop Header: Depth=1
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
	JNC	.LBB16_2
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
	JMP	.LBB17_1
.LBB17_3:                               ;   in Loop: Header=BB17_1 Depth=1
	MOV	A, D
	ADD	E
	MOV	D, A
	MOV	A, C
	DCR	A
	MOV	C, A
	MOV	A, D
	INX	H
	RZ
.LBB17_1:                               ; =>This Inner Loop Header: Depth=1
	MOV	D, A
	MOV	A, M
	ORA	A
	MVI	E, 0
	JZ	.LBB17_3
; %bb.2:                                ;   in Loop: Header=BB17_1 Depth=1
	INR	E
	JMP	.LBB17_3
                                        ; -- End function
	.section	.text.main,"ax",@progbits
	.globl	main                            ; -- Begin function main
main:                                   ; @main
; %bb.0:
	CALL	init_buf
	MVI	A, 2
	LXI	H, buf+2
	JMP	.LBB18_1
.LBB18_3:                               ;   in Loop: Header=BB18_1 Depth=1
	INX	H
.LLo61_2:
	MVI	A, 0
	INR	A
	CPI	0x10
	JZ	.LBB18_4
.LBB18_1:                               ; =>This Inner Loop Header: Depth=1
	STA	.LLo61_2+1
	MOV	A, M
	ORA	A
	JZ	.LBB18_3
; %bb.2:                                ;   in Loop: Header=BB18_1 Depth=1
	LDA	.LLo61_2+1
	SHLD	.LLo61_1+1
	CALL	cross_off
.LLo61_1:
	LXI	H, 0
	JMP	.LBB18_3
.LBB18_4:
	CALL	count_set
	OUT	0xed
	HLT
                                        ; -- End function
	.local	buf                             ; @buf
	.comm	buf,252,1
	.addrsig
	.addrsig_sym __mulqi3
	.addrsig_sym __v6c_mulqihi3
	.addrsig_sym __mulhi3
	.addrsig_sym __v6c_udivmod16_body
	.addrsig_sym __udivhi3
	.addrsig_sym __umodhi3
	.addrsig_sym __udivmodhi4
	.addrsig_sym __divmodhi4
	.addrsig_sym __v6c_neg_hl_body
	.addrsig_sym __v6c_neg_de_body
	.addrsig_sym __divhi3
	.addrsig_sym __modhi3
	.addrsig_sym __ashlhi3
	.addrsig_sym __lshrhi3
	.addrsig_sym __ashrhi3
