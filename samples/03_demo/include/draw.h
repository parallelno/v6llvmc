#ifndef DRAW_H
#define DRAW_H

#include <stdint.h>
#include <stdbool.h>
#include <stdlib.h>
#include <v6c_rt_macros.h>
#include "v6c_consts.h"


// bit mask for each bit position in a byte
static const uint8_t BIT_MASK[8] = {
    0x80, 0x40, 0x20, 0x10, 0x08, 0x04, 0x02, 0x01};

V6C_NOINLINE_ASM
void draw_pixel2(uint8_t x, uint8_t y, uint8_t* plane_addr)
{
    register uint8_t addr_x_reg asm("A") = x;
    register uint8_t addr_y_reg asm("L") = y;
    register uint8_t addr_reg asm("H") = (((uint16_t)plane_addr) >> 8);
    asm (
        "MOV C, A          \n"
        "RRC               \n"
        "RRC               \n"
        "RRC               \n"
        "ANI 0x1F          \n" // a is byte offset within the plane (0-31)
        "ADD H             \n"
        "MOV H, A          \n"
        "MVI A, 0x07       \n"
        "ANA C             \n" // a is bit offset within the byte (0-7)
        "LXI B, %[B_MASK]  \n"
        "ADD C             \n"
        "MOV C, A          \n"
        "ADC B             \n"
        "SUB C             \n"
        "MOV B, A          \n"
        "LDAX B            \n"
        "ORA M             \n"
        "MOV M, A          \n"
        : /* no outputs */
         /* input constraints */
        : "r" (addr_reg), "r" (addr_x_reg), "r" (addr_y_reg), [B_MASK] "i" (BIT_MASK)
        : "A", "BC", "FLAGS" /* clobbered registers */
    );
}

V6C_NOINLINE_ASM
void draw_line2(uint8_t scr_addr_h, uint8_t x0, uint8_t y0, uint8_t x1, uint8_t y1)
{
    register uint8_t _scr_addr_h asm("A") = scr_addr_h;
    register uint8_t _x0 asm("B") = x0;
    register uint8_t _y0 asm("C") = y0;
    register uint8_t _x1 asm("D") = x1;
    register uint8_t _y1 asm("E") = y1;

    asm(
        // A = scr_addr_h
        // B = x0
        // C = y0
        // D = x1
        // E = y1
        "STA .ADDR_H+1          \n"

        // calc+check x slop
        "MOV A, D               \n"
        "SUB B                  \n"
        //"JC .REVERS_X           \n" // if x0 >= x1, jump to .REVERS_X
        "JC .L1 \n"
        "STA .DX+1              \n" // .DX+1 = dx
    ".STRAIGHT_X:"

        // calc+check y slop
        "MOV A, E               \n" // A = y1
        "SUB C                  \n" // compare y0 with y1
        "JC .ADV_Y_NEG          \n" // if y0 >= y1, jump to .ADV_Y_NEG

    // --- x0 < x1, and y0 < y1 ---
    ".ADV_Y_POS:"
        "STA .DY+1              \n" // .DY+1 = dy
        // set up Y advance instruction (INR L)
        "MVI A, %[inr_l]        \n"
        "STA .ADV_Y             \n"
        "JMP .GET_BIT_MASK      \n"
    // --- x0 < x1, and y0 >= y1 ---
    ".ADV_Y_NEG:"
        "CMA                    \n" // dy = -dy
        "INR A                  \n" // dy++
        "STA .DY+1              \n" // .DY+1 = dy
        // set up Y advance instruction (DCR L)
        "MVI A, %[dcr_l]        \n"
        "STA .ADV_Y             \n"

    ".GET_BIT_MASK:"
        // --- slop left-bottom to right-top ---

        // B = x0
        // C = y0

        // calc the bit mask for the current pixel
        "LXI H, BIT_MASK   \n"
        "MVI A, 0x07       \n"
        "ANA B             \n" // A = bit offset within the byte (0-7)
        "MOV E, A          \n"
        "MVI D, 0          \n"
        "DAD D             \n"
        "MOV A, M          \n"
        "STA .BIT_MASK+1   \n"

        // calc the byte address for the current pixel
        "MVI A, 0xF8       \n"
        "ANA B             \n" // A = byte offset within the scr buff (0-31)
        "RRC               \n"
        "RRC               \n"
        "RRC               \n"
    ".ADDR_H:"
        "ADI 0x80          \n" // scr_addr_hi, self-modified code
        "MOV H, A          \n"
        "MOV L, C          \n" // L = y0
        // HL = byte address of the current pixel

    ".DX:"
        "MVI A, 0          \n" // A = dx, self-modified code
        "MOV E, A          \n"
        "INR E             \n" // E = dx + 1 (loop counter)
        "MOV B, A          \n" // B = dx
        "RRC               \n"
        "MOV C, A          \n" // C = err

    ".BIT_MASK:"
        "MVI D, 0          \n" // bit mask. self-modified code
        // HL = byte address of the current pixel
        // C = err
        // B = dx
        // E = loop counter
        // D = bit mask

        // --- loop ---
    ".LOOP:"
        // set pixel
        "MOV A, M          \n"
        "ORA D             \n" // set the current pixel
        "MOV M, A          \n"

        // shift bit mask right for the next pixel
        "MOV A, D          \n" // A = bit mask
        "RRC               \n" // shift bit mask right for the next pixel
        "MOV D, A          \n" // save updated bit mask
        // advance x
        "JNC .NO_ADV_X     \n"
        // if bit mask didn't cross byte boundary, skip addr_x increment
        "INR H             \n" // addr_x++
    ".NO_ADV_X:"

        // err -= dy
        "MOV A, C          \n" // A = err
    ".DY:"
        "SUI 0             \n" // A = err - dy, self-modified code
        // advance y if err < 0
        "JNC .NO_ADV_Y     \n"
        "ADD B             \n" // A = err + dx
    ".ADV_Y:"
        "INR L              \n" // y++, self-modified code
    ".NO_ADV_Y:"
        "MOV C, A           \n" // C = err
        "DCR E              \n" // loop counter--
        "JNZ .LOOP          \n" // if loop counter != 0, repeat

        ".L1:"
        // TODO: implement the line drawing algorithm in assembly.
        "RET                \n"

    ".REVERS_X:"
        // A = -dx
        "CMA                    \n" // dx = -dx
        "INR A                  \n" // dx++
        "STA .DX+1              \n" // .DX+1 = dx
        // swap (x0, y0) with (x1, y1)
        // B = x0
        // C = y0
        // D = x1
        // E = y1
        "XCHG               \n"
        "MOV D, B           \n"
        "MOV E, C           \n"
        "MOV B, H           \n"
        "MOV C, L           \n"
        // jump to the common code for the rest of the algorithm
        "JMP .STRAIGHT_X   \n"


        : /* no outputs */
        /* input constraints */
        : "r" (_scr_addr_h), "r" (_x0), "r" (_y0), "r" (_x1), "r" (_y1),
          [inr_l] "i" (OPCODE_INR_L), [dcr_l] "i" (OPCODE_DCR_L)
        /* clobbered regs */
        : "A", "BC", "DE", "HL", "FLAGS"
    );

}

V6C_NOINLINE
void draw_pixel(uint8_t x, uint8_t y, uint8_t* plane_addr)
{
    uint8_t addr_hi = x / 8;
    uint16_t byte_index = (addr_hi<<8) + y;
    uint8_t bit_index = 7 - (x % 8);
    plane_addr[byte_index] |= 1 << bit_index;
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
