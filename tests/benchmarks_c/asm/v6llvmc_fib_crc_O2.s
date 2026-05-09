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
	MOV	E, A
	INR	A
	STA	__v6c_a.main+1
	LDA	__v6c_a.main
	;--- V6C_BUILD_PAIR ---
	MOV	H, E
	MOV	L, A
	LDA	__v6c_a.main+1
	;--- V6C_BUILD_PAIR ---
	MOV	D, E
	MOV	E, A
	LXI	B, 0xffff
	;--- V6C_SPILL16 ---
	PUSH	H
	MOV	L, C
	MOV	H, B
	SHLD	.LLo61_2+1
	POP	H
	LXI	B, 0x18
	JMP	.LBB15_1
.LBB15_34:                              ;   in Loop: Header=BB15_1 Depth=1
	;--- V6C_SPILL16 ---
.LBB15_35:                              ;   in Loop: Header=BB15_1 Depth=1
	SHLD	.LLo61_2+1
	MOV	B, D
	MOV	C, E
	;--- V6C_DCX16 ---
	DCX	B
	;--- V6C_RELOAD16 ---
.LLo61_3:
	LXI	H, 0
	;--- V6C_RELOAD16 ---
.LLo61_1:
	LXI	D, 0
	;--- V6C_BR_CC16_IMM ---
	MOV	A, B
	ORA	C
	JZ	.LBB15_36
.LBB15_1:                               ; =>This Inner Loop Header: Depth=1
	;--- V6C_SPILL16 ---
	XCHG
	SHLD	.LLo61_3+1
	XCHG
	;--- V6C_ADD16 ---
	DAD	D
	XCHG
	LXI	H, 0xff
	;--- V6C_SPILL16 ---
	XCHG
	SHLD	.LLo61_0+1
	SHLD	.LLo61_1+1
	XCHG
	;--- V6C_AND16 ---
	MOV	A, E
	ANA	L
	MOV	L, A
	MOV	A, D
	ANA	H
	MOV	H, A
	;--- V6C_RELOAD16 ---
.LLo61_2:
	LXI	D, 0
	;--- V6C_XOR16 ---
	MOV	A, L
	XRA	E
	MOV	L, A
	MOV	A, H
	XRA	D
	MOV	H, A
	LXI	D, 1
	;--- V6C_AND16 ---
	MOV	A, L
	ANA	E
	MOV	E, A
	MOV	A, H
	ANA	D
	MOV	D, A
	;--- V6C_SRL16 ---
	MOV	A, H
	RAR
	MOV	H, A
	MOV	A, L
	RAR
	MOV	L, A
	;--- V6C_CMP16_ZERO ---
	MOV	A, D
	ORA	E
	JZ	.LBB15_3
; %bb.2:                                ;   in Loop: Header=BB15_1 Depth=1
	LXI	D, 0xa001
	;--- V6C_XOR16 ---
	MOV	A, L
	XRA	E
	MOV	L, A
	MOV	A, H
	XRA	D
	MOV	H, A
.LBB15_3:                               ;   in Loop: Header=BB15_1 Depth=1
	LXI	D, 1
	;--- V6C_AND16 ---
	MOV	A, L
	ANA	E
	MOV	E, A
	MOV	A, H
	ANA	D
	MOV	D, A
	;--- V6C_SRL16 ---
	MOV	A, H
	RAR
	MOV	H, A
	MOV	A, L
	RAR
	MOV	L, A
	;--- V6C_CMP16_ZERO ---
	MOV	A, D
	ORA	E
	JZ	.LBB15_5
; %bb.4:                                ;   in Loop: Header=BB15_1 Depth=1
	LXI	D, 0xa001
	;--- V6C_XOR16 ---
	MOV	A, L
	XRA	E
	MOV	L, A
	MOV	A, H
	XRA	D
	MOV	H, A
.LBB15_5:                               ;   in Loop: Header=BB15_1 Depth=1
	LXI	D, 1
	;--- V6C_AND16 ---
	MOV	A, L
	ANA	E
	MOV	E, A
	MOV	A, H
	ANA	D
	MOV	D, A
	;--- V6C_SRL16 ---
	MOV	A, H
	RAR
	MOV	H, A
	MOV	A, L
	RAR
	MOV	L, A
	;--- V6C_CMP16_ZERO ---
	MOV	A, D
	ORA	E
	JZ	.LBB15_7
; %bb.6:                                ;   in Loop: Header=BB15_1 Depth=1
	LXI	D, 0xa001
	;--- V6C_XOR16 ---
	MOV	A, L
	XRA	E
	MOV	L, A
	MOV	A, H
	XRA	D
	MOV	H, A
.LBB15_7:                               ;   in Loop: Header=BB15_1 Depth=1
	LXI	D, 1
	;--- V6C_AND16 ---
	MOV	A, L
	ANA	E
	MOV	E, A
	MOV	A, H
	ANA	D
	MOV	D, A
	;--- V6C_SRL16 ---
	MOV	A, H
	RAR
	MOV	H, A
	MOV	A, L
	RAR
	MOV	L, A
	;--- V6C_CMP16_ZERO ---
	MOV	A, D
	ORA	E
	JZ	.LBB15_9
; %bb.8:                                ;   in Loop: Header=BB15_1 Depth=1
	LXI	D, 0xa001
	;--- V6C_XOR16 ---
	MOV	A, L
	XRA	E
	MOV	L, A
	MOV	A, H
	XRA	D
	MOV	H, A
.LBB15_9:                               ;   in Loop: Header=BB15_1 Depth=1
	LXI	D, 1
	;--- V6C_AND16 ---
	MOV	A, L
	ANA	E
	MOV	E, A
	MOV	A, H
	ANA	D
	MOV	D, A
	;--- V6C_SRL16 ---
	MOV	A, H
	RAR
	MOV	H, A
	MOV	A, L
	RAR
	MOV	L, A
	;--- V6C_CMP16_ZERO ---
	MOV	A, D
	ORA	E
	JZ	.LBB15_11
; %bb.10:                               ;   in Loop: Header=BB15_1 Depth=1
	LXI	D, 0xa001
	;--- V6C_XOR16 ---
	MOV	A, L
	XRA	E
	MOV	L, A
	MOV	A, H
	XRA	D
	MOV	H, A
.LBB15_11:                              ;   in Loop: Header=BB15_1 Depth=1
	LXI	D, 1
	;--- V6C_AND16 ---
	MOV	A, L
	ANA	E
	MOV	E, A
	MOV	A, H
	ANA	D
	MOV	D, A
	;--- V6C_SRL16 ---
	MOV	A, H
	RAR
	MOV	H, A
	MOV	A, L
	RAR
	MOV	L, A
	;--- V6C_CMP16_ZERO ---
	MOV	A, D
	ORA	E
	JZ	.LBB15_13
; %bb.12:                               ;   in Loop: Header=BB15_1 Depth=1
	LXI	D, 0xa001
	;--- V6C_XOR16 ---
	MOV	A, L
	XRA	E
	MOV	L, A
	MOV	A, H
	XRA	D
	MOV	H, A
.LBB15_13:                              ;   in Loop: Header=BB15_1 Depth=1
	LXI	D, 1
	;--- V6C_AND16 ---
	MOV	A, L
	ANA	E
	MOV	E, A
	MOV	A, H
	ANA	D
	MOV	D, A
	;--- V6C_SRL16 ---
	MOV	A, H
	RAR
	MOV	H, A
	MOV	A, L
	RAR
	MOV	L, A
	;--- V6C_CMP16_ZERO ---
	MOV	A, D
	ORA	E
	JZ	.LBB15_15
; %bb.14:                               ;   in Loop: Header=BB15_1 Depth=1
	LXI	D, 0xa001
	;--- V6C_XOR16 ---
	MOV	A, L
	XRA	E
	MOV	L, A
	MOV	A, H
	XRA	D
	MOV	H, A
.LBB15_15:                              ;   in Loop: Header=BB15_1 Depth=1
	LXI	D, 1
	;--- V6C_AND16 ---
	MOV	A, L
	ANA	E
	MOV	E, A
	MOV	A, H
	ANA	D
	MOV	D, A
	;--- V6C_SRL16 ---
	MOV	A, H
	RAR
	MOV	H, A
	MOV	A, L
	RAR
	MOV	L, A
	;--- V6C_CMP16_ZERO ---
	MOV	A, D
	ORA	E
	JZ	.LBB15_17
; %bb.16:                               ;   in Loop: Header=BB15_1 Depth=1
	LXI	D, 0xa001
	;--- V6C_XOR16 ---
	MOV	A, L
	XRA	E
	MOV	L, A
	MOV	A, H
	XRA	D
	MOV	H, A
.LBB15_17:                              ;   in Loop: Header=BB15_1 Depth=1
	;--- V6C_RELOAD16 ---
.LLo61_0:
	LXI	D, 0
	;--- V6C_SRL16 ---
	MOV	E, D
	MVI	D, 0
	;--- V6C_XOR16 ---
	MOV	A, L
	XRA	E
	MOV	L, A
	MOV	A, H
	XRA	D
	MOV	H, A
	LXI	D, 1
	;--- V6C_AND16 ---
	MOV	A, L
	ANA	E
	MOV	E, A
	MOV	A, H
	ANA	D
	MOV	D, A
	;--- V6C_SRL16 ---
	MOV	A, H
	RAR
	MOV	H, A
	MOV	A, L
	RAR
	MOV	L, A
	;--- V6C_CMP16_ZERO ---
	MOV	A, D
	ORA	E
	JZ	.LBB15_19
; %bb.18:                               ;   in Loop: Header=BB15_1 Depth=1
	LXI	D, 0xa001
	;--- V6C_XOR16 ---
	MOV	A, L
	XRA	E
	MOV	L, A
	MOV	A, H
	XRA	D
	MOV	H, A
.LBB15_19:                              ;   in Loop: Header=BB15_1 Depth=1
	LXI	D, 1
	;--- V6C_AND16 ---
	MOV	A, L
	ANA	E
	MOV	E, A
	MOV	A, H
	ANA	D
	MOV	D, A
	;--- V6C_SRL16 ---
	MOV	A, H
	RAR
	MOV	H, A
	MOV	A, L
	RAR
	MOV	L, A
	;--- V6C_CMP16_ZERO ---
	MOV	A, D
	ORA	E
	JZ	.LBB15_21
; %bb.20:                               ;   in Loop: Header=BB15_1 Depth=1
	LXI	D, 0xa001
	;--- V6C_XOR16 ---
	MOV	A, L
	XRA	E
	MOV	L, A
	MOV	A, H
	XRA	D
	MOV	H, A
.LBB15_21:                              ;   in Loop: Header=BB15_1 Depth=1
	LXI	D, 1
	;--- V6C_AND16 ---
	MOV	A, L
	ANA	E
	MOV	E, A
	MOV	A, H
	ANA	D
	MOV	D, A
	;--- V6C_SRL16 ---
	MOV	A, H
	RAR
	MOV	H, A
	MOV	A, L
	RAR
	MOV	L, A
	;--- V6C_CMP16_ZERO ---
	MOV	A, D
	ORA	E
	JZ	.LBB15_23
; %bb.22:                               ;   in Loop: Header=BB15_1 Depth=1
	LXI	D, 0xa001
	;--- V6C_XOR16 ---
	MOV	A, L
	XRA	E
	MOV	L, A
	MOV	A, H
	XRA	D
	MOV	H, A
.LBB15_23:                              ;   in Loop: Header=BB15_1 Depth=1
	LXI	D, 1
	;--- V6C_AND16 ---
	MOV	A, L
	ANA	E
	MOV	E, A
	MOV	A, H
	ANA	D
	MOV	D, A
	;--- V6C_SRL16 ---
	MOV	A, H
	RAR
	MOV	H, A
	MOV	A, L
	RAR
	MOV	L, A
	;--- V6C_CMP16_ZERO ---
	MOV	A, D
	ORA	E
	JZ	.LBB15_25
; %bb.24:                               ;   in Loop: Header=BB15_1 Depth=1
	LXI	D, 0xa001
	;--- V6C_XOR16 ---
	MOV	A, L
	XRA	E
	MOV	L, A
	MOV	A, H
	XRA	D
	MOV	H, A
.LBB15_25:                              ;   in Loop: Header=BB15_1 Depth=1
	LXI	D, 1
	;--- V6C_AND16 ---
	MOV	A, L
	ANA	E
	MOV	E, A
	MOV	A, H
	ANA	D
	MOV	D, A
	;--- V6C_SRL16 ---
	MOV	A, H
	RAR
	MOV	H, A
	MOV	A, L
	RAR
	MOV	L, A
	;--- V6C_CMP16_ZERO ---
	MOV	A, D
	ORA	E
	JZ	.LBB15_27
; %bb.26:                               ;   in Loop: Header=BB15_1 Depth=1
	LXI	D, 0xa001
	;--- V6C_XOR16 ---
	MOV	A, L
	XRA	E
	MOV	L, A
	MOV	A, H
	XRA	D
	MOV	H, A
.LBB15_27:                              ;   in Loop: Header=BB15_1 Depth=1
	LXI	D, 1
	;--- V6C_AND16 ---
	MOV	A, L
	ANA	E
	MOV	E, A
	MOV	A, H
	ANA	D
	MOV	D, A
	;--- V6C_SRL16 ---
	MOV	A, H
	RAR
	MOV	H, A
	MOV	A, L
	RAR
	MOV	L, A
	;--- V6C_CMP16_ZERO ---
	MOV	A, D
	ORA	E
	JZ	.LBB15_29
; %bb.28:                               ;   in Loop: Header=BB15_1 Depth=1
	LXI	D, 0xa001
	;--- V6C_XOR16 ---
	MOV	A, L
	XRA	E
	MOV	L, A
	MOV	A, H
	XRA	D
	MOV	H, A
.LBB15_29:                              ;   in Loop: Header=BB15_1 Depth=1
	LXI	D, 1
	;--- V6C_AND16 ---
	MOV	A, L
	ANA	E
	MOV	E, A
	MOV	A, H
	ANA	D
	MOV	D, A
	;--- V6C_SRL16 ---
	MOV	A, H
	RAR
	MOV	H, A
	MOV	A, L
	RAR
	MOV	L, A
	;--- V6C_CMP16_ZERO ---
	MOV	A, D
	ORA	E
	JNZ	.LBB15_30
; %bb.31:                               ;   in Loop: Header=BB15_1 Depth=1
	MOV	D, B
	MOV	E, C
	JMP	.LBB15_32
.LBB15_30:                              ;   in Loop: Header=BB15_1 Depth=1
	MOV	D, B
	MOV	E, C
	LXI	B, 0xa001
	;--- V6C_XOR16 ---
	MOV	A, L
	XRA	C
	MOV	L, A
	MOV	A, H
	XRA	B
	MOV	H, A
.LBB15_32:                              ;   in Loop: Header=BB15_1 Depth=1
	LXI	B, 1
	;--- V6C_AND16 ---
	MOV	A, L
	ANA	C
	MOV	C, A
	MOV	A, H
	ANA	B
	MOV	B, A
	;--- V6C_SRL16 ---
	MOV	A, H
	RAR
	MOV	H, A
	MOV	A, L
	RAR
	MOV	L, A
	;--- V6C_CMP16_ZERO ---
	MOV	A, B
	ORA	C
	JZ	.LBB15_34
; %bb.33:                               ;   in Loop: Header=BB15_1 Depth=1
	MOV	B, H
	MOV	C, L
	LXI	H, 0xa001
	;--- V6C_XOR16 ---
	MOV	A, C
	XRA	L
	MOV	C, A
	MOV	A, B
	XRA	H
	MOV	B, A
	;--- V6C_SPILL16 ---
	MOV	L, C
	MOV	H, B
	JMP	.LBB15_35
.LBB15_36:
	;--- V6C_RELOAD16 ---
	LHLD	.LLo61_2+1
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
