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

#include <stdio.h>
#include "__printf.h"

int vsnprintf(char *buffer, size_t buffer_size, const char *format, va_list va) {
    __printf_out_pointer = buffer;
    size_t s = buffer_size;
    if (s > 0)
        s--;
    __printf_out_end = buffer + s;
    __printf(format, va);
    if (buffer_size != 0)
        *__printf_out_pointer = '\0';
    return __printf_out_total;
}

int vsprintf(char *buffer, const char *format, va_list va) {
    return vsnprintf(buffer, SIZE_MAX, format, va);
}

int snprintf(char *buffer, size_t buffer_size, const char *format, ...) {
    va_list va;
    va_start(va, format);
    return vsnprintf(buffer, buffer_size, format, va);
}

int sprintf(char *buffer, const char *format, ...) {
    va_list va;
    va_start(va, format);
    return vsnprintf(buffer, SIZE_MAX, format, va);
}
