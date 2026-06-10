	.text
	.section	.text.rand,"ax",@progbits
rand:                                   ; -- Begin function rand
                                        ; @rand
; %bb.0:
	;APP
.Ltmp0:
	LHLD	__v6c_rand_state
	MOV	A, H
	RAR

	MOV	A, L
	RAR

	XRA	H
	MOV	H, A
	MOV	A, L
	RAR

	MOV	A, H
	RAR

	XRA	L
	MOV	L, A
	XRA	H
	MOV	H, A
	SHLD	__v6c_rand_state

	;NO_APP
	RET
                                        ; -- End function
	.section	.text.draw_line,"ax",@progbits
draw_line:                              ; -- Begin function draw_line
                                        ; @draw_line
; %bb.0:
	MOV	E, B
	MOV	D, A
	MVI	A, 0x80
	MVI	B, 0x7f
	MOV	C, B
	;APP
	STA	.ADDR_H+1
	MOV	A, D
	SUB	B
	JC	.SWAP_POINTS
.SET_DX:
	MOV	D, A
	LXI	H, .ADV_Y
	MOV	A, E
	SUB	C
	JC	.ADV_Y_NEG
.ADV_Y_POS:
	MVI	M, 0x2c
	JMP	.CHECK_SLOP
.ADV_Y_NEG:
	CMA

	INR	A
	MVI	M, 0x2d
.CHECK_SLOP:
	CMP	D
	JNC	.VERTICAL_DRAW
	STA	.DY+1
	CALL	.SET_LOOP_VARS
.LOOP_H:
	MOV	A, M
	ORA	E
	MOV	M, A
	ANA	E
	RRC

	MOV	E, A
	ADC	H
	SUB	E
	MOV	H, A
	MOV	A, C
.DY:
	SUI	0
	JNC	.NO_ADV_Y
	ADD	D
.ADV_Y:
	INR	L
.NO_ADV_Y:
	MOV	C, A
	DCR	B
	JNZ	.LOOP_H
	RET

.SWAP_POINTS:
	CMA

	INR	A
	XCHG

	MOV	D, B
	MOV	E, C
	MOV	B, H
	MOV	C, L
	JMP	.SET_DX
.VERTICAL_DRAW:
	LXI	H, .DX2+1
	MOV	M, D
	MOV	D, A
	LDA	.ADV_Y
	STA	.ADV_Y2
	CALL	.SET_LOOP_VARS
.LOOP_V:
	MOV	A, M
	ORA	E
	MOV	M, A
.ADV_Y2:
	INR	L
	MOV	A, C
.DX2:
	SUI	0
	MOV	C, A
	JNC	.NO_ADV_X2
	ADD	D
	MOV	C, A
	MOV	A, E
	RRC

	MOV	E, A
	ADC	H
	SUB	E
	MOV	H, A
.NO_ADV_X2:
	DCR	B
	JNZ	.LOOP_V
	RET

.SET_LOOP_VARS:
	LXI	H, BIT_MASK
	MVI	A, 7
	ANA	B
	ADD	L
	MOV	L, A
	ADC	H
	SUB	L
	MOV	H, A
	MOV	E, M
	MVI	A, 0xf8
	ANA	B
	RRC

	RRC

	RRC

.ADDR_H:
	ADI	0x80
	MOV	H, A
	MOV	L, C
	MOV	B, D
	INR	B
	XRA	A
	ORA	D
	RAR

	MOV	C, A
	RET


	;NO_APP
	RET
                                        ; -- End function
	.section	.text.draw_pixel,"ax",@progbits
draw_pixel:                             ; -- Begin function draw_pixel
                                        ; @draw_pixel
; %bb.0:
	MOV	L, B
	MOV	H, C
	;APP
	MOV	C, A
	RRC

	RRC

	RRC

	ANI	0x1f
	ADD	H
	MOV	H, A
	MVI	A, 7
	ANA	C
	LXI	B, BIT_MASK
	ADD	C
	MOV	C, A
	ADC	B
	SUB	C
	MOV	B, A
	LDAX	B
	ORA	M
	MOV	M, A

	;NO_APP
	RET
                                        ; -- End function
	.section	.text.draw_circle,"ax",@progbits
draw_circle:                            ; -- Begin function draw_circle
                                        ; @draw_circle
; %bb.0:
	MOV	L, A
	MVI	E, 0x7f
	RRC
	RRC
	RRC
	RRC
	ANI	0xf
	STA	.LLo61_4+1
	MOV	A, L
	MVI	D, 0
.LBB18_1:                               ; =>This Inner Loop Header: Depth=1
	MOV	L, A
	RRC
	MOV	C, A
	ANI	0x7f
	MOV	H, A
	MOV	A, C
	RRC
	ANI	0x3f
	ADD	H
	MOV	H, A
	MOV	A, L
	STA	.LLo61_0+1
	ANI	3
	MVI	L, 0
	JZ	.LBB18_3
; %bb.2:                                ;   in Loop: Header=BB18_1 Depth=1
	MVI	L, 1
.LBB18_3:                               ;   in Loop: Header=BB18_1 Depth=1
	MOV	A, H
	ADD	L
	STA	.LLo61_1+1
	ADI	0x7f
	MOV	L, A
	STA	.LLo61_2+1
	MOV	A, D
	ADI	0x7f
	MOV	B, A
	MOV	A, D
	STA	.LLo61_3+1
	MOV	D, B
	MOV	A, L
	MVI	C, 0xa0
	CALL	draw_pixel
.LLo61_1:
	MVI	A, 0
	XRI	0x7f
	STA	.LLo61_1+1
	LDA	.LLo61_1+1
	MOV	B, D
	MVI	C, 0xa0
	CALL	draw_pixel
	LDA	.LLo61_2+1
	MOV	B, E
	MVI	C, 0xa0
	CALL	draw_pixel
	LDA	.LLo61_1+1
	LXI	H, .LLo61_2+1
	MOV	M, E
	MOV	B, E
	MVI	C, 0xa0
	CALL	draw_pixel
.LLo61_3:
	MVI	H, 0
	MOV	A, H
	RRC
	MOV	E, A
	ANI	0x7f
	MOV	L, A
	MOV	A, E
	RRC
	ANI	0x3f
	ADD	L
	MOV	L, A
	MOV	A, H
	ANI	3
	MVI	H, 0
	JZ	.LBB18_5
; %bb.4:                                ;   in Loop: Header=BB18_1 Depth=1
	MVI	H, 1
.LBB18_5:                               ;   in Loop: Header=BB18_1 Depth=1
	MOV	A, L
	ADD	H
	MOV	E, A
	ADI	0x7f
	STA	.LLo61_1+1
	LDA	.LLo61_0+1
	ADI	0x7f
	MOV	D, A
	LDA	.LLo61_1+1
	MOV	B, D
	MVI	C, 0xa0
	CALL	draw_pixel
	MOV	A, E
	XRI	0x7f
	MOV	E, A
	MOV	B, D
	MVI	C, 0xa0
	CALL	draw_pixel
	LDA	.LLo61_0+1
	XRI	0x7f
	MOV	D, A
	LDA	.LLo61_1+1
	MOV	B, D
	MVI	C, 0xa0
	CALL	draw_pixel
	MOV	A, E
	MOV	B, D
	MVI	C, 0xa0
	CALL	draw_pixel
	LXI	H, .LLo61_3+1
	MOV	L, M
	INR	L
.LLo61_4:
	MVI	A, 0
	MOV	B, A
	MOV	A, L
	STA	.LLo61_3+1
	MOV	A, B
	ADD	L
	MVI	C, 0
.LLo61_0:
	MVI	L, 0
	MOV	H, C
	STA	.LLo61_4+1
	MOV	B, C
	SUB	L
	MOV	L, A
	MOV	A, B
	SBB	H
	MOV	H, A
	XRA	A
	ADD	H
	JM	.LBB18_7
; %bb.6:                                ;   in Loop: Header=BB18_1 Depth=1
	MOV	A, L
	STA	.LLo61_4+1
.LBB18_7:                               ;   in Loop: Header=BB18_1 Depth=1
	MVI	L, 0
.LLo61_2:
	MVI	E, 0
	JM	.LBB18_9
; %bb.8:                                ;   in Loop: Header=BB18_1 Depth=1
	MVI	L, 1
.LBB18_9:                               ;   in Loop: Header=BB18_1 Depth=1
	LDA	.LLo61_0+1
	SUB	L
	DCR	E
	LXI	H, .LLo61_3+1
	MOV	D, M
	CMP	D
	JNC	.LBB18_1
; %bb.10:
	RET
                                        ; -- End function
	.section	.text.sin8,"ax",@progbits
sin8:                                   ; -- Begin function sin8
                                        ; @sin8
; %bb.0:
	LXI	B, 0x168
	LXI	D, 0x168
	CALL	__modhi3
	XRA	A
	ADD	H
	JP	.LBB19_2
; %bb.1:
	DAD	B
.LBB19_2:
	MVI	A, 0x59
	SUB	L
	MVI	A, 0
	SBB	H
	JNC	.LBB19_9
; %bb.3:
	MVI	A, 0xb3
	SUB	L
	MVI	A, 0
	SBB	H
	JC	.LBB19_4
; %bb.8:
	LXI	D, 0xb4
	MOV	A, E
	SUB	L
	MOV	L, A
	MOV	A, D
	SBB	H
	MOV	H, A
.LBB19_9:
	;APP
	DAD	H
	LXI	D, sin_q_lut
	DAD	D
	MOV	A, M
	INX	H
	MOV	H, M
	MOV	L, A

	;NO_APP
	RET
.LBB19_4:
	MVI	A, 0xd
	SUB	L
	MVI	A, 1
	SBB	H
	JC	.LBB19_5
; %bb.6:
	LXI	D, 0x4c
	DAD	D
	JMP	.LBB19_7
.LBB19_5:
	LXI	D, 0x68
	MOV	A, E
	SUB	L
	MOV	L, A
	MOV	A, D
	SBB	H
.LBB19_7:
	MVI	H, 0
	;APP
	DAD	H
	LXI	D, sin_q_lut
	DAD	D
	MOV	A, M
	INX	H
	MOV	H, M
	MOV	L, A

	;NO_APP
	XRA	A
	SUB	L
	MOV	L, A
	SBB	A
	SUB	H
	MOV	H, A
	RET
                                        ; -- End function
	.section	.text.memset,"ax",@progbits
memset:                                 ; -- Begin function memset
                                        ; @memset
; %bb.0:
	SHLD	.LLo61_5+1
	LXI	H, 0x20
.LLo61_5:
	LXI	B, 0
	DAD	B
	MOV	B, H
	MOV	C, L
	LHLD	.LLo61_5+1
.LBB20_1:                               ; =>This Inner Loop Header: Depth=1
	MOV	M, E
	INX	H
	MOV	A, L
	CMP	C
	JNZ	.LBB20_1
; %bb.3:                                ;   in Loop: Header=BB20_1 Depth=1
	MOV	A, H
	CMP	B
	JNZ	.LBB20_1
; %bb.2:
	LHLD	.LLo61_5+1
	RET
                                        ; -- End function
	.section	.text.fill_rect,"ax",@progbits
fill_rect:                              ; -- Begin function fill_rect
                                        ; @fill_rect
; %bb.0:
	LXI	H, .LLo61_12+1
	MOV	M, D
	LXI	H, .LLo61_14+1
	MOV	M, B
	MOV	L, A
	MVI	D, 0
	MOV	E, C
	MOV	H, D
	LXI	B, 7
	XCHG
	DAD	B
	SHLD	.LLo61_10+1
	XCHG
	PUSH	H
	DAD	D
	MOV	C, L
	MVI	A, 7
	ANA	C
	LXI	D, REQ_BIT_MASK_R
	MOV	H, B
	MOV	L, A
	DAD	D
	XCHG
	POP	H
	XCHG
	SHLD	.LLo61_7+1
	XCHG
	MOV	E, L
	MVI	A, 7
	ANA	E
	MOV	E, A
	MOV	D, B
.LLo61_10:
	LXI	B, 0
	MOV	A, C
	ADD	E
	MOV	C, A
	MOV	A, B
	ADC	D
	PUSH	H
	MOV	L, C
	MOV	H, A
	SHLD	.LLo61_10+1
	LXI	B, REQ_BIT_MASK_L
	XCHG
	DAD	B
	XCHG
	POP	H
	XCHG
	SHLD	.LLo61_8+1
	XCHG
	LDA	.LLo61_14+1
	MVI	D, 0
	MOV	E, A
.LLo61_12:
	MVI	A, 0
	MOV	B, A
	MOV	C, D
	DAD	H
	DAD	H
	DAD	H
	DAD	H
	DAD	H
	MOV	L, C
	MVI	A, 0x1f
	ANA	H
	MOV	H, A
	PUSH	H
	MOV	H, B
	SHLD	.LLo61_9+1
	POP	H
	SHLD	.LLo61_11+1
	DAD	B
	XCHG
	SHLD	.LLo61_6+1
	XCHG
	MOV	A, L
	ORA	E
	MOV	L, A
	MOV	A, H
	ORA	D
	MOV	H, A
.LLo61_8:
	LXI	D, 0
	LDAX	D
	MOV	E, A
	PUSH	H
	LHLD	.LLo61_7+1
	MOV	C, L
	MOV	B, H
	LDAX	B
	MOV	D, A
	LHLD	.LLo61_10+1
	MOV	B, H
	XRA	A
	DAD	H
	ADC	A
	DAD	H
	ADC	A
	DAD	H
	ADC	A
	DAD	H
	ADC	A
	DAD	H
	ADC	A
	MOV	C, H
	MOV	B, A
	POP	H
	MVI	A, 1
	CMP	C
	JNZ	.LBB21_1
; %bb.7:
	XRA	A
	CMP	B
	JZ	.LBB21_5
.LBB21_1:
	MOV	A, D
	STA	.LLo61_13+1
	MVI	D, 0
	SHLD	.LLo61_10+1
	PUSH	H
	MOV	L, C
	MOV	H, B
	SHLD	.LLo61_7+1
	POP	H
	CALL	memset
	LHLD	.LLo61_7+1
	XCHG
	DCX	D
	MOV	A, E
	ANI	0xfe
	JZ	.LBB21_2
; %bb.3:
.LLo61_9:
	LXI	H, 0
.LLo61_11:
	LXI	B, 0
	DAD	B
	PUSH	H
	LHLD	.LLo61_6+1
	MOV	C, L
	MOV	B, H
	POP	H
	DAD	B
	LXI	B, 0x100
	DAD	B
	MOV	A, B
	XCHG
	SHLD	.LLo61_7+1
	XCHG
.LBB21_4:                               ; =>This Inner Loop Header: Depth=1
	STA	.LLo61_14+1
	SHLD	.LLo61_6+1
	LHLD	.LLo61_6+1
	LXI	D, 0xff
	CALL	memset
.LLo61_7:
	LXI	D, 0
	LXI	H, 0x100
.LLo61_6:
	LXI	B, 0
	DAD	B
	MOV	C, L
.LLo61_14:
	MVI	A, 0
	SHLD	.LLo61_6+1
	LHLD	.LLo61_6+1
	INR	A
	CMP	E
	JC	.LBB21_4
.LBB21_2:
	MOV	D, E
	MVI	E, 0
	LHLD	.LLo61_10+1
	DAD	D
.LLo61_13:
	MVI	E, 0
	JMP	.LBB21_6
.LBB21_5:
	MOV	A, D
	ANA	E
	MOV	E, A
.LBB21_6:
	MVI	D, 0
	JMP	memset
                                        ; -- End function
	.section	.text.draw,"ax",@progbits
	.globl	draw                            ; -- Begin function draw
draw:                                   ; @draw
; %bb.0:
	MVI	A, 0x64
.LBB22_1:                               ; =>This Inner Loop Header: Depth=1
	STA	.LLo61_19+1
	CALL	rand
	MOV	A, L
	MOV	B, H
	CALL	draw_line
	LDA	.LLo61_19+1
	DCR	A
	JNZ	.LBB22_1
; %bb.2:
	MVI	H, 0xa
	MVI	A, 0x64
.LBB22_3:                               ; =>This Inner Loop Header: Depth=1
	STA	.LLo61_19+1
	MOV	A, H
	STA	.LLo61_22+1
	LDA	.LLo61_19+1
	CALL	draw_circle
.LLo61_22:
	MVI	H, 0
	LDA	.LLo61_19+1
	ADI	0xf6
	DCR	H
	JNZ	.LBB22_3
; %bb.4:
	XRA	A
	LXI	H, 0
.LBB22_5:                               ; =>This Loop Header: Depth=1
                                        ;     Child Loop BB22_6 Depth 2
	LXI	D, 0x100
	MOV	B, A
	ADI	0x7f
	STA	.LLo61_23+1
	MOV	A, B
	STA	.LLo61_24+1
	ADD	A
	ADD	A
	ADD	A
	ADD	A
	ADD	A
	ORI	0x80
	STA	.LLo61_21+1
	XRA	A
	STA	.LLo61_20+1
	SHLD	.LLo61_17+1
.LBB22_6:                               ;   Parent Loop BB22_5 Depth=1
                                        ; =>  This Inner Loop Header: Depth=2
	SHLD	.LLo61_18+1
	XCHG
	SHLD	.LLo61_15+1
	SHLD	.LLo61_16+1
.LLo61_18:
	LXI	H, 0
	CALL	sin8
	MOV	A, H
	RLC
	SBB	A
	RLC
	RLC
	RLC
	ANI	7
	MOV	E, A
	MVI	D, 0
	DAD	D
.LLo61_16:
	LXI	D, 0
	XRA	A
	DAD	H
	ADC	A
	DAD	H
	ADC	A
	DAD	H
	ADC	A
	DAD	H
	ADC	A
	DAD	H
	ADC	A
	MOV	L, H
                                        ; kill: def $l killed $l killed $hl
.LLo61_23:
	MVI	H, 0
	MOV	A, L
	ADD	H
	MOV	B, A
.LLo61_20:
	MVI	E, 0
	MOV	A, E
.LLo61_21:
	MVI	C, 0
	CALL	draw_pixel
	LHLD	.LLo61_18+1
	INR	E
	MOV	A, E
	STA	.LLo61_20+1
	INX	H
	INX	H
.LLo61_15:
	LXI	B, 0
	DCX	B
	MOV	D, B
	MOV	E, C
	MOV	A, B
	ORA	C
	JNZ	.LBB22_6
; %bb.7:                                ;   in Loop: Header=BB22_5 Depth=1
.LLo61_17:
	LXI	H, 0
	LXI	D, 8
	DAD	D
.LLo61_24:
	MVI	A, 0
	INR	A
	CPI	0xb
	JNZ	.LBB22_5
; %bb.9:
	MVI	D, 3
	MVI	A, 0x3c
	MVI	H, 0x80
	MVI	E, 0x28
.LBB22_10:                              ; =>This Inner Loop Header: Depth=1
	MOV	B, A
	MOV	A, D
	STA	.LLo61_22+1
	MOV	A, B
	STA	.LLo61_19+1
	ADI	0x8c
	MOV	C, A
	MOV	A, E
	STA	.LLo61_23+1
.LLo61_19:
	MVI	B, 0
	MOV	D, H
	LXI	H, .LLo61_20+1
	MOV	M, D
	CALL	fill_rect
	LXI	H, .LLo61_22+1
	MOV	D, M
	LDA	.LLo61_23+1
	ADI	0xfc
	MOV	E, A
	LDA	.LLo61_20+1
	ADI	0x20
	MOV	H, A
	LDA	.LLo61_19+1
	ADI	0xf8
	DCR	D
	JNZ	.LBB22_10
; %bb.8:
	RET
                                        ; -- End function
	.section	.text.main,"ax",@progbits
	.globl	main                            ; -- Begin function main
main:                                   ; @main
; %bb.0:
	LXI	H, v6_interruption
	;APP
	MVI	A, 0xc3
	STA	0x38
	SHLD	0x39

	;NO_APP
	;APP
	EI

	;NO_APP
	MVI	A, 1
	STA	v6_palette_update_request
	LXI	H, song01_ay_reg_data_ptrs
	LXI	D, _v6_gc_buffer
	XRA	A
	CALL	v6_gc_init_song
	CALL	v6_gc_start
.LBB23_1:                               ; =>This Inner Loop Header: Depth=1
	;APP
	HLT

	;NO_APP
	JMP	.LBB23_1
                                        ; -- End function
	.data
	.globl	v6_palette                      ; @v6_palette
v6_palette:
	.ascii	"\000\021\"3DUfw\210\231\252\273\314\335\356\377"

	.section	.bss,"aw",@nobits
	.globl	v6_scr_offset_y                 ; @v6_scr_offset_y
v6_scr_offset_y:
	DB	0                               ; 0x0

	.globl	v6_game_updates_required        ; @v6_game_updates_required
v6_game_updates_required:
	DB	0                               ; 0x0

	.globl	song01_ram_disk_m               ; @song01_ram_disk_m
song01_ram_disk_m:
	DB	0                               ; 0x0

	.data
__v6c_rand_state:                       ; @__v6c_rand_state
	DW	1                               ; 0x1

	.section	.rodata,"a",@progbits
BIT_MASK:                               ; @BIT_MASK
	.ascii	"\200@ \020\b\004\002\001"

sin_q_lut:                              ; @sin_q_lut
	DW	0                               ; 0x0
	DW	4                               ; 0x4
	DW	9                               ; 0x9
	DW	13                              ; 0xd
	DW	18                              ; 0x12
	DW	22                              ; 0x16
	DW	27                              ; 0x1b
	DW	31                              ; 0x1f
	DW	36                              ; 0x24
	DW	40                              ; 0x28
	DW	44                              ; 0x2c
	DW	49                              ; 0x31
	DW	53                              ; 0x35
	DW	58                              ; 0x3a
	DW	62                              ; 0x3e
	DW	66                              ; 0x42
	DW	71                              ; 0x47
	DW	75                              ; 0x4b
	DW	79                              ; 0x4f
	DW	83                              ; 0x53
	DW	88                              ; 0x58
	DW	92                              ; 0x5c
	DW	96                              ; 0x60
	DW	100                             ; 0x64
	DW	104                             ; 0x68
	DW	108                             ; 0x6c
	DW	112                             ; 0x70
	DW	116                             ; 0x74
	DW	120                             ; 0x78
	DW	124                             ; 0x7c
	DW	128                             ; 0x80
	DW	132                             ; 0x84
	DW	136                             ; 0x88
	DW	139                             ; 0x8b
	DW	143                             ; 0x8f
	DW	147                             ; 0x93
	DW	150                             ; 0x96
	DW	154                             ; 0x9a
	DW	158                             ; 0x9e
	DW	161                             ; 0xa1
	DW	165                             ; 0xa5
	DW	168                             ; 0xa8
	DW	171                             ; 0xab
	DW	175                             ; 0xaf
	DW	178                             ; 0xb2
	DW	181                             ; 0xb5
	DW	184                             ; 0xb8
	DW	187                             ; 0xbb
	DW	190                             ; 0xbe
	DW	193                             ; 0xc1
	DW	196                             ; 0xc4
	DW	199                             ; 0xc7
	DW	202                             ; 0xca
	DW	204                             ; 0xcc
	DW	207                             ; 0xcf
	DW	210                             ; 0xd2
	DW	212                             ; 0xd4
	DW	215                             ; 0xd7
	DW	217                             ; 0xd9
	DW	219                             ; 0xdb
	DW	222                             ; 0xde
	DW	224                             ; 0xe0
	DW	226                             ; 0xe2
	DW	228                             ; 0xe4
	DW	230                             ; 0xe6
	DW	232                             ; 0xe8
	DW	234                             ; 0xea
	DW	236                             ; 0xec
	DW	237                             ; 0xed
	DW	239                             ; 0xef
	DW	241                             ; 0xf1
	DW	242                             ; 0xf2
	DW	243                             ; 0xf3
	DW	245                             ; 0xf5
	DW	246                             ; 0xf6
	DW	247                             ; 0xf7
	DW	248                             ; 0xf8
	DW	249                             ; 0xf9
	DW	250                             ; 0xfa
	DW	251                             ; 0xfb
	DW	252                             ; 0xfc
	DW	253                             ; 0xfd
	DW	254                             ; 0xfe
	DW	254                             ; 0xfe
	DW	255                             ; 0xff
	DW	255                             ; 0xff
	DW	255                             ; 0xff
	DW	256                             ; 0x100
	DW	256                             ; 0x100
	DW	256                             ; 0x100
	DW	256                             ; 0x100

	.section	.rodata.cst8,"aM",@progbits,8
REQ_BIT_MASK_L:                         ; @REQ_BIT_MASK_L
	.ascii	"\377\177?\037\017\007\003\001"

REQ_BIT_MASK_R:                         ; @REQ_BIT_MASK_R
	.ascii	"\200\300\340\360\370\374\376\377"

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
	.addrsig_sym v6_interruption
	.addrsig_sym song01_ay_reg_data_ptrs
	.addrsig_sym _v6_gc_buffer
	.addrsig_sym __v6c_rand_state
	.addrsig_sym BIT_MASK
	.addrsig_sym sin_q_lut
