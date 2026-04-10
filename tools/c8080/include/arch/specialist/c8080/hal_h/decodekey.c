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
#include <c8080/keys.h>

static const char scanCodes[] = {
    KEY_F1,  KEY_F2,    KEY_F3, KEY_F4,   KEY_F5,  KEY_F6,  KEY_F7,    KEY_F8,        KEY_F9, KEY_F10,
    KEY_F11, KEY_F12,

    KEY_RUS, KEY_HOME,  KEY_UP, KEY_DOWN, KEY_TAB, KEY_ESC, KEY_SPACE, KEY_LEFT,      KEY_PV, KEY_RIGHT,
    KEY_PS,  KEY_ENTER,

    ';',     '1',       '2',    '3',      '4',     '5',     '6',       '7',           '8',    '9',
    '0',     '-',       'j',    'c',      'u',     'k',     'e',       'n',           'g',    '[',
    ']',     'z',       'h',    '*',      'f',     'y',     'w',       'a',           'p',    'r',
    'o',     'l',       'd',    'v',      '\\',    '.',     'q',       '^',           's',    'm',
    'i',     't',       'x',    'b',      '@',     ',',     '/',       KEY_BACKSPACE,

    '+',     '!',       '"',    '#',      '$',     '%',     '^',       '&',           '*',    '(',
    ')',     '=',       'J',    'C',      'U',     'K',     'E',       'N',           'G',    '{',
    '}',     'Z',       'H',    ':',      'F',     'Y',     'W',       'A',           'P',    'R',
    'O',     'L',       'D',    'V',      '\\',    '>',     'Q',       '^',           'S',    'M',
    'I',     'T',       'X',    'B',      '@',     '<',     '?',       KEY_BACKSPACE,

    ';',     '1',       '2',    '3',      '4',     '5',     '6',       '7',           '8',    '9',
    '0',     '-',       'й',    'ц',      'у',     'к',     'е',       'н',           'г',    'ш',
    'щ',     'з',       'х',    '*',      'ф',     'ы',     'в',       'а',           'п',    'р',
    'о',     'л',       'д',    'ж',      'э',     '.',     'я',       'ч',           'с',    'м',
    'и',     'т',       'ь',    'б',      'ю',     ',',     '/',       KEY_BACKSPACE,

    '+',     '!',       '"',    '#',      '$',     '%',     '^',       '&',           '*',    '(',
    ')',     '=',       'Й',    'Ц',      'У',     'К',     'Е',       'Н',           'Г',    'Ш',
    'Щ',     'З',       'Х',    ':',      'Ф',     'Ы',     'В',       'А',           'П',    'Р',
    'О',     'Л',       'Д',    'Ж',      'Э',     '>',     'Я',       'Ч',           'С',    'М',
    'И',     'Т',       'Ь',    'Б',      'Ю',     '<',     '?',       KEY_BACKSPACE,
};

static const uint8_t KEY_MODE_CYRILYC = 1 << 0;

static uint8_t keyMode;

uint8_t DecodeReadKey(uint8_t n) {
    if (n == 12) {
        keyMode ^= KEY_MODE_CYRILYC;
        return 0xFF;
    }

    if (n >= 24) {
        if (IsShiftPressed())
            n += 12 * 4;
        if (keyMode & KEY_MODE_CYRILYC)
            n += 12 * 8;
    }
    return scanCodes[n];
}

uint8_t DecodeInKey(uint8_t n) {
    return scanCodes[n];
}
