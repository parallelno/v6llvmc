// c8080 stdlib
// Copyright (c) 2025 Aleksey Morozov aleksey.f.morozov@gmail.com aleksey.f.morozov@yandex.ru
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#include <c8080/hal.h>

void __global ChangeTileColor(void *tile, uint8_t color, uint8_t width, uint8_t height) {
    asm {
__a_4_changetilecolor=0
        ld   c, a ; height
__a_1_changetilecolor=$+1
        ld   hl, 0 ; tile
        ld   a, h
        sub  8
        ld   h, a
__a_2_changetilecolor=$+1
        ld   a, 0 ; color
changetilecolor_1:
__a_3_changetilecolor=$+1
        ld   b, 0 ; width
        ld   de, hl
changetilecolor_2:
        ld   (de), a
        inc  de
        dec  b
        jp   nz, changetilecolor_2
        ld   de, 64
        add  hl, de
        dec  c
        jp   nz, changetilecolor_1
    }
}
