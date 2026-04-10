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

void __global Sound(uint8_t period, uint16_t count) {
    asm {
__a_2_sound=0
__a_1_sound=$+1
        ld   b, 0
        dec  b           ; Compensating for extra ticks
        dec  b           ; 10+5 + 5+5+10 + 5+5+5+10 = 60/30 = 2
        ld   a, 1
Sound1: out  (1), a      ; extra 10, a = 1
        ld   a, b        ; extra 5
Sound2: dec  a           ; 5
        jp   nz, Sound2  ; 10
        dec  hl          ; extra 5
        ld   a, b        ; extra 5
        out  (1), a      ; extra 10, a = 0
Sound3: dec  a           ; 5
        jp   nz, Sound3  ; 10
        inc  a           ; extra 5, a = 1
        ld   c, h        ; extra 5
        inc  c           ; extra 5
        jp   nz, Sound1  ; extra 10
    }
}
