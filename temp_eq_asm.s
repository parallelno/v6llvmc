	.text
	.globl	cmp_eq_i16                      ; -- Begin function cmp_eq_i16
cmp_eq_i16:                             ; @cmp_eq_i16
; %bb.0:
	MOV	A, H
	CMP	D
	JNZ	.LBB0_2
	MOV	A, L
	CMP	E
	JNZ	.LBB0_2
	JMP	.LBB0_1
.LBB0_1:                                ; %then
	MVI	A, 1
	RET
.LBB0_2:                                ; %else
	MVI	A, 0
	RET
                                        ; -- End function
