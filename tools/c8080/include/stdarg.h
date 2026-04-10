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

#pragma once

typedef void *va_list;

#define va_start(v, arg)            \
    do {                            \
        (v) = (void *)(&(arg) + 1); \
    } while (0)
#define va_copy(destination, source) \
    do {                             \
        (destination) = (source);    \
    } while (0)
#define va_arg(v, type) ((v) = (char *)(v) + sizeof(type), *(type *)((char *)(v) - sizeof(type)))
#define va_end(v) \
    do {          \
    } while (0)
