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

#include <string.h>

void __global memswap(void *, void *, size_t) {
    asm {
__a_3_memswap=0
        ex   hl, de            ; de = size
__a_2_memswap=$+1
        ld   bc, 0             ; bc = buffer2
__a_1_memswap=$+1
        ld   hl, 0             ; hl = buffer1
        inc  d                 ; enter loop
        xor  a
        or   e
        ld   a, d
        jp   z, memswap_3
memswap_0:
        push af
memswap_1:
        ld   a, (bc)
        ld   d, a
        ld   a, (hl)
        ld   (bc), a
        ld   (hl), d
        inc  hl
        inc  bc
        dec  e                 ; end loop
        jp   nz, memswap_1
        pop  af
memswap_3:
        dec  a
        jp   nz, memswap_0
    }
}
