	.text
	.globl	fold_spill                      ; -- Begin function fold_spill
fold_spill:                             ; @fold_spill
; %bb.0:
	PUSH	H
	LXI	H, .LLo61_0+1
	MOV	M, B
	POP	H
.LLo61_0:
	XRI	0
	XRA	C
	XRA	D
	XRA	E
	XRA	L
	XRA	H
	LXI	H, 2
	DAD	SP
	XRA	M
	RET
                                        ; -- End function
