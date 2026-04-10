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

#include <c8080/tolowercase.h>

void __global ToLowerCase(char *text) {
    asm {
__a_1_tolowercase = 0
        dec  hl
ToLowerCase_1:
        inc  hl
        ld   a, (hl)
        or   a
        ret  z
        cp   'A'
        jp   c, ToLowerCase_1
        cp   'Z' + 1
        jp   c, ToLowerCase_2
        cp   0x60 ; А
        jp   c, ToLowerCase_1
        cp   0x7F ; Я
        jp   nc, ToLowerCase_1
ToLowerCase_2:
        add  0x80
        ld   (hl), a
        jp   ToLowerCase_1

        ; TODO: Ъ ъ
    }
}
