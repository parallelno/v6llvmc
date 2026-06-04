	.text
	.section	.text.memcpy,"ax",@progbits
memcpy:                                 ; -- Begin function memcpy
                                        ; @memcpy
; %bb.0:
	LXI	B, 8
	;APP
	PUSH	H
.Ltmp0:
	MOV	A, B
	ORA	C
	JZ	.Ltmp1
	LDAX	D
	MOV	M, A
	INX	H
	INX	D
	DCX	B
	JMP	.Ltmp0
.Ltmp1:
	POP	H
	RET


	;NO_APP
	RET
                                        ; -- End function
	.section	.text.draw_text,"ax",@progbits
draw_text:                              ; -- Begin function draw_text
                                        ; @draw_text
; %bb.0:
	MOV	B, H
	MOV	C, L
	MOV	D, A
	LDAX	B
	MOV	E, A
	MOV	A, D
	INR	E
	DCR	E
	RZ
.LBB17_1:
	MVI	H, 0
	MOV	L, A
	INX	B
	MVI	A, 0xc8
	ORA	H
	MOV	H, A
.LBB17_2:                               ; =>This Inner Loop Header: Depth=1
	PUSH	H
	MOV	L, C
	MOV	H, B
	SHLD	.LLo61_0+1
	POP	H
	MVI	D, 0
	XCHG
	DAD	H
	DAD	H
	DAD	H
	LXI	B, __font-256
	DAD	B
	XCHG
	CALL	memcpy
.LLo61_0:
	LXI	B, 0
	LXI	D, 0x100
	DAD	D
	LDAX	B
	MOV	E, A
	INX	B
	XRA	A
	CMP	E
	JNZ	.LBB17_2
; %bb.3:
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
	JP	.LBB18_2
; %bb.1:
	DAD	B
.LBB18_2:
	MVI	A, 0x59
	SUB	L
	MVI	A, 0
	SBB	H
	JNC	.LBB18_9
; %bb.3:
	MVI	A, 0xb3
	SUB	L
	MVI	A, 0
	SBB	H
	JC	.LBB18_4
; %bb.8:
	LXI	D, 0xb4
	MOV	A, E
	SUB	L
	MOV	L, A
	MOV	A, D
	SBB	H
	MOV	H, A
.LBB18_9:
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
.LBB18_4:
	MVI	A, 0xd
	SUB	L
	MVI	A, 1
	SBB	H
	JC	.LBB18_5
; %bb.6:
	LXI	D, 0x4c
	DAD	D
	JMP	.LBB18_7
.LBB18_5:
	LXI	D, 0x68
	MOV	A, E
	SUB	L
	MOV	L, A
	MOV	A, D
	SBB	H
	MOV	H, A
.LBB18_7:
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
	.section	.text.main,"ax",@progbits
	.globl	main                            ; -- Begin function main
main:                                   ; @main
; %bb.0:
	LXI	H, 0xfff8
	DAD	SP
	SPHL
	MVI	E, 0
	MVI	A, 1
	LXI	H, 0
.LBB20_1:                               ; =>This Loop Header: Depth=1
                                        ;     Child Loop BB20_2 Depth 2
	PUSH	H
	LXI	H, 2
	DAD	SP
	MOV	M, A
	LXI	B, 0x100
	MOV	D, E
	MOV	A, D
	ADI	0x7f
	LXI	H, 3
	DAD	SP
	MOV	M, A
	MOV	A, D
	ADD	A
	ADD	A
	ADD	A
	ADD	A
	ADD	A
	ORI	0x80
	LXI	H, 4
	DAD	SP
	MOV	M, A
	XRA	A
	LXI	H, 7
	DAD	SP
	MOV	M, A
	POP	H
.LBB20_2:                               ;   Parent Loop BB20_1 Depth=1
                                        ; =>  This Inner Loop Header: Depth=2
	PUSH	H
	LXI	H, 5
	DAD	SP
	MOV	M, C
	INX	H
	MOV	M, B
	POP	H
	XCHG
	LXI	H, 6
	DAD	SP
	MOV	M, E
	INX	H
	MOV	M, D
	XCHG
	CALL	sin8
	MOV	A, H
	RLC
	SBB	A
	RLC
	RLC
	ANI	3
	MOV	E, A
	MVI	D, 0
	DAD	D
	MOV	A, H
	ORA	A
	RAR
	MOV	H, A
	MOV	A, L
	RAR
	MOV	L, A
	MOV	A, H
	ORA	A
	RAR
	MOV	A, L
	RAR
	MOV	L, A
                                        ; kill: def $l killed $l killed $hl
	PUSH	D
	MOV	D, L
	LXI	H, 3
	DAD	SP
	MOV	H, M
	MOV	A, D
	POP	D
	ADD	H
	MOV	B, A
	LXI	H, 5
	DAD	SP
	MOV	E, M
	MOV	A, E
	LXI	H, 2
	DAD	SP
	MOV	C, M
	CALL	draw_pixel
	LXI	H, 3
	DAD	SP
	MOV	C, M
	INX	H
	MOV	B, M
	PUSH	D
	LXI	H, 8
	DAD	SP
	MOV	E, M
	INX	H
	MOV	D, M
	XCHG
	POP	D
	INX	H
	INR	E
	PUSH	H
	LXI	H, 7
	DAD	SP
	MOV	M, E
	POP	H
	DCX	B
	MOV	A, B
	ORA	C
	JNZ	.LBB20_2
; %bb.4:                                ;   in Loop: Header=BB20_1 Depth=1
	LXI	H, 0
	DAD	SP
	MOV	A, M
	ANI	1
	MVI	E, 1
	MOV	A, B
	LXI	H, 1
	JNZ	.LBB20_1
; %bb.3:
	LXI	H, .str
	MVI	A, 0xf0
	CALL	draw_text
	LXI	H, .str.1
	MVI	A, 0xe4
	CALL	draw_text
	LXI	H, .str.2
	MVI	A, 0xd8
	CALL	draw_text
	LXI	H, .str.3
	MVI	A, 0xcc
	CALL	draw_text
	LXI	H, 8
	DAD	SP
	SPHL
	RET
                                        ; -- End function
	.data
	.globl	__v6c_rand_state                ; @__v6c_rand_state
__v6c_rand_state:
	DW	1                               ; 0x1

	.section	.rodata,"a",@progbits
__font:                                 ; @__font
	.ascii	"\b\000\b\b\b\b\b\b"
	.ascii	"\000\000\000\000\000$$$"
	.ascii	"\000$$~$~$$"
	.ascii	"\b>H<\022|\b\000"
	.ascii	"bd\b\020&F\000\000"
	.ascii	"4JD8DJ4\000"
	.ascii	"\000\000\000\000\000\b\b\b"
	.ascii	"\004\b\020\020\020\b\004\000"
	.ascii	"\020\b\004\004\004\b\020\000"
	.ascii	"\000\b*\034*\b\000\000"
	.ascii	"\000\b\b>\b\b\000\000"
	.ascii	"\020\b\b\000\000\000\000\000"
	.ascii	"\000\000\000>\000\000\000\000"
	.ascii	"\b\000\000\000\000\000\000\000"
	.ascii	"\002\004\b\020 @\000\000"
	.ascii	"<BFJRbB<"
	.ascii	">\b\b\b\b\030\b\b"
	.ascii	"~@ \020\b\004B<"
	.ascii	"<B\002\034\002\002B<"
	.ascii	"\004\004~D$\024\f\f"
	.ascii	"<B\002\002|@@~"
	.ascii	"<BB|@@B<"
	.ascii	"  \020\b\004\002\002~"
	.ascii	"<BB<BBB<"
	.ascii	"<B\002\002>BB<"
	.ascii	"\000\000\030\030\000\030\030\000"
	.ascii	"\020\b\030\030\000\030\030\000"
	.ascii	"\004\b\020 \020\b\004\000"
	.ascii	"\000\000~\000~\000\000\000"
	.ascii	"\020\b\004\002\004\b\020\000"
	.ascii	"\b\000\b\004\002!!\036"
	.ascii	"<@^R^BB<"
	.ascii	"BB~BB$$\030"
	.ascii	"|BB|BBB|"
	.ascii	"<B@@@@B<"
	.ascii	"xDBBBBDx"
	.ascii	"~@@|@@@~"
	.ascii	"@@@|@@@~"
	.ascii	"<BFB@@B<"
	.ascii	"BBB~BBBB"
	.ascii	"<\b\b\b\b\b\b<"
	.ascii	"0H\b\b\b\b\b\036"
	.ascii	"BDHpHDBB"
	.ascii	"~@@@@@@@"
	.ascii	"BBBBZfBB"
	.ascii	"BBFJRbBB"
	.ascii	"<BBBBBB<"
	.ascii	"@@@|BBB|"
	.ascii	":DJBBBB<"
	.ascii	"BDH|BBB|"
	.ascii	"<B\002<@BB<"
	.ascii	"\b\b\b\b\b\b\b~"
	.ascii	"<BBBBBBB"
	.ascii	"\030$$BBBBB"
	.ascii	"BBfZBBBB"
	.ascii	"BB$\030\030$BB"
	.ascii	"\b\b\b\030$BBB"
	.ascii	"~@ \020\b\004\002~"

	.data
	.globl	__font_ptr                      ; @__font_ptr
__font_ptr:
	DW	__font

	.section	.rodata.str1.1,"aMS",@progbits,1
.str:                                   ; @.str
	.ascii	" !\"#$%&'()*+,-./\000"

.str.1:                                 ; @.str.1
	.ascii	"0123456789:;<=>?\000"

.str.2:                                 ; @.str.2
	.ascii	"@ABCDEFGHIJKLMNO\000"

.str.3:                                 ; @.str.3
	.ascii	"PQRSTUVWXYZ\000"

	.section	.rodata,"a",@progbits
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

BIT_MASK:                               ; @BIT_MASK
	.ascii	"\200@ \020\b\004\002\001"

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
	.addrsig_sym v6c_interrupt
	.addrsig_sym __font
	.addrsig_sym sin_q_lut
	.addrsig_sym BIT_MASK
