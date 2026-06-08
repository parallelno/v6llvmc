	.text
	.section	.text.memset,"ax",@progbits
memset:                                 ; -- Begin function memset
                                        ; @memset
; %bb.0:
	LXI	H, 0x8000
.LBB15_1:                               ; =>This Inner Loop Header: Depth=1
	MVI	M, 0
	INX	H
	MOV	A, H
	ORA	L
	JNZ	.LBB15_1
; %bb.2:
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
	CALL	memset
	LXI	H, v6_scr_offset_y
.LBB16_1:                               ; =>This Inner Loop Header: Depth=1
	XCHG
	LHLD	v6_action_code
	XCHG
	MOV	A, D
	ORA	E
	JZ	.LBB16_7
; %bb.2:                                ;   in Loop: Header=BB16_1 Depth=1
	MOV	A, E
	CPI	4
	JZ	.LBB16_5
; %bb.3:                                ;   in Loop: Header=BB16_1 Depth=1
	CPI	8
	JNZ	.LBB16_7
; %bb.4:                                ;   in Loop: Header=BB16_1 Depth=1
	MVI	A, 1
	JMP	.LBB16_6
.LBB16_5:                               ;   in Loop: Header=BB16_1 Depth=1
	MVI	A, 0xff
.LBB16_6:                               ;   in Loop: Header=BB16_1 Depth=1
	ADD	M
	STA	v6_scr_offset_y
.LBB16_7:                               ;   in Loop: Header=BB16_1 Depth=1
	;APP
	HLT

	;NO_APP
	JMP	.LBB16_1
                                        ; -- End function
	.data
	.globl	v6_palette                      ; @v6_palette
v6_palette:
	.ascii	"\000\021\"3DUfw\210\231\252\273\314\335\356\377"

	.section	.bss,"aw",@nobits
	.globl	v6_scr_offset_y                 ; @v6_scr_offset_y
v6_scr_offset_y:
	DB	0                               ; 0x0

	.globl	v6_ram_disk_mode                ; @v6_ram_disk_mode
v6_ram_disk_mode:
	DB	0                               ; 0x0

	.globl	v6_game_updates_required        ; @v6_game_updates_required
v6_game_updates_required:
	DB	0                               ; 0x0

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
