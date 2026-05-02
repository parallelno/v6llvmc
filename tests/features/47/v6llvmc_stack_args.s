	.text
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
	.section	.text.add_de_de,"ax",@progbits
	.globl	add_de_de                       ; -- Begin function add_de_de
add_de_de:                              ; @add_de_de
	;=== int add_de_de(int arg0, int arg1) ===
	;  arg0 = HL
	;  arg1 = DE
; %bb.0:
	;--- V6C_ADD16 ---
	MOV	A, E
	ADD	E
	MOV	E, A
	MOV	A, D
	ADC	D
	MOV	D, A
	;--- V6C_ADD16 ---
	DAD	D
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
	SHLD	.LLo61_0+1
	;--- V6C_LOAD16_G ---
	LHLD	i_p+2
	SHLD	.LLo61_2+1
	;--- V6C_LOAD16_G ---
	LHLD	i_p+4
	SHLD	.LLo61_1+1
	;--- V6C_LOAD16_G ---
	LHLD	i_p+6
	;--- V6C_LOAD16_G ---
	PUSH	H
	LHLD	i_p+8
	MOV	B, H
	MOV	C, L
	POP	H
	PUSH	H
	LXI	H, 2
	DAD	SP
	XCHG
	POP	H
	;--- V6C_STORE16_P ---
	PUSH	D
	MOV	A, L
	STAX	D
	INX	D
	MOV	A, H
	STAX	D
	POP	D
	;--- V6C_INX16 ---
	INX	D
	INX	D
	;--- V6C_STORE16_P ---
	XCHG
	MOV	M, C
	INX	H
	MOV	M, B
.LLo61_0:
	LXI	H, 0
.LLo61_2:
	LXI	D, 0
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
	XCHG
	;--- V6C_ADD16 ---
	MOV	A, E
	ADD	E
	MOV	E, A
	MOV	A, D
	ADC	D
	MOV	D, A
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
	.addrsig_sym i_p
