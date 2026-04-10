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

#include <stdint.h>
#include <stdbool.h>

#include <c8080/codepage/866.h>

static uint8_t *const SCREEN = (uint8_t *)0x9000;
static const uint16_t SCREEN_SIZE = 0x3000;
static const uint16_t SCREEN_BPL = 0x100;
static const uint16_t TILE_WIDTH = 48;
static const uint16_t TILE_HEIGHT = 256;
static const uint16_t SCREEN_WIDTH = 384;
static const uint16_t SCREEN_HEIGHT = 256;
static const uint16_t DRAW_SCREEN_TEMP_BUFFER_SIZE = SCREEN_SIZE;

#define TILE(X, Y) (SCREEN + (Y) + (X)*SCREEN_BPL)

#define SET_COLOR(C)                   \
    do {                               \
        *(uint8_t *)0xFFFE = (C)&0xD0; \
    } while (0)

void __global DrawImageTileMono(void *tile, const void *image, uint16_t width_height)
    __link("c8080/hal_h/drawimagetilemono.c");
uint8_t ScanKey(void) __link("c8080/hal_h/scankey.c");
bool IsShiftPressed(void) __link("c8080/hal_h/scankey.c");
uint8_t DecodeReadKey(uint8_t n) __link("c8080/hal_h/decodekey.c");
uint8_t DecodeInKey(uint8_t n) __link("c8080/hal_h/decodekey.c");
uint8_t ReadKey(void) __link("c8080/hal_h/readkey.c");
uint8_t InKey(void) __link("c8080/hal_h/inkey.c");
void DrawTextXor(void) __link("c8080/hal_h/drawtext.c");
void DrawTextInverse(void) __link("c8080/hal_h/drawtext.c");
void DrawTextNormal(void) __link("c8080/hal_h/drawtext.c");

#define DRAWTEXTARGS(X, Y) (SCREEN + (Y) + ((X) >> 2) * SCREEN_BPL), (X)&3
