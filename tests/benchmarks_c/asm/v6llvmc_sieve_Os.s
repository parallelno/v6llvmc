	.text
	.section	.text.main,"ax",@progbits
	.globl	main                            ; -- Begin function main
main:                                   ; @main
	;=== int main(int arg0, void* arg1) ===
	;  arg0 = HL
	;  arg1 = DE
; %bb.0:
	LXI	H, flags
.LBB15_1:                               ; =>This Inner Loop Header: Depth=1
	;--- V6C_STORE8_IMM_P ---
	MVI	M, 0
	;--- V6C_INX16 ---
	INX	H
	;--- V6C_BR_CC16_IMM ---
	MVI	A, <(flags+8000)
	CMP	L
	JNZ	.LBB15_1
; %bb.10:                               ;   in Loop: Header=BB15_1 Depth=1
	MVI	A, >(flags+8000)
	CMP	H
	JNZ	.LBB15_1
; %bb.2:
	LXI	H, 4
	;--- V6C_SPILL16 ---
	SHLD	.LLo61_4+1
	LXI	H, 0x1f3e
	;--- V6C_SPILL16 ---
	SHLD	.LLo61_0+1
	LXI	H, 2
	LXI	B, 5
	LXI	D, flags+4
	;--- V6C_SPILL16 ---
	XCHG
	SHLD	.LLo61_2+1
	XCHG
.LBB15_3:                               ; =>This Loop Header: Depth=1
                                        ;     Child Loop BB15_5 Depth 2
	;--- V6C_SPILL16 ---
	PUSH	H
	MOV	L, C
	MOV	H, B
	SHLD	.LLo61_5+1
	POP	H
	;--- V6C_SPILL16 ---
	SHLD	.LLo61_1+1
	LXI	D, flags
	;--- V6C_DAD ---
	DAD	D
	;--- V6C_LOAD8_P ---
	MOV	A, M
	;--- V6C_CMP8_ZERO ---
	ORA	A
	;--- V6C_BRCOND ---
	JNZ	.LBB15_8
; %bb.4:                                ;   in Loop: Header=BB15_3 Depth=1
	;--- V6C_RELOAD16 ---
	LHLD	.LLo61_2+1
	MOV	C, L
	MOV	B, H
	;--- V6C_RELOAD16 ---
	LHLD	.LLo61_4+1
.LBB15_5:                               ;   Parent Loop BB15_3 Depth=1
                                        ; =>  This Inner Loop Header: Depth=2
	;--- V6C_SPILL16 ---
	SHLD	.LLo61_3+1
	;--- V6C_LOAD8_P ---
	LDAX	B
	;--- V6C_CMP8_ZERO ---
	ORA	A
	MVI	L, 0
	MOV	A, L
	JNZ	.LBB15_7
; %bb.6:                                ;   in Loop: Header=BB15_5 Depth=2
	INR	A
.LBB15_7:                               ;   in Loop: Header=BB15_5 Depth=2
	;--- V6C_BUILD_PAIR ---
	MOV	H, L
	MOV	L, A
	;--- V6C_RELOAD16 ---
.LLo61_0:
	LXI	D, 0
	;--- V6C_SUB16 ---
	MOV	A, E
	SUB	L
	MOV	E, A
	MOV	A, D
	SBB	H
	MOV	D, A
	;--- V6C_SPILL16 ---
	XCHG
	SHLD	.LLo61_0+1
	;--- V6C_STORE8_IMM_P ---
	MVI	A, 1
	STAX	B
	;--- V6C_RELOAD16 ---
.LLo61_1:
	LXI	H, 0
	;--- V6C_ADD16 ---
	MOV	A, C
	ADD	L
	MOV	C, A
	MOV	A, B
	ADC	H
	MOV	B, A
	;--- V6C_RELOAD16 ---
.LLo61_3:
	LXI	D, 0
	;--- V6C_ADD16 ---
	DAD	D
	;--- V6C_BR_CC16_IMM ---
	MVI	A, 0x3f
	SUB	L
	MVI	A, 0x1f
	SBB	H
	JNC	.LBB15_5
.LBB15_8:                               ;   in Loop: Header=BB15_3 Depth=1
	;--- V6C_RELOAD16 ---
	LHLD	.LLo61_1+1
	;--- V6C_ADD16 ---
	DAD	H
	;--- V6C_RELOAD16 ---
.LLo61_4:
	LXI	D, 0
	;--- V6C_ADD16 ---
	DAD	D
	;--- V6C_SPILL16 ---
	SHLD	.LLo61_4+1
	;--- V6C_RELOAD16 ---
	LHLD	.LLo61_1+1
	;--- V6C_RELOAD16 ---
.LLo61_5:
	LXI	B, 0
	;--- V6C_RELOAD16 ---
.LLo61_2:
	LXI	D, 0
	;--- V6C_ADD16 ---
	XCHG
	DAD	B
	;--- V6C_SPILL16 ---
	SHLD	.LLo61_2+1
	;--- V6C_INX16 ---
	INX	B
	INX	B
	;--- V6C_RELOAD16 ---
	LHLD	.LLo61_4+1
	XCHG
	;--- V6C_INX16 ---
	INX	D
	;--- V6C_SPILL16 ---
	XCHG
	SHLD	.LLo61_4+1
	XCHG
	;--- V6C_INX16 ---
	INX	H
	;--- V6C_BR_CC16_IMM ---
	MVI	A, 0x5a
	CMP	L
	JNZ	.LBB15_3
; %bb.11:                               ;   in Loop: Header=BB15_3 Depth=1
	XRA	A
	CMP	H
	JNZ	.LBB15_3
; %bb.9:
	;--- V6C_RELOAD16 ---
	LHLD	.LLo61_0+1
	XCHG
	;--- V6C_SRL16 ---
	MOV	L, D
	MOV	H, A
	;--- V6C_XOR16 ---
	MOV	A, L
	XRA	E
	MOV	L, A
	MOV	A, H
	XRA	D
	MOV	H, A
	MOV	A, L
	OUT	0xed
	HLT
                                        ; -- End function
	.local	flags                           ; @flags
	.comm	flags,8000,1
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
