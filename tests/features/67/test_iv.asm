	.text
	.text
	.globl	extra_pn_uses                   ; -- Begin function extra_pn_uses
extra_pn_uses:                          ; @extra_pn_uses
; %bb.0:                                ; %entry
	MVI	L, 0
	MOV	H, L
	MOV	L, A
	LXI	D, 0
.LBB0_1:                                ; %loop
                                        ; =>This Inner Loop Header: Depth=1
	MOV	A, L
	XRA	E
	MOV	C, A
	MOV	A, H
	XRA	D
	MOV	B, A
	DAD	B
	INX	D
	MVI	A, 0x40
	CMP	E
	JNZ	.LBB0_1
; %bb.3:                                ; %loop
                                        ;   in Loop: Header=BB0_1 Depth=1
	XRA	A
	CMP	D
	JNZ	.LBB0_1
; %bb.2:                                ; %exit
	RET
                                        ; -- End function
	.globl	extra_add_uses                  ; -- Begin function extra_add_uses
extra_add_uses:                         ; @extra_add_uses
; %bb.0:                                ; %entry
	MVI	L, 0
	MOV	H, L
	MOV	L, A
	LXI	D, 1
.LBB1_1:                                ; %loop
                                        ; =>This Inner Loop Header: Depth=1
	MOV	A, L
	XRA	E
	MOV	C, A
	MOV	A, H
	XRA	D
	MOV	B, A
	DAD	B
	INX	D
	MVI	A, 0x41
	CMP	E
	JNZ	.LBB1_1
; %bb.3:                                ; %loop
                                        ;   in Loop: Header=BB1_1 Depth=1
	XRA	A
	CMP	D
	JNZ	.LBB1_1
; %bb.2:                                ; %exit
	RET
                                        ; -- End function
	.globl	down_counter_extra_pn           ; -- Begin function down_counter_extra_pn
down_counter_extra_pn:                  ; @down_counter_extra_pn
; %bb.0:                                ; %entry
	MVI	L, 0
	MOV	H, L
	MOV	L, A
	LXI	D, 0x3f
.LBB2_1:                                ; %loop
                                        ; =>This Inner Loop Header: Depth=1
	MOV	A, L
	XRA	E
	MOV	C, A
	MOV	A, H
	XRA	D
	MOV	B, A
	DAD	B
	DCX	D
	MOV	A, D
	ORA	E
	JNZ	.LBB2_1
; %bb.2:                                ; %exit
	RET
                                        ; -- End function
	.globl	phi_user_rejected               ; -- Begin function phi_user_rejected
phi_user_rejected:                      ; @phi_user_rejected
; %bb.0:                                ; %entry
	LXI	H, 0xffff
.LBB3_1:                                ; %loop
                                        ; =>This Inner Loop Header: Depth=1
	INX	H
	MVI	A, 0x3f
	CMP	L
	JNZ	.LBB3_1
; %bb.3:                                ; %loop
                                        ;   in Loop: Header=BB3_1 Depth=1
	XRA	A
	CMP	H
	JNZ	.LBB3_1
; %bb.2:                                ; %exit
	RET
                                        ; -- End function
	.globl	no_icmp_extra_pn                ; -- Begin function no_icmp_extra_pn
no_icmp_extra_pn:                       ; @no_icmp_extra_pn
; %bb.0:                                ; %entry
	MVI	L, 0
	MOV	H, L
	MOV	L, A
	LXI	D, 1
.LBB4_1:                                ; %loop
                                        ; =>This Inner Loop Header: Depth=1
	XCHG
	SHLD	.LLo61_0+1
	SHLD	.LLo61_1+1
	XCHG
.LLo61_0:
	LXI	B, 0
	DCX	B
	MOV	A, L
	XRA	C
	MOV	C, A
	MOV	A, H
	XRA	B
	MOV	B, A
	DAD	B
	INX	D
.LLo61_1:
	LXI	B, 0
	MOV	A, B
	ORA	C
	JNZ	.LBB4_1
; %bb.2:                                ; %exit
	RET
                                        ; -- End function
	.section	.bss,"aw",@nobits
	.globl	arr_e                           ; @arr_e
arr_e:

