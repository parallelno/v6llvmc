#ifndef DRAW_H
#define DRAW_H

#include <stdint.h>
#include <stdbool.h>
#include <stdlib.h>
#include <v6c_rt_macros.h>

#include "memory.h"

// bit mask for each bit position in a byte
const uint8_t BIT_MASK[8] = {0x80, 0x40, 0x20, 0x10, 0x08, 0x04, 0x02, 0x01};

V6C_NOINLINE
void draw_pixel(uint8_t x, uint8_t y, uint8_t* plane_addr)
{
    register uint8_t addr_x_reg asm("A") = x;
    register uint8_t addr_y_reg asm("L") = y;
    register uint8_t addr_reg asm("H") = (((uint16_t)plane_addr) >> 8);
    asm (
        "MOV C, A          \n\t"
        "RRC               \n\t"
        "RRC               \n\t"
        "RRC               \n\t"
        "ANI 0x1F          \n\t" // a is byte offset within the plane (0-31)
        "ADD H             \n\t"
        "MOV H, A          \n\t"
        "MVI A, 0x07       \n\t"
        "ANA C             \n\t" // a is bit offset within the byte (0-7)
        "LXI B, BIT_MASK   \n\t"
        "ADD C             \n\t"
        "MOV C, A          \n\t"
        "ADC B             \n\t"
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
//     int dx = abs(x1 - x0);
//     int dy = -abs(y1 - y0);
//     int sx = x0 < x1 ? 1 : -1;
//     int sy = y0 < y1 ? 1 : -1;
//     int err = dx + dy;
//     while (true) {
//         draw_pixel(x0, y0, plane_addr);
//         if (x0 == x1 && y0 == y1) break;
//         int err2 = 2 * err;
//         if (err2 >= dy) {
//             err += dy;
//             x0 += sx;
//         }
//         if (err2 <= dx) {
//             err += dx;
//             y0 += sy;
//         }
//     }

    // uint8_t tmp;
    // // swap points to be always left-to-right.
    // if (x0 > x1 || y0 > y1) {
    //     return;
    // }
    // uint8_t dx = x1 - x0;
    // uint8_t dy = y1 > y0 ? (y1 - y0) : (y0 - y1);
    // if (dy > dx) {
    //     return; // not supported yet
    // }

    // int8_t err = dx;
    // while(true){
    //     draw_pixel(x0, y0, plane_addr);

    //     if (x0 == x1) break;
    //     x0++;
    //     err -= dy;
    //     if (err < 0) {
    //         y0 += 1;
    //         err += dx;
    //     }
    // }
    // A = x0
    // B = y0
    // C = x1
    // D = y1
    // HL = plane_addr

    asm(
        "MOV E, A         \n\t" // E = x0
        // check x slop
        "CMP C            \n\t" // compare x0 with x1
        "JNC .L1           \n\t" // if x0 >= x1, jump to .L1
        // check the y slop
        "MOV A, B         \n\t" // A = y0
        "SUB D            \n\t" // compare y0 with y1
        "JNC .L1           \n\t" // if y0 >= y1, jump to .L1

        // --- slop left-bottom to right-top ---

        // calc and save dx, dy
        "STA .DY+1        \n\t" // save y0 in .DY+1
        "MOV A, C         \n\t" // A = x1
        "SUB E            \n\t" // A = dx
        "STA .DX+1        \n\t" // save dx in .DX+1
        // E = x0
        // B = y0
        // C = x1
        // D = y1

        // calc the bit mask for the current pixel
        "MVI A, 0x07       \n\t"
        "ANA E             \n\t" // A = bit offset within the byte (0-7)
        "LXI H, BIT_MASK   \n\t"
        "ADD L             \n\t"
        "MOV L, A          \n\t"
        "ADC H             \n\t"
        "SUB L             \n\t"
        "MOV H, A          \n\t"
        "MOV A, M          \n\t"
        "STA .BIT_MASK+1   \n\t" // save bit mask for the current pixel

        // calc the byte address for the current pixel
        "MVI A, 0xF8       \n\t"
        "ANA E             \n\t" // A = byte offset within the plane (0-31)
        "RRC               \n\t"
        "RRC               \n\t"
        "RRC               \n\t"
    ".ADDR_H:"
        "ADI 0x80          \n\t" // plane_addr_hi, self-modified code
        "MOV H, A          \n\t"
        "MOV L, B          \n\t" // L = y0
        // HL = byte address of the current pixel

    ".DX:"
        "MOV B, 0          \n\t" // B = dx, self-modified code
        "MVI C, B          \n\t" // C = err
        "MOV E, B          \n\t"
        "INR E              \n\t" // E = dx + 1 (loop counter)
    ".BIT_MASK:            \n\t"
        "MVI D, 0          \n\t" // bit mask. self-modified code
        // HL = byte address of the current pixel
        // C = err
        // B = dx
        // E = loop counter
        // D = bit mask

        // loop
    ".L0:                  \n\t"
        // set pixel
        "MOV A, M          \n\t"
        "ORA D             \n\t" // set the current pixel
        "MOV M, A          \n\t"

        // shift bit mask right for the next pixel
        "MOV A, D          \n\t" // A = bit mask
        "RRC               \n\t" // shift bit mask right for the next pixel
        "MOV D, A          \n\t" // save updated bit mask
        // advance x
        "JNC .NO_ADV_X     \n\t"
        // if bit mask didn't cross byte boundary, skip addr_x increment
        "INR H             \n\t" // addr_x++
    ".NO_ADV_X:            \n\t"

        // err -= dy
        "MOV A, C          \n\t" // A = err
    ".DY:                  \n\t"
        "SUI 0             \n\t" // A = err - dy, self-modified code
        // advance y if err < 0
        "JNC .NO_ADV_Y     \n\t"
        "INR L             \n\t" // y++
        "ADD B             \n\t" // err += dx
    ".NO_ADV_Y:            \n\t"
        "MOV C, A          \n\t" // C = err + dx
        "DCR E              \n\t" // loop counter--
        "JNZ .L0            \n\t" // if loop counter != 0, repeat


        ".L1:"
        // TODO: implement the line drawing algorithm in assembly.
        "RET"
    );

}

#endif /* DRAW_H */
