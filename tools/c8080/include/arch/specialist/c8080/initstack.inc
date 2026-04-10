    asm {
        ld   sp, 089FFh ; BIOS variables
        ld   hl, 0C800h ; Reboot
        push hl
    }
