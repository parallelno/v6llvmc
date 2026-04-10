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

char *__global strchr(const char *, char) {
    asm {
__a_2_strchr=0
        ; d = what
        ld   d, a
        ; hl = string
__a_1_strchr=$+1
        ld   hl, 0
        ; loop
strchr_1:
        ld   a, (hl)
        cp   d
        ret  z
        inc  hl
        or   a
        jp   nz, strchr_1
        ; return 0
        ld   h, a
        ld   l, a
    }
}
