	.text
	.section	.text.main,"ax",@progbits
	.globl	main                            ; -- Begin function main
main:                                   ; @main
	;=== int main(int arg0, void* arg1) ===
	;  arg0 = HL
	;  arg1 = DE
; %bb.0:
	XRA	A
	STA	__v6c_a.main
	MOV	D, A
	INR	A
	STA	__v6c_a.main+1
	LXI	H, 0xffff
	LDA	__v6c_a.main
	;--- V6C_BUILD_PAIR ---
	MOV	B, D
	MOV	C, A
	LDA	__v6c_a.main+1
	MOV	E, B
	;--- V6C_SPILL8 ---
	PUSH	H
	LXI	H, .LLo61_2+1
	MOV	M, E
	POP	H
	;--- V6C_BUILD_PAIR ---
	MOV	E, A
.LBB15_1:                               ; =>This Loop Header: Depth=1
                                        ;     Child Loop BB15_2 Depth 2
                                        ;     Child Loop BB15_7 Depth 2
	;--- V6C_SPILL16 ---
	XCHG
	SHLD	.LLo61_1+1
	XCHG
	;--- V6C_ADD16 ---
	MOV	A, C
	ADD	E
	MOV	C, A
	MOV	A, B
	ADC	D
	MOV	B, A
	LXI	D, 0xff
	;--- V6C_SPILL16 ---
	PUSH	H
	MOV	L, C
	MOV	H, B
	SHLD	.LLo61_0+1
	POP	H
	;--- V6C_AND16 ---
	MOV	A, C
	ANA	E
	MOV	E, A
	MOV	A, B
	ANA	D
	MOV	D, A
	;--- V6C_XOR16 ---
	MOV	A, E
	XRA	L
	MOV	C, A
	MOV	A, D
	XRA	H
	MOV	B, A
	MVI	L, 8
.LBB15_2:                               ;   Parent Loop BB15_1 Depth=1
                                        ; =>  This Inner Loop Header: Depth=2
	;--- V6C_SRL16 ---
	MOV	D, B
	MOV	E, C
	MOV	A, D
	ORA	A
	RAR
	MOV	D, A
	MOV	A, E
	RAR
	MOV	E, A
	MOV	A, C
	ANI	1
	JNZ	.LBB15_3
; %bb.4:                                ;   in Loop: Header=BB15_2 Depth=2
	MOV	B, D
	MOV	C, E
	JMP	.LBB15_5
.LBB15_3:                               ;   in Loop: Header=BB15_2 Depth=2
	LXI	B, 0xa001
	;--- V6C_XOR16 ---
	MOV	A, E
	XRA	C
	MOV	C, A
	MOV	A, D
	XRA	B
	MOV	B, A
.LBB15_5:                               ;   in Loop: Header=BB15_2 Depth=2
	DCR	L
	;--- V6C_BRCOND ---
	JNZ	.LBB15_2
; %bb.6:                                ;   in Loop: Header=BB15_1 Depth=1
	;--- V6C_RELOAD16 ---
	LHLD	.LLo61_0+1
	;--- V6C_SRL16 ---
	MOV	L, H
	MVI	H, 0
	;--- V6C_XOR16 ---
	MOV	A, C
	XRA	L
	MOV	L, A
	MOV	A, B
	XRA	H
	MOV	H, A
	MVI	C, 8
.LBB15_7:                               ;   Parent Loop BB15_1 Depth=1
                                        ; =>  This Inner Loop Header: Depth=2
	;--- V6C_SRL16 ---
	MOV	D, H
	MOV	E, L
	MOV	A, D
	ORA	A
	RAR
	MOV	D, A
	MOV	A, E
	RAR
	MOV	E, A
	MOV	A, L
	ANI	1
	JNZ	.LBB15_8
; %bb.9:                                ;   in Loop: Header=BB15_7 Depth=2
	XCHG
	JMP	.LBB15_10
.LBB15_8:                               ;   in Loop: Header=BB15_7 Depth=2
	LXI	H, 0xa001
	;--- V6C_XOR16 ---
	MOV	A, E
	XRA	L
	MOV	L, A
	MOV	A, D
	XRA	H
	MOV	H, A
.LBB15_10:                              ;   in Loop: Header=BB15_7 Depth=2
	DCR	C
	;--- V6C_BRCOND ---
	JNZ	.LBB15_7
; %bb.11:                               ;   in Loop: Header=BB15_1 Depth=1
	;--- V6C_RELOAD8 ---
.LLo61_2:
	MVI	A, 0
	INR	A
	;--- V6C_SPILL8 ---
	STA	.LLo61_2+1
	CPI	0x18
	;--- V6C_RELOAD16 ---
.LLo61_1:
	LXI	B, 0
	;--- V6C_RELOAD16 ---
.LLo61_0:
	LXI	D, 0
	;--- V6C_BRCOND ---
	JNZ	.LBB15_1
; %bb.12:
	MOV	A, L
	OUT	0xed
	HLT
                                        ; -- End function
	.local	__v6c_a.main                    ; @__v6c_a.main
	.comm	__v6c_a.main,2,1
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
	.addrsig_sym __v6c_a.main
