	.text
	.globl	multi_ptr_copy                  ; -- Begin function multi_ptr_copy
multi_ptr_copy:                         ; @multi_ptr_copy
; %bb.0:
	PUSH	HL
	PUSH	DE
	LXI	HL, 0xfffa
	DAD	SP
	SPHL
	LXI	HL, 6
	DAD	SP
	MOV	E, M
	INX	HL
	MOV	D, M
	INX	HL
	MOV	A, M
	INX	HL
	MOV	H, M
	MOV	L, A
	MOV	A, C
	MOV	B, D
	MOV	C, E
	PUSH	DE
	XCHG
	LXI	HL, 6
	DAD	SP
	MOV	M, E
	INX	HL
	MOV	M, D
	XCHG
	POP	DE
	ORA	A
	JZ	.LBB0_3
; %bb.1:
	PUSH	HL
	LXI	HL, 8
	DAD	SP
	MOV	M, C
	INX	HL
	MOV	M, B
	POP	HL
	MVI	L, 0
	MOV	D, L
	MOV	E, A
	PUSH	DE
	LXI	HL, 8
	DAD	SP
	MOV	E, M
	INX	HL
	MOV	D, M
	XCHG
	POP	DE
.LBB0_2:                                ; =>This Inner Loop Header: Depth=1
	PUSH	HL
	LXI	HL, 0xa
	DAD	SP
	MOV	M, E
	INX	HL
	MOV	M, D
	POP	HL
	PUSH	DE
	XCHG
	LXI	HL, 8
	DAD	SP
	MOV	M, E
	INX	HL
	MOV	M, D
	XCHG
	POP	DE
	MOV	A, M
	INR	A
	PUSH	HL
	LXI	HL, 6
	DAD	SP
	MOV	E, M
	INX	HL
	MOV	D, M
	POP	HL
	STAX	DE
	PUSH	DE
	LXI	HL, 8
	DAD	SP
	MOV	E, M
	INX	HL
	MOV	D, M
	XCHG
	POP	DE
	INX	HL
	INX	DE
	PUSH	HL
	LXI	HL, 6
	DAD	SP
	MOV	M, E
	INX	HL
	MOV	M, D
	POP	HL
	PUSH	HL
	LXI	HL, 0xa
	DAD	SP
	MOV	C, M
	INX	HL
	MOV	B, M
	POP	HL
	DCX	BC
	PUSH	HL
	LXI	HL, 0xa
	DAD	SP
	MOV	M, C
	INX	HL
	MOV	M, B
	POP	HL
	MOV	E, C
	MOV	D, B
	MOV	A, D
	ORA	E
	JNZ	.LBB0_2
.LBB0_3:
	LXI	HL, 0xa
	DAD	SP
	SPHL
	RET
                                        ; -- End function
	.globl	multi_live                      ; -- Begin function multi_live
multi_live:                             ; @multi_live
; %bb.0:
	LXI	HL, 0xfffe
	DAD	SP
	SPHL
	PUSH	HL
	LXI	HL, 3
	DAD	SP
	MOV	M, E
	POP	HL
	PUSH	HL
	LXI	HL, 2
	DAD	SP
	MOV	M, A
	POP	HL
	MOV	A, C
	CALL	use8
	PUSH	HL
	LXI	HL, 2
	DAD	SP
	MOV	A, M
	POP	HL
	PUSH	DE
	MOV	D, H
	LXI	HL, 3
	DAD	SP
	MOV	L, M
	MOV	H, D
	POP	DE
	ADD	L
	ADI	3
	LXI	HL, 2
	DAD	SP
	SPHL
	RET
                                        ; -- End function
	.globl	nested_calls                    ; -- Begin function nested_calls
nested_calls:                           ; @nested_calls
; %bb.0:
	LXI	HL, 0xfffd
	DAD	SP
	SPHL
	PUSH	HL
	LXI	HL, 2
	DAD	SP
	MOV	M, E
	POP	HL
	PUSH	HL
	LXI	HL, 3
	DAD	SP
	MOV	M, A
	POP	HL
	CALL	get8
	PUSH	HL
	LXI	HL, 4
	DAD	SP
	MOV	M, A
	POP	HL
	PUSH	HL
	LXI	HL, 2
	DAD	SP
	MOV	A, M
	POP	HL
	CALL	use8
	PUSH	HL
	LXI	HL, 4
	DAD	SP
	MOV	A, M
	POP	HL
	PUSH	DE
	MOV	D, H
	LXI	HL, 3
	DAD	SP
	MOV	L, M
	MOV	H, D
	POP	DE
	ADD	L
	PUSH	HL
	LXI	HL, 4
	DAD	SP
	MOV	M, A
	POP	HL
	CALL	get8
	MOV	L, A
	PUSH	HL
	LXI	HL, 4
	DAD	SP
	MOV	A, M
	POP	HL
	ADD	L
	LXI	HL, 3
	DAD	SP
	SPHL
	RET
                                        ; -- End function
	.globl	main                            ; -- Begin function main
main:                                   ; @main
; %bb.0:
	LXI	HL, 0xfffc
	DAD	SP
	SPHL
	LXI	HL, 3
	DAD	SP
	PUSH	DE
	MOV	D, H
	MOV	E, L
	LXI	HL, 3
	DAD	SP
	MOV	M, E
	INX	HL
	MOV	M, D
	XCHG
	POP	DE
	MVI	A, 0xb
	MOV	M, A
	MVI	A, 3
	CALL	use8
	MVI	A, 6
	PUSH	DE
	LXI	HL, 3
	DAD	SP
	MOV	E, M
	INX	HL
	MOV	D, M
	XCHG
	POP	DE
	MOV	M, A
	CALL	get8
	PUSH	HL
	LXI	HL, 2
	DAD	SP
	MOV	M, A
	POP	HL
	MVI	A, 6
	CALL	use8
	CALL	get8
	MOV	L, A
	PUSH	HL
	LXI	HL, 2
	DAD	SP
	MOV	A, M
	POP	HL
	ADD	L
	ADI	5
	PUSH	HL
	LXI	HL, 3
	DAD	SP
	MOV	E, M
	INX	HL
	MOV	D, M
	POP	HL
	STAX	DE
	LDAX	DE
	MVI	L, 0
	MOV	H, L
	MOV	L, A
	XCHG
	LXI	HL, 4
	DAD	SP
	SPHL
	XCHG
	RET
                                        ; -- End function
	.addrsig
