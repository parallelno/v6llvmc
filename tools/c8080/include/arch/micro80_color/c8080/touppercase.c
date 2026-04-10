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

#include <c8080/touppercase.h>

void __global ToUpperCase(char *text) {
    asm {
__a_1_touppercase = 0
        dec  hl
ToUpperCase_1:
        inc  hl
        ld   a, (hl)
        or   a
        ret  z
        cp   'A' + 0x80
        jp   c, ToUpperCase_1
        cp   'Z' + 0x80 + 1
        jp   c, ToUpperCase_2
        cp   0x60 + 0x80 ; А
        jp   c, ToUpperCase_1
        cp   0x7F + 0x80 ; Я
        jp   nc, ToUpperCase_1
ToUpperCase_2:
        sub  0x80
        ld   (hl), a
        jp   ToUpperCase_1

        ; TODO: Ъ ъ
    }
}
