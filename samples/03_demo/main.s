	.text
	.section	.text.mem_access,"ax",@progbits
mem_access:                             ; -- Begin function mem_access
                                        ; @mem_access
.Lfunc_begin0:
	;=== void mem_access(char x1, char y1) ===
	;  x1 = A
	;  y1 = B
; %bb.0:
	;DEBUG_VALUE: mem_access:x1 <- $a
	;DEBUG_VALUE: mem_access:y1 <- $b
	MVI	E, 0
	;--- V6C_BUILD_PAIR ---
	MOV	H, E
	MOV	L, B
	;--- V6C_SPILL16 ---
	SHLD	.LLo61_2+1
	;--- V6C_BUILD_PAIR ---
	MOV	D, E
	MOV	E, A
	;--- V6C_SPILL16 ---
	XCHG
	SHLD	.LLo61_0+1
	XCHG
	;--- V6C_ADD16 ---
	MOV	A, E
	ADD	E
	MOV	C, A
	MOV	A, D
	ADC	D
	MOV	B, A
	;--- V6C_SPILL16 ---
	PUSH	H
	MOV	L, C
	MOV	H, B
	SHLD	.LLo61_3+1
	POP	H
	LXI	D, test_arr
	;--- V6C_DAD ---
	PUSH	H
	MOV	H, B
	MOV	L, C
	DAD	D
	XCHG
	POP	H
	;--- V6C_SPILL16 ---
	XCHG
	SHLD	.LLo61_1+1
	XCHG
	;--- V6C_ADD16 ---
	PUSH	H
	DAD	H
	XCHG
	POP	H
	;--- V6C_RELOAD16 ---
.LLo61_1:
	LXI	B, 0
	;--- V6C_STORE16_P ---
	MOV	A, E
	STAX	B
	INX	B
	MOV	A, D
	STAX	B
	;--- V6C_RELOAD16 ---
.LLo61_0:
	LXI	D, 0
	CALL	__mulhi3
	;DEBUG_VALUE: mem_access:a <- $hl
	;--- V6C_RELOAD16 ---
.LLo61_2:
	LXI	D, 0
	;--- V6C_ADD16 ---
	DAD	D
	LXI	D, 0xa
	;--- V6C_ADD16 ---
	DAD	D
	;--- V6C_RELOAD16 ---
.LLo61_3:
	LXI	B, 0
	;--- V6C_INX16 ---
	INX	B
	INX	B
	LXI	D, test_arr
	;--- V6C_DAD ---
	PUSH	H
	MOV	H, B
	MOV	L, C
	DAD	D
	XCHG
	POP	H
	;--- V6C_STORE16_P ---
	XCHG
	MOV	M, E
	INX	H
	MOV	M, D
	XCHG
	RET
.Lfunc_end0:
                                        ; -- End function
	.section	.text.main,"ax",@progbits
	.globl	main                            ; -- Begin function main
main:                                   ; @main
.Lfunc_begin1:
	;=== void main(void) ===
; %bb.0:
	LXI	D, test_arr
	;APP
	MVI	A, 0xfb
	STA	0x38
	MVI	A, 0xc9
	STA	0x39

	;NO_APP
	;DEBUG_VALUE: i <- 0
	;DEBUG_VALUE: main:ttt <- 4660
	LXI	B, test_arr
.LBB16_1:                               ; =>This Inner Loop Header: Depth=1
	;DEBUG_VALUE: main:ttt <- 4660
	;DEBUG_VALUE: i <- undef
	;--- V6C_SPILL16 ---
	MOV	L, C
	MOV	H, B
	SHLD	.LLo61_6+1
	;--- V6C_SPILL16 ---
	XCHG
	SHLD	.LLo61_4+1
	XCHG
	LXI	H, 0x14
	;--- V6C_DAD ---
	DAD	B
	;--- V6C_LOAD16_P ---
	MOV	B, M
	INX	H
	MOV	H, M
	MOV	L, B
	;DEBUG_VALUE: r1 <- $hl
	;--- V6C_SPILL16 ---
	SHLD	.LLo61_7+1
	;--- V6C_SRL16 ---
	MOV	L, H
	MVI	H, 0
	;DEBUG_VALUE: r1 <- [$sp+0]
	;DEBUG_VALUE: r1 <- $hl
	;--- V6C_SPILL16 ---
	SHLD	.LLo61_5+1
	;--- V6C_LOAD16_P ---
	XCHG
	MOV	C, M
	INX	H
	MOV	B, M
	XCHG
	;DEBUG_VALUE: x1 <- [DW_OP_LLVM_convert 16 7, DW_OP_LLVM_convert 8 7, DW_OP_stack_value] $bc
	;DEBUG_VALUE: r1 <- $bc
	;--- V6C_SRL16 ---
	MOV	E, B
	MOV	D, H
	;DEBUG_VALUE: y1 <- [DW_OP_LLVM_convert 16 7, DW_OP_LLVM_convert 8 7, DW_OP_stack_value] $de
	;--- V6C_RELOAD16 ---
.LLo61_5:
	LXI	H, 0
	;--- V6C_ADD16 ---
	DAD	D
	XCHG
	;--- V6C_RELOAD16 ---
.LLo61_7:
	LXI	H, 0
	;--- V6C_ADD16 ---
	DAD	B
	;DEBUG_VALUE: y1 <- $e
	;DEBUG_VALUE: x1 <- $l
	MOV	A, L
	MOV	B, E
	CALL	mem_access
	;--- V6C_RELOAD16 ---
.LLo61_6:
	LXI	B, 0
	;--- V6C_RELOAD16 ---
.LLo61_4:
	LXI	D, 0
	;--- V6C_INX16 ---
	INX	B
	INX	B
	;--- V6C_INX16 ---
	INX	D
	INX	D
	;--- V6C_BR_CC16_IMM ---
	MVI	A, <(test_arr+200)
	CMP	E
	JNZ	.LBB16_1
; %bb.3:                                ;   in Loop: Header=BB16_1 Depth=1
	;DEBUG_VALUE: main:ttt <- 4660
	MVI	A, >(test_arr+200)
	CMP	D
	JNZ	.LBB16_1
; %bb.2:
	;DEBUG_VALUE: main:ttt <- 4660
	RET
.Lfunc_end1:
                                        ; -- End function
	.data
	.globl	__v6c_rand_state                ; @__v6c_rand_state
__v6c_rand_state:
	DW	1                               ; 0x1

	.section	.bss,"aw",@nobits
	.globl	test_arr                        ; @test_arr
test_arr:

	.local	__v6c_ss.main                   ; @__v6c_ss.main
	.comm	__v6c_ss.main,2,1
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
