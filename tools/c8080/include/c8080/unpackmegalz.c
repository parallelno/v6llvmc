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

#include "unpackmegalz.h"

void *__global UnpackMegalz(void *destination, const void *source) {
    asm {
__a_2_unpackmegalz=0
        ex   hl, de  ; source
__a_1_unpackmegalz=$+1
        ld   bc, 0  ; destination
        ld   a, 0x80
UnpackMegalz_0:
        ld   (UnpackMegalz_5 + 1), a
        ld   a, (de)
        inc  de
        jp   UnpackMegalz_4
UnpackMegalz_1:
        ld   a, (hl)
        inc  hl
        ld   (bc), a
        inc  bc
UnpackMegalz_2:
        ld   a, (hl)
        inc  hl
        ld   (bc), a
        inc  bc
UnpackMegalz_3:
        ld   a, (hl)
UnpackMegalz_4:
        ld   (bc), a
        inc  bc
UnpackMegalz_5:
        ld   a, 0x80
        add  a
        call z, UnpackMegalz_20
        jp   c, UnpackMegalz_0
        add  a
        call z, UnpackMegalz_20
        jp   c, UnpackMegalz_7
        add  a
        call z, UnpackMegalz_20
        jp   c, UnpackMegalz_6
        ld   hl, 16383
        call UnpackMegalz_16
        ld   (UnpackMegalz_5 + 1), a
        add  hl, bc
        jp   UnpackMegalz_3

UnpackMegalz_6:
        ld   (UnpackMegalz_5 + 1), a
        ld   a, (de)
        inc  de
        ld   l, a
        ld   h, 255
        add  hl, bc
        jp   UnpackMegalz_2

UnpackMegalz_7:
        add  a
        call z, UnpackMegalz_20
        jp   c, UnpackMegalz_8
        call UnpackMegalz_18
        add  hl, bc
        jp   UnpackMegalz_1

UnpackMegalz_8:
        ld   h, 0
UnpackMegalz_9:
        inc  h
        add  a
        call z, UnpackMegalz_20
        jp   nc, UnpackMegalz_9
UnpackMegalz_10:
        push af
        ld   a, h
        cp   8
        jp   nc, UnpackMegalz_15
        ld   a, 0
UnpackMegalz_11:
        rra
        dec  h
        jp   nz, UnpackMegalz_11
UnpackMegalz_12:
        ld   h, a
        ld   l, 1
        pop  af
        call UnpackMegalz_16
        inc  hl
        inc  hl
        push hl
        call UnpackMegalz_18
        ex de, hl
        ex   (sp), hl
        ex de, hl
        add  hl, bc
UnpackMegalz_13:
        ld   a, (hl)
        inc  hl
        ld   (bc), a
        inc  bc
        dec  e
        jp   nz, UnpackMegalz_13
UnpackMegalz_14:
        pop  de
        jp   UnpackMegalz_5
UnpackMegalz_15:
        pop  af
        ex   de, hl
        ret

UnpackMegalz_16:
        add  a
        call z, UnpackMegalz_20
        jp   c, UnpackMegalz_17
        add  hl, hl
        ret  c
        jp UnpackMegalz_16
UnpackMegalz_17:
        add  hl, hl
        inc  l
        ret  c
        jp   UnpackMegalz_16

UnpackMegalz_18:
        add  a
        call z, UnpackMegalz_20
        jp   c, UnpackMegalz_19
        ld   (UnpackMegalz_5 + 1), a
        ld   a, (de)
        inc  de
        ld   l, a
        ld   h, 255
        ret

UnpackMegalz_19:
        ld   hl, 8191
        call UnpackMegalz_16
        ld   (UnpackMegalz_5 + 1), a
        ld   h, l
        dec  h
        ld   a, (de)
        inc  de
        ld   l, a
        ret

UnpackMegalz_20:
        ld   a, (de)
        inc  de
        rla
    }
}
