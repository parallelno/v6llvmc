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

#include <stdlib.h>

static uint16_t __rand_seed = 1;

int rand(void) {
    __rand_seed ^= (__rand_seed << 13);
    __rand_seed ^= (__rand_seed >> 9);
    __rand_seed ^= (__rand_seed << 7);
    return (int)__rand_seed;
}

void srand(unsigned seed) {
    __rand_seed = (uint16_t)seed;
}
