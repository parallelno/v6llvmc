	.text
	.section	.text.main,"ax",@progbits
	.globl	main                            ; -- Begin function main
main:                                   ; @main
; %bb.0:
	;APP
	CALL	func1
	;NO_APP
	HLT
	LXI	H, 0
	RET
                                        ; -- End function
	.addrsig
