	.text
	.section	.text.v6c_set_palette,"ax",@progbits
v6c_set_palette:                        ; -- Begin function v6c_set_palette
                                        ; @v6c_set_palette
.Lfunc_begin0:
	;=== void v6c_set_palette(void) ===
	;  [folded: wait_for_vsync=1]
; %bb.0:
	;DEBUG_VALUE: v6c_set_palette:wait_for_vsync <- 1
	;APP
	HLT

	;NO_APP
	LXI	H, palette+15
	;APP
	MVI	A, 0x88
	OUT	0
	MVI	B, 0xf
.Ltmp0:
	MOV	A, B
	OUT	2
	MOV	A, M
	OUT	0xc
	PUSH	PSW
	POP	PSW
	PUSH	PSW
	POP	PSW
	DCX	H
	DCR	B
	OUT	0xc
	JP	.Ltmp0

	;NO_APP
	RET
.Lfunc_end0:
                                        ; -- End function
	.section	.text.memset,"ax",@progbits
memset:                                 ; -- Begin function memset
                                        ; @memset
.Lfunc_begin1:
	;=== void memset(void) ===
	;  [folded: dst=0x8000, val=0, n=0x8000]
; %bb.0:
	;DEBUG_VALUE: memset:dst <- -32768
	;DEBUG_VALUE: memset:val <- 0
	;DEBUG_VALUE: memset:n <- -32768
	;DEBUG_VALUE: memset:p <- -32768
	;DEBUG_VALUE: i <- 0
	LXI	H, 0x8000
.LBB16_1:                               ; =>This Inner Loop Header: Depth=1
	;DEBUG_VALUE: memset:p <- -32768
	;DEBUG_VALUE: memset:n <- -32768
	;DEBUG_VALUE: memset:val <- 0
	;DEBUG_VALUE: memset:dst <- -32768
	;DEBUG_VALUE: i <- undef
	;--- V6C_STORE8_IMM_P ---
	MVI	M, 0
	;--- V6C_INX16 ---
	INX	H
	;--- V6C_BR_CC16_IMM ---
	MOV	A, H
	ORA	L
	JNZ	.LBB16_1
; %bb.2:
	;DEBUG_VALUE: memset:p <- -32768
	;DEBUG_VALUE: memset:n <- -32768
	;DEBUG_VALUE: memset:val <- 0
	;DEBUG_VALUE: memset:dst <- -32768
	RET
.Lfunc_end1:
                                        ; -- End function
	.section	.text.main,"ax",@progbits
	.globl	main                            ; -- Begin function main
main:                                   ; @main
.Lfunc_begin2:
	;=== void main(void) ===
	;  [folded: handler=@v6c_interrupt_handler]
; %bb.0:
	LXI	H, v6c_interrupt_handler
	;DEBUG_VALUE: v6c_set_interrupt_handler:handler <- $hl
	;DEBUG_VALUE: v6c_set_interrupt_handler:_handler <- $hl
	;APP
	MVI	A, 0xc3
	STA	0x38
	SHLD	0x39

	;NO_APP
	;APP
	EI

	;NO_APP
	CALL	v6c_set_palette
	JMP	memset
.Lfunc_end2:
                                        ; -- End function
	.section	.text.v6c_interrupt_handler,"ax",@progbits
v6c_interrupt_handler:                  ; -- Begin function v6c_interrupt_handler
                                        ; @v6c_interrupt_handler
.Lfunc_begin3:
	;=== void v6c_interrupt_handler(void) ===
; %bb.0:
	;APP
	XTHL

	SHLD	.L_INT_RETURN+1
	POP	H
	SHLD	.L_INT_RESTORE_HL+1
	PUSH	PSW
	POP	H
	SHLD	0x7fcc
	LXI	H, 0
	DAD	SP
	SHLD	.L_INT_RESTORE_SP+1
	PUSH	B

	;NO_APP
	;APP
	XRA	A

	;NO_APP
	;APP
	OUT	0x11

	;NO_APP
	;APP
	LXI	SP, 0x7fcc
	PUSH	B
	PUSH	D
	POP	D
	POP	B
	POP	PSW
	MOV	L, A

	;NO_APP
	;APP
	LDA	ram_disk_mode
	OUT	0x11

	;NO_APP
	;APP
	MOV	A, L
.L_INT_RESTORE_HL:
	LXI	H, 0
.L_INT_RESTORE_SP:
	LXI	SP, 0
	EI

.L_INT_RETURN:
	JMP	0x0

	;NO_APP
	RET
.Lfunc_end3:
                                        ; -- End function
	.data
	.globl	__v6c_rand_state                ; @__v6c_rand_state
__v6c_rand_state:
	DW	1                               ; 0x1

	.section	.bss,"aw",@nobits
	.globl	ram_disk_mode                   ; @ram_disk_mode
ram_disk_mode:
	DB	0                               ; 0x0

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

palette:                                ; @palette
	.ascii	"\000\021\"3DUfw\210\231\252\273\314\335\356\377"

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
	.addrsig_sym v6c_interrupt_handler
	.addrsig_sym __font
	.addrsig_sym palette
