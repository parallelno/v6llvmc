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

int8_t __global memcmp(const void *, const void *, size_t size) {
    asm {
__a_3_memcmp=0
        ex   hl, de           ; de = size
__a_1_memcmp=$+1
        ld   bc, 0            ; bc = buffer1
__a_2_memcmp=$+1
        ld   hl, 0            ; hl = buffer2
        inc  d                ; Enter loop
        xor  a
        or   e
        jp   z, memcmp_2
memcmp_1:
        ld   a, (bc)          ; if (buffer1[i] != buffer2[i]) goto memcmp_3
        cp   (hl)
        jp   nz, memcmp_3
        inc  hl
        inc  bc
        dec  e                ; End loop
        jp   nz, memcmp_1
memcmp_2:
        dec  d
        jp   nz, memcmp_1
        xor  a                ; return 0;
        ret

memcmp_3:
        sbc  a                ; return buffer1[i] < buffer2[i] ? -1 : 1;
        ret  c
        inc  a
    }
}
