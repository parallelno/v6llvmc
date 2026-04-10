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

#include <c8080/hal.h>
#include <c8080/console.h>
#include <string.h>

extern uint8_t BIOS_COLOR __address(0xF759);
extern uint16_t BIOS_CURSOR __address(0xF75A);
extern uint8_t BIOS_CURSOR_VISIBLE __address(0xF75E);

void SaveScreen(struct SavedScreen *s) {
    s->color = BIOS_COLOR;
    s->cursor = BIOS_CURSOR;
    s->cursor_visible = BIOS_CURSOR_VISIBLE;
    HideCursor();
    memcpy(s->screen, SCREEN_ATTRIB, TEXT_WIDTH * TEXT_HEIGHT);
    memcpy(s->screen + TEXT_WIDTH * TEXT_HEIGHT, SCREEN, TEXT_WIDTH * TEXT_HEIGHT);
    if (s->cursor_visible)
        ShowCursor();
}
