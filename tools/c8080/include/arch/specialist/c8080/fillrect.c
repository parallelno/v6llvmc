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

#include "fillrect.h"

void FillRectOver(void) {
    (void)FillRectTrue;
    asm {
        ld   a, 0AAh ; XOR D
        jp   fillrecttrue_1
    }
}

void FillRectInverse(void) {
    (void)FillRectTrue;
    asm {
        ld   a, 0A2h ; AND D
        ld   (fillrect_int_cmd), a
        ld   a, 02Fh ; CMA
        jp   fillrecttrue_2
    }
}

void FillRectTrue(void) {
    asm {
        ld   a, 0B2h ; OR D
fillrecttrue_1:
        ld   (fillrect_int_cmd), a
        xor  a ; NOP
fillrecttrue_2:
        ld   (fillrect_int_cmd2), a
    }
}

void __global FillRectInt(uint8_t len, uint8_t x, uint8_t *a) {
    asm {
__a_3_fillrectint=0
__a_2_fillrectint=$+1
        ld   a, 0
fillrect_int_cmd2:
        nop          ; CMA = 2F NOP = 00
        ld   d, a
__a_1_fillrectint=$+1
        ld   e, 0
fillrect_int_l0:
        ld   a, (hl)
fillrect_int_cmd:
        or   d        ; XOR D = AA, AND D = A2, OR D = B2
        ld   (hl), a
        inc  l
        dec  e
        jp   nz, fillrect_int_l0
    }
}

void FillRect(uint8_t *tile, uint16_t centerSize, uint8_t leftMask, uint8_t rightMask, uint8_t height) {
    if (centerSize == 0) {
        FillRectInt(height, leftMask & rightMask, tile);
        return;
    }
    --centerSize;
    FillRectInt(height, leftMask, tile);
    tile += SCREEN_BPL;
    for (; centerSize; --centerSize) {
        FillRectInt(height, 0xFF, tile);
        tile += SCREEN_BPL;
    }
    FillRectInt(height, rightMask, tile);
}

void FillRectXY(uint16_t x0, uint8_t y0, uint16_t x1, uint8_t y1) {
    FillRect(FILLRECTARGS(x0, y0, x1, y1));
}
