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
        ld   c, a
__a_2_changetilecolor=$+1
	ld   a, 0
	ld   (0F802h), a
__a_1_changetilecolor=$+1
        ld   de, 0
        ld   h, d
ChangeRectColor_1:
__a_3_changetilecolor=$+1
        ld   b, 0
ChangeRectColor_2:
        ld   a, (de)
        ld   (de), a
        inc  d
        dec  b
        jp   nz, ChangeRectColor_2
        ld   d, h
        inc  e
        dec  c
        jp   nz, ChangeRectColor_1
    }
}
