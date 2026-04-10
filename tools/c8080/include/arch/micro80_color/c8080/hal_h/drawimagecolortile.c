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

void __global DrawImageColorTile(void *tile, uint8_t color, const void *image) {
    asm {
__a_3_drawimagecolortile=0
        ld   c, (hl)
        inc  hl
        ld   b, (hl)
        inc  hl
        ex   hl, de

        ld   a, (__a_2_drawimagecolortile)
        add  a
        add  a
        add  a
        add  a
        ld   (drawimagecolortile_tb), a

__a_1_drawimagecolortile=$+1
        ld   hl, 0 ; tile
drawimagecolortile_l1:
        push bc
        push hl
drawimagecolortile_l2:
        ld   a, h
        sub  08h
        ld   h, a

        ld   a, (de)

        ; Change color
        ld   b, a
        and  07h
        cp   4  ; From color
        ld   a, b
        jp   nz, drawimagecolortile_l3
        and  ~07h
__a_2_drawimagecolortile=$+1
        or   0 ; To color
        ld   b, a
drawimagecolortile_l3:

        and  7 << 4
        cp   4 << 4  ; From color
        ld   a, b
        jp   nz, drawimagecolortile_l4
        and  ~(7 << 4)
drawimagecolortile_tb=$+1
        or   0
drawimagecolortile_l4:

        inc  de
        ld   (hl), a

        ld   a, h
        add  08h
        ld   h, a

        ld   a, (de)
        inc  de
        ld   (hl), a

        inc  l

        dec  c
        jp   nz, drawimagecolortile_l2

        pop  hl

        ld   bc, 64
        add  hl, bc

        pop  bc

        dec  b
        jp   nz, drawimagecolortile_l1
    }
}
