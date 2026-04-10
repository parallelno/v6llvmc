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

static const uint16_t KEY_DEBOUNCE_TIME = 128;
static const uint16_t KEY_REPEAT_RATE = 256;
static const uint16_t KEY_DELAY_RATE = 512;

static uint16_t keyDelay = 128;
static uint8_t keyCode = 0xFF;

uint8_t ReadKey(void) {
    uint8_t debounce = KEY_DEBOUNCE_TIME;
    uint8_t result;
    do {
        uint8_t prevKey = keyCode;
        for (;;) {
            keyCode = ScanKey();
            if (keyCode != 0xFF) {
                if (keyCode != prevKey) {
                    keyDelay = KEY_DELAY_RATE;
                    break;
                }
                if (keyDelay == 0) {
                    keyDelay = KEY_REPEAT_RATE;
                    break;
                }
            } else if (debounce == 0) {
                prevKey = 0xFF;
            }
            if (debounce)
                debounce--;
            if (keyDelay)
                keyDelay--;
        }
        result = DecodeReadKey(keyCode);
    } while (result == 0xFF);
    return result;
}
