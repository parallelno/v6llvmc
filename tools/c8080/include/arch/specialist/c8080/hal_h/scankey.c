/*
 * Keyboard driver with codepage 866 for 8-bit Computer Specialist
 * Copyright (c) 2025 Aleksey Morozov aleksey.f.morozov@gmail.com aleksey.f.morozov@yandex.ru
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */

#include <c8080/hal.h>

static uint8_t *const KEYB0 = (uint8_t *)0xF800;
static uint8_t *const KEYB1 = (uint8_t *)0xF801;
static uint8_t *const KEYB2 = (uint8_t *)0xF802;
static uint8_t *const KEYB_MODE = (uint8_t *)0xF803;

bool IsShiftPressed(void) {
    *KEYB_MODE = 0x82;
    return ~*KEYB1 & 2;
}

uint8_t ScanKey(void) {
    asm {
        ld   a, 91h
        ld   (0F803h), a
        ld   a, (80h ^ ~3) & 0xFF
        ld   c, 12 * 0
        call scankey_1
        ld   a, 4 ^ ~3
        ld   c, 12 * 1
        call scankey_1
        ld   a, 40h ^ ~3
        ld   c, 12 * 2
        call scankey_1
        ld   a, 20h ^ ~3
        ld   c, 12 * 3
        call scankey_1
        ld   a, 10h ^ ~3
        ld   c, 12 * 4
        call scankey_1
        ld   a, 8 ^ ~3
        ld   c, 12 * 5
        call scankey_1
        ld   a, 0FFh
        ret

scankey_1:
        ld   (0F801h), a
        ld   a, (0F800h)
        cpl
        ld   b, 3
        or   a
        jp   nz, scankey_2

        ld   a, (0F802h)
        cpl
        and  00Fh
        ret  z

        ld   b, -5

scankey_2:
        rla
        inc  b
        jp   nc, scankey_2

        ld   a, b
        add  c

        pop  hl
    }
}
