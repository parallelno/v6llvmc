/*
 * c8080 stdlib
 * Copyright (c) 2025 Aleksey Morozov aleksey.f.morozov@gmail.com aleksey.f.morozov@yandex.ru
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#include <c8080/hal.h>
#include <c8080/chargen6.h>

void DrawTextXor(void) {
    (void)DrawTextNormal;
    asm {
        ld   hl, 000FEh ; NOP + CPI
        jp   drawTextNormal_1
    }
}

void DrawTextInverse(void) {
    (void)DrawTextNormal;
    asm {
        ld   hl, 02FE6h ; CMA + AND
        jp   drawTextNormal_1
    }
}

void DrawTextNormal(void) {
    asm {
        ld   hl, 000E6h ; NOP + AND
drawTextNormal_1:
        ld   a, l
        ld   (drawtext_and1), a
        ld   (drawtext_and2), a
        ld   (drawtext_and3), a
        ld   (drawtext_and4), a
        ld   (drawtext_and5), a
        ld   (drawtext_and6), a
        ld   a, h
        ld   (drawtext_cma1), a
        ld   (drawtext_cma2), a
        ld   (drawtext_cma3), a
        ld   (drawtext_cma4), a
        ld   (drawtext_cma5), a
    }
}

static void __global DrawTextA(void *, void *) {
    asm {
__a_2_drawtexta=0
        ex   hl, de
__a_1_drawtexta=$+1
        ld   hl, 0
        ld   c,  8
drawtexta6_1:
        ld   a,  (de)
drawtext_cma1:
        nop
        add  a
        add  a
        ld   b, a
        ld   a, (hl)
drawtext_and1:
        and  3
        xor  b
        ld   (hl), a
        inc  de
        inc  hl
        dec  c
        jp   nz, drawtexta6_1
    }
}

static void __global DrawTextD(void *, void *) {
    asm {
__a_2_drawtextd=0
        ex   hl, de
__a_1_drawtextd=$+1
        ld   hl, 0
        ld   c, 8
drawtextd6_1:
        ld   a, (de)
drawtext_cma2:
        nop
        add  a
        adc  a
        adc  a
        adc  a
        push af
        adc  a
        and  00000011b
        ld   b, a
        ld   a, (hl)
drawtext_and2:
        and  0FCh
        xor  b
        ld   (hl), a

        inc  h

        pop  af
        and  011110000b
        ld   b, a
        ld   a, (hl)
drawtext_and3:
        and  00Fh
        xor  b
        ld   (hl), a

        dec  h

        inc  de
        inc  hl
        dec  c
        jp   nz, drawtextd6_1
    }
}

static void __global DrawTextC(void *, void *) {
    asm {
__a_2_drawtextc=0
        ex   hl, de
__a_1_drawtextc=$+1
        ld   hl, 0
        ld   c,  8
drawtextc6_1:
        ld   a, (de)
drawtext_cma3:
        nop
        rra
        rra
        and  00001111b
        ld   b, a
        ld   a, (hl)
drawtext_and4:
        and  0F0h
        xor  B
        ld   (hl), A

        inc  h

        ld   a, (de)
drawtext_cma4:
        nop
        rra
        rra
        rra
        and  11000000b
        ld   b, a
        ld   a, (hl);
drawtext_and5:
        and  03Fh
        xor  b
        ld   (hl), a

        dec  h

        inc  de
        inc  hl
        dec  c
        jp   nz, drawtextc6_1
    }
}

static void __global DrawTextB(void *, void *) {
    asm {
__a_2_drawtextb=0
        ex   hl, de
__a_1_drawtextb=$+1
        ld   hl, 0
        ld   c,  8
drawtextb6_1:
        ld   a, (de)
drawtext_cma5:
        nop
        and  03Fh
        ld   b, a
        ld   a, (hl)
drawtext_and6:
        and  0C0h
        xor  b
        ld   (hl), a
        inc  de
        inc  hl
        dec  c
        jp   nz, drawtextb6_1
    }
}

void __global DrawText(void *tile, uint8_t x, uint8_t color, const char *text) {
    SET_COLOR(color);
    for (;;) {
        uint8_t c = *text;
        if (c == 0)
            return;
        uint8_t *s = chargen6 + c * 8;
        switch (x) {
            case 0:
                DrawTextA(tile, s);
                x = 3;
                break;
            case 1:
                DrawTextB(tile, s);
                x = 0;
                tile = ((uint8_t *)tile + SCREEN_BPL);
                break;
            case 2:
                DrawTextC(tile, s);
                x = 1;
                tile = ((uint8_t *)tile + SCREEN_BPL);
                break;
            case 3:
                DrawTextD(tile, s);
                x = 2;
                tile = ((uint8_t *)tile + SCREEN_BPL);
                break;
        }
        text++;
    }
}
