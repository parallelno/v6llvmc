; external.s - hand-written i8080 asm bodies for the inline-asm clobber test.
;
; Each function lives in its own .text.<name> section so that ld.lld
; --gc-sections can drop them individually when unreachable.
;
; Reachability graph from _start:
;   _start (crt0) -> main -> [inline asm] CALL func1 -> CALL func2 -> RET
; func3 and func4 are not referenced anywhere in the reachable closure
; and therefore must be removed from the final ROM.

    .section .text.func1, "ax"
    .globl func1
func1:
    MVI A, 0x31           ; '1'
    OUT 0xED
    CALL func2
    RET

    .section .text.func2, "ax"
    .globl func2
func2:
    MVI A, 0x32           ; '2'
    OUT 0xED
    RET

    .section .text.func3, "ax"
    .globl func3
func3:
    MVI A, 0x33           ; '3' - must NOT execute (unreachable)
    OUT 0xED
    CALL func4
    RET

    .section .text.func4, "ax"
    .globl func4
func4:
    MVI A, 0x34           ; '4' - must NOT execute (unreachable)
    OUT 0xED
    RET
