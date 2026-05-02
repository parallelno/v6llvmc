	.text
	.section	.text.load8_stack_arg,"ax",@progbits
	.globl	load8_stack_arg                 ; -- Begin function load8_stack_arg
load8_stack_arg:                        ; @load8_stack_arg
	;=== char load8_stack_arg(char arg0, char arg1, char arg2, char arg3, char arg4, char arg5, char arg6, char arg7) ===
	;  arg0 = A
	;  arg1 = E
	;  arg2 = C
	;  arg3 = stack
	;  arg4 = stack
	;  arg5 = stack
	;  arg6 = stack
	;  arg7 = stack
; %bb.0:
	;--- V6C_LOAD8_FI ---
	LXI	H, 2
	DAD	SP
	MOV	A, M
	RET
                                        ; -- End function
	.section	.text.load16_stack_arg,"ax",@progbits
	.globl	load16_stack_arg                ; -- Begin function load16_stack_arg
load16_stack_arg:                       ; @load16_stack_arg
	;=== int load16_stack_arg(int arg0, int arg1, int arg2, int arg3) ===
	;  arg0 = HL
	;  arg1 = DE
	;  arg2 = BC
	;  arg3 = stack
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
	RET
                                        ; -- End function
	.section	.text.store8_local,"ax",@progbits
	.globl	store8_local                    ; -- Begin function store8_local
store8_local:                           ; @store8_local
	;=== char store8_local(char arg0) ===
	;  arg0 = A
; %bb.0:
	LXI	H, 0xffff
	DAD	SP
	SPHL
	;--- V6C_STORE8_FI ---
	LXI	H, 0
	DAD	SP
	MOV	M, A
	;--- V6C_LOAD8_FI ---
	LXI	H, 0
	DAD	SP
	MOV	A, M
	LXI	H, 1
	DAD	SP
	SPHL
	RET
                                        ; -- End function
	.section	.text.store16_local,"ax",@progbits
	.globl	store16_local                   ; -- Begin function store16_local
store16_local:                          ; @store16_local
	;=== int store16_local(int arg0) ===
	;  arg0 = HL
; %bb.0:
	XCHG
	PUSH	PSW
	XCHG
	MOV	B, H
	MOV	C, L
	;--- V6C_STORE16_FI ---
	LXI	H, 0
	DAD	SP
	MOV	M, C
	INX	H
	MOV	M, B
	;--- V6C_LOAD16_FI ---
	LXI	H, 0
	DAD	SP
	MOV	E, M
	INX	H
	MOV	D, M
	POP	PSW
	XCHG
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
	MVI	A, 8
	STA	g8
	LXI	H, 0
	DAD	SP
	LXI	D, 4
	;--- V6C_STORE16_P ---
	MOV	M, E
	INX	H
	MOV	M, D
	LXI	H, 1
	LXI	D, 2
	LXI	B, 3
	CALL	load16_stack_arg
	PUSH	H
	LDA	g8
	CALL	store8_local
	STA	g8
	;--- V6C_LOAD16_G ---
	POP	H
	CALL	store16_local
	PUSH	H
	LDA	g8
	OUT	0xed
	;--- V6C_LOAD16_G ---
	POP	H
	MOV	A, L
	OUT	0xed
	HLT
	LXI	H, 0
	XCHG
	POP	PSW
	XCHG
	RET
                                        ; -- End function
	.section	.bss,"aw",@nobits
	.globl	g8                              ; @g8
g8:
	DB	0                               ; 0x0

	.globl	g16                             ; @g16
g16:
	DW	0                               ; 0x0

	.addrsig
	.addrsig_sym g8
	.addrsig_sym g16
