main:
	di
	lxi h, 0
	sphl

	LXI	HL, ARR
	MVI	E, 0x10
	CALL	bsort_for
	call print_arr
	hlt

print_arr:
	lxi h, arr
	mvi c, 16
@loop:
	mov a, m
	out 0xED
	inx h
	dcr c
	jnz @loop
	ret

bsort_for:                              ; @bsort_for
; %bb.0:
	MOV	A, E
	SHLD	LLo61_2+1
	MVI	L, 0
	MOV	H, L
	MOV	L, A
	CPI	2
	RC
LBB0_1:
	DCX	HL
	LXI	DE, 0
	SHLD	LLo61_5+1
LBB0_2:                                ; =>This Loop Header: Depth=1
                                        ;     Child Loop BB0_4 Depth 2
	XCHG ; 648cc
	SHLD	LLo61_1+1
	XCHG
	MOV	A, L
	SUB	E
	MOV	L, A
	MOV	A, H
	SBB	D
	MOV	H, A
	SHLD	LLo61_4+1
	MOV	A, H
	ORA	L
	JNZ	LBB0_7
; %bb.3:                                ;   in Loop: Header=BB0_2 Depth=1
	INR	A
	STA	LLo61_6+1
LLo61_2:
	LXI	BC, 0
	MOV	L, C
	MOV	H, B
	SHLD	LLo61_3+1
	JMP	LBB0_4
LBB0_6:                                ;   in Loop: Header=BB0_4 Depth=2
	MVI	A, 0
LLo61_6:
	MVI	E, 0
	MOV	B, A
	MOV	C, E
	PUSH	HL
	MOV	L, C
	MOV	H, B
	SHLD	LLo61_0+1
	POP	HL
	INR	E
	MOV	A, E
	STA	LLo61_6+1
	SHLD	LLo61_3+1
	MOV	B, H
	MOV	C, L
LLo61_4:
	LXI	HL, 0
LLo61_0:
	LXI	DE, 0
	MOV	A, E
	SUB	L
	MOV	A, D
	SBB	H
	JNC	LBB0_7
LBB0_4:                                ;   Parent Loop BB0_2 Depth=1
                                        ; =>  This Inner Loop Header: Depth=2
LLo61_3:
	LXI	DE, 0
	LDAX	DE
	MOV	L, A
	INX	BC
	LDAX	BC
	PUSH	PSW
	MOV	A, L
	STA	LLo61_7+1
	POP	PSW
	CMP	L
	MOV	H, B
	MOV	L, C
	JNC	LBB0_6
; %bb.5:                                ;   in Loop: Header=BB0_4 Depth=2
	STAX	DE
	INX	DE
LLo61_7:
	MVI	A, 0
	STAX	DE
	JMP	LBB0_6
LBB0_7:                                ;   in Loop: Header=BB0_2 Depth=1
LLo61_1:
	LXI	DE, 0
	INX	DE
LLo61_5:
	LXI	HL, 0
	MOV	A, E
	CMP	L
	JNZ	LBB0_2
; %bb.9:                                ;   in Loop: Header=BB0_2 Depth=1
	MOV	A, D
	CMP	H
	JNZ	LBB0_2
; %bb.8:
	RET

ARR:
	.storage 0x10
