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

#pragma once

#include <c8080/hal.h>

#define FILLRECTARGS(X0, Y, X1, Y1)                                                                     \
    (SCREEN + (((X0) / 8) * SCREEN_BPL) + (Y)), ((X1) + 1) / 8 - (X0 / 8), (0xFF >> ((uint8_t)(X0)&7)), \
        (0xFF >> ((uint8_t)((X1) + 1) & 7)) ^ 0xFF, (Y1) - (Y) + 1

void FillRectOver(void) __link("c8080/fillrect.c");
void FillRectInverse(void) __link("c8080/fillrect.c");
void FillRectTrue(void) __link("c8080/fillrect.c");
void FillRect(uint8_t *tile, uint16_t centerSize, uint8_t leftMask, uint8_t rightMask, uint8_t height)
    __link("c8080/fillrect.c");
void FillRectXY(uint16_t x, uint8_t y, uint16_t x1, uint8_t y1) __link("c8080/fillrect.c");
