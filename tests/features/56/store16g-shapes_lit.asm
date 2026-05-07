	.text
	.text
	.globl	case1_val_hl                    ; -- Begin function case1_val_hl
case1_val_hl:                           ; @case1_val_hl
; %bb.0:
	SHLD	g
	RET
                                        ; -- End function
	.globl	case2a_val_de_hl_dead           ; -- Begin function case2a_val_de_hl_dead
case2a_val_de_hl_dead:                  ; @case2a_val_de_hl_dead
; %bb.0:
	XCHG
	SHLD	g
	RET
                                        ; -- End function
	.globl	case2b_val_de_hl_live           ; -- Begin function case2b_val_de_hl_live
case2b_val_de_hl_live:                  ; @case2b_val_de_hl_live
; %bb.0:
	XCHG
	SHLD	g
	XCHG
	RET
                                        ; -- End function
	.globl	case3a_val_bc_hl_dead           ; -- Begin function case3a_val_bc_hl_dead
case3a_val_bc_hl_dead:                  ; @case3a_val_bc_hl_dead
; %bb.0:
	MOV	H, B
	MOV	L, C
	SHLD	g
	RET
                                        ; -- End function
	.globl	case3b_val_bc_a_dead            ; -- Begin function case3b_val_bc_a_dead
case3b_val_bc_a_dead:                   ; @case3b_val_bc_a_dead
; %bb.0:
	MOV	A, C
	STA	g
	MOV	A, B
	STA	g+1
	RET
                                        ; -- End function
	.globl	case3c_val_bc_a_live            ; -- Begin function case3c_val_bc_a_live
case3c_val_bc_a_live:                   ; @case3c_val_bc_a_live
; %bb.0:
	PUSH	H
	MOV	H, B
	MOV	L, C
	SHLD	g
	POP	H
	JMP	sink3_i16_i8
                                        ; -- End function
