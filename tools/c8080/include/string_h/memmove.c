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

#include <string.h>

void *__global memmove(void *, const void *, size_t) {
    (void)memcpy;  // Link
    asm {
__a_3_memmove=0
        ex   hl, de              ; de = size
        ld   hl, __a_2_memmove   ; if (destination > source) goto memmove_3
        ld   a, (__a_1_memmove)
        sub  (hl)
        inc  hl
        ld   a, (__a_1_memmove + 1)
        sbc  (hl)
        jp   nc, memmove_3
        ld   hl, (__a_1_memmove) ; return memcpy(destination, source, size`)
        ld   (__a_1_memcpy), hl
        ld   hl, (__a_2_memmove)
        ld   (__a_2_memcpy), hl
        ex   hl, de
        jp   memcpy

memmove_3:
        ld   hl, (__a_2_memmove) ; bc = source
        add  hl, de
        ld   c, l
        ld   b, h
        ld   hl, (__a_1_memmove) ; hl = destination
        add  hl, de
        inc  d                   ; enter loop
        xor  a
        or   e
        jp   z, memmove_2
memmove_1:
        dec  hl
        dec  bc
        ld   a, (bc)
        ld   (hl), a
        dec  e                   ; end loop
        jp   nz, memmove_1
memmove_2:
        dec  d
        jp   nz, memmove_1
    }
}
