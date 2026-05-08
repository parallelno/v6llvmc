	.text
	.section	.text.addi16,"ax",@progbits
	.globl	addi16                          ; -- Begin function addi16
addi16:                                 ; @addi16
; %bb.0:
	DCX	H
.LBB15_1:                               ; =>This Inner Loop Header: Depth=1
	INX	H
	ADD	A
	JNZ	.LBB15_1
; %bb.2:
	RET
                                        ; -- End function
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
