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

void __global DrawText(void *, uint8_t, uint8_t, const char *) {
    asm {
__a_4_drawtext=0
        ex   hl, de
__a_1_drawtext=$+1
        ld   bc, 0 ; tile
        ld   a, b
        sub  08h
        ld   h, a
        ld   l, c
drawtext_l1:
        ld   a, (de)
        inc  de
        or   a
        ret  z
        ld   (bc), a
__a_3_drawtext=$+1
        ld   (hl), 0 ; color
        inc  c
        inc  l
        jp   drawtext_l1
    }
}
