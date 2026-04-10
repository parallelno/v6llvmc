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
#include <c8080/unpackmegalz.h>
#include <c8080/colors.h>
#include <string.h>

static void __global DrawScreenInt(const void *tempBuffer) {
    asm {
__a_1_drawscreenint=0
        ld   (DrawScreenInt_tempBuffer), hl
        ld   e, 0
DrawScreenInt_1:
        ld   a, e
        add  a
        add  a
        add  e
        inc  a
        ld   e, a
DrawScreenInt_tempBuffer=$+1
        ld   hl, 0
        ld   d, 0
        add  hl, de
        ld   d, 90h ; Screen address
        ld   c, 48 ; Screen width
DrawScreenInt_2:
        ld   a, (hl)
        inc  h
        ld   (0F802h), a ; Color port
        ld   a, (de)
        ld   (de), a
        inc  d
        dec  c
        jp   nz,  DrawScreenInt_2
        dec  e
        inc  e
        jp   nz,  DrawScreenInt_1
    }
}

void DrawScreenBuffer(void *tempBuffer, const void *image) {
    memset(tempBuffer, COLOR_INK_BLACK, SCREEN_SIZE);
    DrawScreenInt(tempBuffer);
    image = UnpackMegalz(SCREEN, image);
    UnpackMegalz(tempBuffer, image);
    DrawScreenInt(tempBuffer);
}

void DrawScreen(const void *image) {
    uint8_t tempBuffer[DRAW_SCREEN_TEMP_BUFFER_SIZE];
    DrawScreenBuffer(tempBuffer, image);
}
