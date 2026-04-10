#include "zerobitcount.h"

uint16_t __global ZeroBitCount(const void *, size_t) {
    asm {
__a_2_zerobitcount = 0
        ; Размер массива
        ld   b, h
        ld   c, l

        ; Результат
        ld   hl, 0

        ; Адрес
__a_1_zerobitcount = $+1
        ld   de, 0

        ; Если размер 0
        ld   a, b
        or   c
        ret  z

BitCount_0:
        ; Получить байт
        ld   a, (de)
        inc  de

        ; Подсчитать единичные биты в байте
        push bc
        ld   c, 8
BitCount_1:
        rrca
        jp   c, BitCount_2
        inc  hl
BitCount_2:
        dec  c
        jp   nz, BitCount_1
        pop  bc

        ; Цикл
        dec  bc
        ld   a, b
        or   c
        jp   nz, BitCount_0
    }
}
