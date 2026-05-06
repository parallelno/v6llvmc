	.text
	.section	.text.__mulqi3,"ax",@progbits
__mulqi3:                               ; -- Begin function __mulqi3
                                        ; @__mulqi3
	;=== char __mulqi3(char arg0, char arg1) ===
	;  arg0 = A
	;  arg1 = E
; %bb.0:
	;APP
	MOV	E, B
	MVI	D, 0
	LXI	H, 0
	MVI	B, 8
.Ltmp0:
	DAD	H
	RLC

	JNC	.Ltmp1
	DAD	D
.Ltmp1:
	DCR	B
	JNZ	.Ltmp0
	MOV	A, L
	RET


	;NO_APP
                                        ; -- End function
	.section	.text.__v6c_mulqihi3,"ax",@progbits
__v6c_mulqihi3:                         ; -- Begin function __v6c_mulqihi3
                                        ; @__v6c_mulqihi3
	;=== int __v6c_mulqihi3(char arg0, char arg1) ===
	;  arg0 = A
	;  arg1 = E
; %bb.0:
	;APP
	MOV	E, B
	MVI	D, 0
	LXI	H, 0
	MVI	B, 8
.Ltmp2:
	DAD	H
	RLC

	JNC	.Ltmp3
	DAD	D
.Ltmp3:
	DCR	B
	JNZ	.Ltmp2
	RET


	;NO_APP
                                        ; -- End function
	.section	.text.__mulhi3,"ax",@progbits
__mulhi3:                               ; -- Begin function __mulhi3
                                        ; @__mulhi3
	;=== int __mulhi3(int arg0, int arg1) ===
	;  arg0 = HL
	;  arg1 = DE
; %bb.0:
	;APP
	XCHG

	MOV	A, H
	MOV	C, L
	LXI	H, 0
	MVI	B, 8
.Ltmp4:
	DAD	H
	RLC

	JNC	.Ltmp5
	DAD	D
.Ltmp5:
	DCR	B
	JNZ	.Ltmp4
	MOV	A, C
	MVI	B, 8
.Ltmp6:
	DAD	H
	RLC

	JNC	.Ltmp7
	DAD	D
.Ltmp7:
	DCR	B
	JNZ	.Ltmp6
	RET


	;NO_APP
                                        ; -- End function
	.section	.text.__v6c_udivmod16_body,"ax",@progbits
__v6c_udivmod16_body:                   ; -- Begin function __v6c_udivmod16_body
                                        ; @__v6c_udivmod16_body
	;=== void __v6c_udivmod16_body(void) ===
; %bb.0:
	;APP
	MOV	A, D
	ORA	E
	JNZ	.Ltmp8
	LXI	H, 0xffff
	LXI	B, 0
	RET

.Ltmp8:
	LXI	B, 0
	MVI	A, 0x10
	PUSH	PSW
.Ltmp9:
	DAD	H
	MOV	A, C
	RAL

	MOV	C, A
	MOV	A, B
	RAL

	MOV	B, A
	MOV	A, C
	SUB	E
	MOV	A, B
	SBB	D
	JC	.Ltmp10
	MOV	A, C
	SUB	E
	MOV	C, A
	MOV	A, B
	SBB	D
	MOV	B, A
	INX	H
.Ltmp10:
	POP	PSW
	DCR	A
	PUSH	PSW
	JNZ	.Ltmp9
	POP	PSW
	RET


	;NO_APP
                                        ; -- End function
	.section	.text.__udivhi3,"ax",@progbits
__udivhi3:                              ; -- Begin function __udivhi3
                                        ; @__udivhi3
	;=== int __udivhi3(int arg0, int arg1) ===
	;  arg0 = HL
	;  arg1 = DE
; %bb.0:
	;APP
	CALL	__v6c_udivmod16_body
	RET


	;NO_APP
                                        ; -- End function
	.section	.text.__umodhi3,"ax",@progbits
__umodhi3:                              ; -- Begin function __umodhi3
                                        ; @__umodhi3
	;=== int __umodhi3(int arg0, int arg1) ===
	;  arg0 = HL
	;  arg1 = DE
; %bb.0:
	;APP
	CALL	__v6c_udivmod16_body
	MOV	H, B
	MOV	L, C
	RET


	;NO_APP
                                        ; -- End function
	.section	.text.__udivmodhi4,"ax",@progbits
__udivmodhi4:                           ; -- Begin function __udivmodhi4
                                        ; @__udivmodhi4
	;=== int __udivmodhi4(int arg0, int arg1, void* arg2) ===
	;  arg0 = HL
	;  arg1 = DE
	;  arg2 = BC
; %bb.0:
	;APP
	PUSH	B
	CALL	__v6c_udivmod16_body
	XTHL

	MOV	M, C
	INX	H
	MOV	M, B
	POP	H
	RET


	;NO_APP
                                        ; -- End function
	.section	.text.__divmodhi4,"ax",@progbits
__divmodhi4:                            ; -- Begin function __divmodhi4
                                        ; @__divmodhi4
	;=== int __divmodhi4(int arg0, int arg1, void* arg2) ===
	;  arg0 = HL
	;  arg1 = DE
	;  arg2 = BC
; %bb.0:
	;APP
	PUSH	B
	MOV	A, H
	PUSH	PSW
	MOV	A, H
	XRA	D
	PUSH	PSW
	MOV	A, H
	ORA	A
	JP	.Ltmp11
	CALL	__v6c_neg_hl_body
.Ltmp11:
	MOV	A, D
	ORA	A
	JP	.Ltmp12
	CALL	__v6c_neg_de_body
.Ltmp12:
	CALL	__v6c_udivmod16_body
	POP	PSW
	ORA	A
	JP	.Ltmp13
	CALL	__v6c_neg_hl_body
.Ltmp13:
	POP	PSW
	ORA	A
	JP	.Ltmp14
	MOV	A, C
	CMA

	MOV	C, A
	MOV	A, B
	CMA

	MOV	B, A
	INX	B
.Ltmp14:
	XTHL

	MOV	M, C
	INX	H
	MOV	M, B
	POP	H
	RET


	;NO_APP
                                        ; -- End function
	.section	.text.__v6c_neg_hl_body,"ax",@progbits
__v6c_neg_hl_body:                      ; -- Begin function __v6c_neg_hl_body
                                        ; @__v6c_neg_hl_body
	;=== void __v6c_neg_hl_body(void) ===
; %bb.0:
	;APP
	MOV	A, L
	CMA

	MOV	L, A
	MOV	A, H
	CMA

	MOV	H, A
	INX	H
	RET


	;NO_APP
                                        ; -- End function
	.section	.text.__v6c_neg_de_body,"ax",@progbits
__v6c_neg_de_body:                      ; -- Begin function __v6c_neg_de_body
                                        ; @__v6c_neg_de_body
	;=== void __v6c_neg_de_body(void) ===
; %bb.0:
	;APP
	MOV	A, E
	CMA

	MOV	E, A
	MOV	A, D
	CMA

	MOV	D, A
	INX	D
	RET


	;NO_APP
                                        ; -- End function
	.section	.text.__divhi3,"ax",@progbits
__divhi3:                               ; -- Begin function __divhi3
                                        ; @__divhi3
	;=== int __divhi3(int arg0, int arg1) ===
	;  arg0 = HL
	;  arg1 = DE
; %bb.0:
	;APP
	MOV	A, H
	XRA	D
	PUSH	PSW
	MOV	A, H
	ORA	A
	JP	.Ltmp15
	CALL	__v6c_neg_hl_body
.Ltmp15:
	MOV	A, D
	ORA	A
	JP	.Ltmp16
	CALL	__v6c_neg_de_body
.Ltmp16:
	CALL	__v6c_udivmod16_body
	POP	PSW
	ORA	A
	JP	.Ltmp17
	CALL	__v6c_neg_hl_body
.Ltmp17:
	RET


	;NO_APP
                                        ; -- End function
	.section	.text.__modhi3,"ax",@progbits
__modhi3:                               ; -- Begin function __modhi3
                                        ; @__modhi3
	;=== int __modhi3(int arg0, int arg1) ===
	;  arg0 = HL
	;  arg1 = DE
; %bb.0:
	;APP
	MOV	A, H
	PUSH	PSW
	ORA	A
	JP	.Ltmp18
	CALL	__v6c_neg_hl_body
.Ltmp18:
	MOV	A, D
	ORA	A
	JP	.Ltmp19
	CALL	__v6c_neg_de_body
.Ltmp19:
	CALL	__v6c_udivmod16_body
	MOV	H, B
	MOV	L, C
	POP	PSW
	ORA	A
	JP	.Ltmp20
	CALL	__v6c_neg_hl_body
.Ltmp20:
	RET


	;NO_APP
                                        ; -- End function
	.section	.text.__ashlhi3,"ax",@progbits
__ashlhi3:                              ; -- Begin function __ashlhi3
                                        ; @__ashlhi3
	;=== int __ashlhi3(int arg0, char arg1) ===
	;  arg0 = HL
	;  arg1 = E
; %bb.0:
	;APP
	MOV	A, E
	ANI	0xf
	JZ	.Ltmp21
	CPI	0x10
	JNC	.Ltmp22
	MOV	E, A
.Ltmp23:
	DAD	H
	DCR	E
	JNZ	.Ltmp23
.Ltmp21:
	RET

.Ltmp22:
	LXI	H, 0
	RET


	;NO_APP
                                        ; -- End function
	.section	.text.__lshrhi3,"ax",@progbits
__lshrhi3:                              ; -- Begin function __lshrhi3
                                        ; @__lshrhi3
	;=== int __lshrhi3(int arg0, char arg1) ===
	;  arg0 = HL
	;  arg1 = E
; %bb.0:
	;APP
	MOV	A, E
	ANI	0xf
	JZ	.Ltmp24
	CPI	0x10
	JNC	.Ltmp25
	MOV	E, A
.Ltmp26:
	ORA	A
	MOV	A, H
	RAR

	MOV	H, A
	MOV	A, L
	RAR

	MOV	L, A
	DCR	E
	JNZ	.Ltmp26
.Ltmp24:
	RET

.Ltmp25:
	LXI	H, 0
	RET


	;NO_APP
                                        ; -- End function
	.section	.text.__ashrhi3,"ax",@progbits
__ashrhi3:                              ; -- Begin function __ashrhi3
                                        ; @__ashrhi3
	;=== int __ashrhi3(int arg0, char arg1) ===
	;  arg0 = HL
	;  arg1 = E
; %bb.0:
	;APP
	MOV	A, E
	ANI	0xf
	JZ	.Ltmp27
	CPI	0x10
	JNC	.Ltmp28
	MOV	E, A
.Ltmp29:
	MOV	A, H
	RAL

	MOV	A, H
	RAR

	MOV	H, A
	MOV	A, L
	RAR

	MOV	L, A
	DCR	E
	JNZ	.Ltmp29
.Ltmp27:
	RET

.Ltmp28:
	MOV	A, H
	RAL

	SBB	A
	MOV	H, A
	MOV	L, A
	RET


	;NO_APP
                                        ; -- End function
	.section	.text.error_stack_arg,"ax",@progbits
	.globl	error_stack_arg                 ; -- Begin function error_stack_arg
error_stack_arg:                        ; @error_stack_arg
	;=== int error_stack_arg(int arg0, int arg1, int arg2, int arg3, int arg4) ===
	;  arg0 = HL
	;  arg1 = DE
	;  arg2 = BC
	;  arg3 = stack
	;  arg4 = stack
; %bb.0:
	;--- V6C_ADD16 ---
	DAD	D
	;--- V6C_ADD16 ---
	DAD	B
	XCHG
	;--- V6C_LOAD16_FI ---
	LXI	H, 2
	DAD	SP
	MOV	C, M
	INX	H
	MOV	B, M
	;--- V6C_ADD16 ---
	XCHG
	DAD	B
	XCHG
	;--- V6C_LOAD16_FI ---
	LXI	H, 4
	DAD	SP
	MOV	C, M
	INX	H
	MOV	B, M
	;--- V6C_ADD16 ---
	XCHG
	DAD	B
	RET
                                        ; -- End function
	.section	.text.main,"ax",@progbits
	.globl	main                            ; -- Begin function main
main:                                   ; @main
	;=== int main(int arg0, void* arg1) ===
	;  arg0 = HL
	;  arg1 = DE
; %bb.0:
	PUSH	PSW
	PUSH	PSW
	;--- V6C_LOAD16_G ---
	LHLD	i_p
	;--- V6C_SPILL16 ---
	SHLD	.LLo61_0+1
	;--- V6C_LOAD16_G ---
	LHLD	i_p+2
	;--- V6C_SPILL16 ---
	SHLD	.LLo61_2+1
	;--- V6C_LOAD16_G ---
	LHLD	i_p+4
	;--- V6C_SPILL16 ---
	SHLD	.LLo61_1+1
	;--- V6C_LOAD16_G ---
	XCHG
	LHLD	i_p+6
	XCHG
	;--- V6C_LOAD16_G ---
	LHLD	i_p+8
	MOV	B, H
	MOV	C, L
	LXI	H, 0
	DAD	SP
	;--- V6C_STORE16_P ---
	MOV	M, E
	INX	H
	MOV	M, D
	DCX	H
	;--- V6C_INX16 ---
	INX	H
	INX	H
	;--- V6C_STORE16_P ---
	MOV	M, C
	INX	H
	MOV	M, B
	;--- V6C_RELOAD16 ---
.LLo61_0:
	LXI	H, 0
	;--- V6C_RELOAD16 ---
.LLo61_2:
	LXI	D, 0
	;--- V6C_RELOAD16 ---
.LLo61_1:
	LXI	B, 0
	CALL	error_stack_arg
	MOV	A, L
	OUT	0xed
	;--- V6C_LOAD16_G ---
	LHLD	i_p
	;--- V6C_LOAD16_G ---
	XCHG
	LHLD	i_p+2
	;--- V6C_ADD16 ---
	DAD	H
	XCHG
	;--- V6C_ADD16 ---
	DAD	D
	MOV	A, L
	OUT	0xed
	HLT
	LXI	H, 0
	POP	PSW
	POP	PSW
	RET
                                        ; -- End function
	.data
	.globl	i_p                             ; @i_p
i_p:
	DW	1                               ; 0x1
	DW	2                               ; 0x2
	DW	3                               ; 0x3
	DW	4                               ; 0x4
	DW	5                               ; 0x5

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
	.addrsig_sym i_p
