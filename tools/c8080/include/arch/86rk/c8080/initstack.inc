    asm {
        call 0F830h  ; Get RAM top
        ld   sp, hl
        ld   hl, 0F86Ch  ; Monitor
        push hl
    }
