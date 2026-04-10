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

#include <c8080/getunusedram.h>

size_t GetUnusedRam(void **out_heap_begin, size_t stack_size) {
    asm {
__a_2_getunusedram = 0
        ex   hl, de

        ld   hl, (__a_1_getunusedram)
        ld   (hl), __end & 0xFF
        inc  hl
        ld   (hl), __end >> 8

        ld   hl, -__end
        add  hl, sp
        ld   bc, hl

        ld   a, c
        sub  e
        ld   l, a
        ld   a, b
        sbc  d
        ld   h, a
    }
}
