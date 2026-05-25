#ifndef DRAW_H
#define DRAW_H

#include <stdint.h>
#include <stdbool.h>
#include <stdlib.h>
#include <v6c_rt_macros.h>
#include "v6c_consts.h"


V6C_NOINLINE
void draw_pixel_old(uint8_t x, uint8_t y, uint8_t* plane_addr)
{
    uint8_t addr_hi = x / 8;
    uint16_t byte_index = (addr_hi<<8) + y;
    uint8_t bit_index = 7 - (x % 8);
    plane_addr[byte_index] |= 1 << bit_index;
}

V6C_NOINLINE
void draw_line_old(uint8_t x0, uint8_t y0, uint8_t x1, uint8_t y1, uint8_t* plane_addr)
{
    // Bresenham's line algorithm
    int dx = abs(x1 - x0);
    int dy = -abs(y1 - y0);
    int sx = x0 < x1 ? 1 : -1;
    int sy = y0 < y1 ? 1 : -1;
    int err = dx + dy;
    while (true) {
        draw_pixel_old(x0, y0, plane_addr);
        if (x0 == x1 && y0 == y1) break;
        int err2 = 2 * err;
        if (err2 >= dy) {
            err += dy;
            x0 += sx;
        }
        if (err2 <= dx) {
            err += dx;
            y0 += sy;
        }
    }
}

#endif /* DRAW_H */
