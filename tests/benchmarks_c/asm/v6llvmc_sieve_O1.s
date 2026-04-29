	.text
	.section	.text.init_buf,"ax",@progbits
init_buf:                               ; -- Begin function init_buf
                                        ; @init_buf
; %bb.0:
	LXI	H, buf
.LBB0_1:                                ; =>This Inner Loop Header: Depth=1
	MVI	M, 1
	INX	H
	MVI	A, <(buf+252)
	CMP	L
	JNZ	.LBB0_1
; %bb.3:                                ;   in Loop: Header=BB0_1 Depth=1
	MVI	A, >(buf+252)
	CMP	H
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
	SHLD	__v6c_ss.cross_off
	CPI	0x7e
	RNC
.LBB1_1:
	LHLD	__v6c_ss.cross_off
	DAD	H
	LXI	B, buf
.LBB1_2:                                ; =>This Inner Loop Header: Depth=1
	XCHG
	LHLD	__v6c_ss.cross_off
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
	LXI	H, buf
	MVI	E, 0
.LBB2_1:                                ; =>This Inner Loop Header: Depth=1
	MOV	A, M
	ORA	A
	MVI	D, 0
	JZ	.LBB2_3
; %bb.2:                                ;   in Loop: Header=BB2_1 Depth=1
	INR	D
.LBB2_3:                                ;   in Loop: Header=BB2_1 Depth=1
	MOV	A, E
	ADD	D
	MOV	E, A
	INX	H
	MVI	A, <(buf+252)
	CMP	L
	JNZ	.LBB2_1
; %bb.5:                                ;   in Loop: Header=BB2_1 Depth=1
	MVI	A, >(buf+252)
	CMP	H
	JNZ	.LBB2_1
; %bb.4:
	MOV	A, E
	RET
                                        ; -- End function
	.section	.text.main,"ax",@progbits
	.globl	main                            ; -- Begin function main
main:                                   ; @main
; %bb.0:
	CALL	init_buf
	LXI	H, 2
	MOV	E, L
.LBB3_1:                                ; =>This Inner Loop Header: Depth=1
	SHLD	__v6c_ss.main
	LXI	B, buf
	DAD	B
	MOV	A, M
	ORA	A
	JZ	.LBB3_3
; %bb.2:                                ;   in Loop: Header=BB3_1 Depth=1
	MOV	A, E
	LXI	H, __v6c_ss.main+2
	MOV	M, E
	CALL	cross_off
	LXI	H, __v6c_ss.main+2
	MOV	E, M
.LBB3_3:                                ;   in Loop: Header=BB3_1 Depth=1
	INR	E
	LHLD	__v6c_ss.main
	INX	H
	MVI	A, 0x10
	CMP	L
	JNZ	.LBB3_1
; %bb.5:                                ;   in Loop: Header=BB3_1 Depth=1
	MVI	A, 0
	CMP	H
	JNZ	.LBB3_1
; %bb.4:
	CALL	count_set
	OUT	0xed
	HLT
                                        ; -- End function
	.local	buf                             ; @buf
	.comm	buf,252,1
	.local	__v6c_ss.cross_off              ; @__v6c_ss.cross_off
	.comm	__v6c_ss.cross_off,2,1
	.local	__v6c_ss.main                   ; @__v6c_ss.main
	.comm	__v6c_ss.main,3,1
	.addrsig
