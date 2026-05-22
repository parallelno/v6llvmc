#ifndef DRAW_H
#define DRAW_H

#include <stdint.h>
#include <stdbool.h>
#include <stdlib.h>
#include <v6c_rt_macros.h>

#include "memory.h"

// bit mask for each bit position in a byte
const uint8_t BIT_MASK[8] = {0x80, 0x40, 0x20, 0x10, 0x08, 0x04, 0x02, 0x01};

__attribute__((noinline)) static
void draw_pixel(uint8_t x, uint8_t y, uint8_t* plane_addr)
{
    register uint8_t addr_x_reg asm("A") = x;
    register uint8_t addr_y_reg asm("L") = y;
    register uint8_t addr_reg asm("H") = (((uint16_t)plane_addr) >> 8);
    asm (
    //     "MOV B, A          \n\t"
    //     "RRC               \n\t"
    //     "RRC               \n\t"
    //     "RRC               \n\t"
    //     "ANI 0x1F          \n\t" // a is byte offset within the plane (0-31)
    //     "ADD H             \n\t"
    //     "MOV H, A          \n\t"
    //     "MVI A, 0x07       \n\t"
    //     "ANA B             \n\t" // a is bit offset within the byte (0-7)
    //     "MOV B, A          \n\t"
    //     "MVI A, 0x80       \n\t"
    // "1:                    \n\t"
    //     "RRC               \n\t"
    //     "DCR B             \n\t"
    //     "JNZ 1b            \n\t"
    //     "ORA M             \n\t"
    //     "MOV M, A          \n\t"


        "MOV C, A          \n\t"
        "RRC               \n\t"
        "RRC               \n\t"
        "RRC               \n\t"
        "ANI 0x1F          \n\t" // a is byte offset within the plane (0-31)
        "ADD H             \n\t"
        "MOV H, A          \n\t"
        "MVI A, 0x07       \n\t"
        "ANA C             \n\t" // a is bit offset within the byte (0-7)
        "ADI LOW[BIT_MASK]   \n\t"
        "MOV C, A          \n\t"
        "ACI HIGH[BIT_MASK]   \n\t"
        "SUB C             \n\t"
        "MOV B, A          \n\t"
        "LDAX B            \n\t"
        "ORA M             \n\t"
        "MOV M, A          \n\t"


        : /* no outputs */
        : "r" (addr_reg), "r" (addr_x_reg), "r" (addr_y_reg) /* input constraints */
        : "A", "BC", "FLAGS"
    );
    // uint8_t addr_hi = x / 8;
    // uint16_t byte_index = (addr_hi<<8) + y;
    // uint8_t bit_index = 7 - (x % 8);
    // plane_addr[byte_index] |= 1 << bit_index;
}

V6C_NOINLINE
void draw_line(uint8_t x0, uint8_t y0, uint8_t x1, uint8_t y1, uint8_t* plane_addr)
{
    // Bresenham's line algorithm
    int dx = abs(x1 - x0);
    int dy = -abs(y1 - y0);
    int sx = x0 < x1 ? 1 : -1;
    int sy = y0 < y1 ? 1 : -1;
    int err = dx + dy;
    while (true) {
        draw_pixel(x0, y0, plane_addr);
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
