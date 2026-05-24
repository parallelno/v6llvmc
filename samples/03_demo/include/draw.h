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
        "MOV C, A           \n"
        "RRC                \n"
        "RRC                \n"
        "RRC                \n"
        "ANI 0x1F           \n" // a is byte offset within the plane (0-31)
        "ADD H              \n"
        "MOV H, A           \n"
        "MVI A, 0x07        \n"
        "ANA C              \n" // a is bit offset within the byte (0-7)
        "LXI B, %[B_MASK] \n"
        "ADD C              \n"
        "MOV C, A           \n"
        "ADC B              \n"
        "SUB C              \n"
        "MOV B, A           \n"
        "LDAX B             \n"
        "ORA M              \n"
        "MOV M, A           \n"
        : /* no outputs */
        /* input constraints */
        : "r" (addr_reg), "r" (addr_x_reg), "r" (addr_y_reg),
            [B_MASK] "i" (BIT_MASK)
        /* clobbered registers */
        : "A", "BC", "FLAGS"
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

        // calc+check dx
        "MOV A, D               \n"
        "SUB B                  \n"
        "JC .SWAP_POINTS        \n" // if x0 >= x1, SWAP_POINTS
    ".SET_DX:"
        "MOV D, A               \n" // D = dx

        // calc+check dy
        "LXI H, .ADV_Y          \n"
        "MOV A, E               \n" // A = y1
        "SUB C                  \n" // compare y0 with y1
        "JC .ADV_Y_NEG          \n" // if y0 >= y1, jump to .ADV_Y_NEG

        // --- x0 < x1, and y0 < y1 ---
    ".ADV_Y_POS:"
        // set up Y advance instruction (INR L)
        "MVI M, %[inr_l]        \n"
        "JMP .CHECK_SLOP        \n"
        // --- x0 < x1, and y0 >= y1 ---
    ".ADV_Y_NEG:"
        "CMA                    \n" // dy = -dy
        "INR A                  \n" // dy++
        "MVI M, %[dcr_l]        \n"

    ".CHECK_SLOP:"
        // D = |dx|
        // A = |dy|
        // if dy > dx, call vertical line drawing routine
        "CMP D                  \n" // compare dy with dx
        "JNC .VERTICAL_DRAW     \n" // if dy > dx, jump to vertical draw routine

        // .DY+1 = dy
        "STA .DY+1              \n"

        // --- left-to-right horizontal line ---
        // B = x0
        // C = y0
        // D = dx

        "call .GET_PIXEL_ADDR_AND_MASK \n"

        // set up: err, loop counter
        "MOV B, D          \n"
        "INR B             \n" // B = dx + 1 (loop counter)
        "XRA A             \n"
        "ORA D             \n" // A = dx, set CY = 0
        "RAR               \n" // err = dx/2
        "MOV C, A          \n" // C = err

        // --- loop ---
    ".LOOP:"
        // HL = byte address of the current pixel
        // C = err
        // D = dx
        // B = loop counter
        // E = bit mask

        // set pixel
        "MOV A, M          \n"
        "ORA E             \n"
        "MOV M, A          \n"

        // shift bit mask right for the next pixel
        "ANA E              \n" // A = bit mask
        "RRC                \n" // shift bit mask right for the next pixel
        "MOV E, A           \n" // save updated bit mask
        // if bit mask didn't cross byte boundary, skip addr_x increment
        "ADC H              \n"
        "SUB E              \n"
        "MOV H, A           \n"

        // err -= dy
        "MOV A, C           \n" // A = err
    ".DY:"
        "SUI 0              \n" // A = err - dy, self-modified code
        // advance y if err < 0
        "JNC .NO_ADV_Y      \n"
        "ADD D              \n" // A = err + dx
    ".ADV_Y:"
        "INR L              \n" // y++, self-modified code

    ".NO_ADV_Y:"
        "MOV C, A           \n" // C = err
        "DCR B              \n" // loop counter--
        "JNZ .LOOP          \n" // if loop counter != 0, repeat
        "RET                \n"

    // swap (x0, y0) with (x1, y1)
    ".SWAP_POINTS:"
        // in:
        // A = -dx
        // B = x0
        // C = y0
        // D = x1
        // E = y1
        // out: A = dx, swapped (x0, y0) with (x1, y1)
        "CMA                    \n"
        "INR A                  \n" // dx = -dx
        // swap
        "XCHG               \n"
        "MOV D, B           \n"
        "MOV E, C           \n"
        "MOV B, H           \n"
        "MOV C, L           \n"
        "JMP .SET_DX        \n"

    ".VERTICAL_DRAW:"
        // D = |dx|
        // A = |dy|
        // B = x0
        // C = y0

        "LXI H, .DX2+1      \n"
        "MOV M, D           \n" // .DX2 = dx
        "MOV D, A           \n"
        // D = dy

        // set up Y advance instruction for vertical draw routine
        "LDA .ADV_Y         \n"
        "STA .ADV_Y2        \n"
        // --- left-to-right vertical line ---
        "call .GET_PIXEL_ADDR_AND_MASK \n"

        // set up: err, loop counter
        "MOV B, D           \n"
        "INR B              \n" // B = dy + 1 (loop counter)
        "XRA A              \n"
        "ORA D              \n" // A = dy, set CY = 0
        "RAR                \n" // err = dy/2
        "MOV C, A           \n" // C = err

        // --- loop ---
    ".LOOP2:"
        // HL = byte address of the current pixel
        // C = err
        // D = dy
        // B = loop counter
        // E = bit mask

        // set pixel
        "MOV A, M           \n"
        "ORA E              \n"
        "MOV M, A           \n"

        // advance y
    ".ADV_Y2:"
        "INR L              \n" // y++, self-modified code

        // err -= dx
        "MOV A, C           \n" // A = err
    ".DX2:"
        "SUI 0              \n" // A = err - dx, self-modified code
        "MOV C, A           \n" // C = err
        // if err < 0, advance x
    "JNC .NO_ADV_X2         \n"
        "ADD D              \n" // A = err + dy
        "MOV C, A           \n" // C = err

        // shift bit mask right for the next pixel
        "MOV A, E           \n" // A = bit mask
        "RRC                \n" // shift bit mask right for the next pixel
        "MOV E, A           \n" // save updated bit mask
        // if bit mask didn't cross byte boundary, skip addr_x increment
        "ADC H              \n"
        "SUB E              \n"
        "MOV H, A           \n"

    ".NO_ADV_X2:"
        "DCR B              \n" // loop counter--
        "JNZ .LOOP2         \n" // if loop counter != 0, repeat
        "RET                \n"

    ".GET_PIXEL_ADDR_AND_MASK:"
        // in: B = x0, C = y0
        // out:
        // HL = byte address of the current pixel
        // E = bit mask
        // clobbers: A, B, C, E, H, L, FLAGS

        // calc the bit mask for the current pixel
        "LXI H, %[B_MASK]  \n"
        "MVI A, 0x07       \n"
        "ANA B             \n" // A = bit offset within the byte (0-7)
        "ADD L             \n"
        "MOV L, A          \n"
        "ADC H             \n"
        "SUB L             \n"
        "MOV H, A          \n"
        "MOV E, M          \n"
        // E = bit mask

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
        "RET               \n"

        : /* no outputs */
        /* input constraints */
        : "r" (_scr_addr_h), "r" (_x0), "r" (_y0), "r" (_x1), "r" (_y1),
          [inr_l] "i" (OPCODE_INR_L), [dcr_l] "i" (OPCODE_DCR_L),
          [B_MASK] "i" (BIT_MASK)
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
