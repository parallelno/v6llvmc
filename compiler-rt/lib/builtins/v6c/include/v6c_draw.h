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
void draw_pixel(uint8_t x, uint8_t y)
{
    register uint8_t _x asm("A") = x;
    register uint8_t _y asm("L") = y;
    asm (
        "MOV C, A           \n"
        "RRC                \n"
        "RRC                \n"
        "RRC                \n"
        "ANI 0x1F           \n" // a is byte offset within the plane (0-31)
        "ADI 0x80           \n" // TODO: make it adjustable for different scr_addr_hi, self-modified code
        "MOV H, A           \n"
        "MVI A, 0x07        \n"
        "ANA C              \n" // a is bit offset within the byte (0-7)
        "LXI B, %[B_MASK]   \n"
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
        : "r" (_x), "r" (_y),
            [B_MASK] "i" (BIT_MASK)
        /* clobbered registers */
        : "A", "BC", "HL", "FLAGS"
    );
}

V6C_NOINLINE_ASM
void draw_line(uint8_t scr_addr_h, uint8_t x0, uint8_t y0, uint8_t x1, uint8_t y1)
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

        "call .SET_LOOP_VARS    \n"

        // --- loop ---
    ".LOOP_H:"
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
        "JNZ .LOOP_H        \n" // if loop counter != 0, repeat
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
        // B = x0
        // C = y0
        // D = dy
        "call .SET_LOOP_VARS \n"

        // --- loop ---
    ".LOOP_V:"
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
        "JNZ .LOOP_V        \n" // if loop counter != 0, repeat
        "RET                \n"

    ".SET_LOOP_VARS:"
        // in: B = x0, C = y0
        // out:
        // HL = byte address of the current pixel
        // C = err
        // D = dx
        // B = loop counter
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

        // set up: err, loop counter
        // D is dx or dy depending on the slope, set up by the caller
        "MOV B, D           \n"
        "INR B              \n" // B = dx_or_dy + 1 (loop counter)
        "XRA A              \n"
        "ORA D              \n" // A = dx_or_dy, set CY = 0
        "RAR                \n" // err = dx_or_dy/2
        "MOV C, A           \n" // C = err
        "RET                \n"

        : /* no outputs */
        /* input constraints */
        : "r" (_scr_addr_h), "r" (_x0), "r" (_y0), "r" (_x1), "r" (_y1),
          [inr_l] "i" (OPCODE_INR_L), [dcr_l] "i" (OPCODE_DCR_L),
          [B_MASK] "i" (BIT_MASK)
        /* clobbered regs */
        : "A", "BC", "DE", "HL", "FLAGS"
    );
}

static inline uint8_t draw_scale_x_4_3(uint8_t value)
{
    return (value >> 1) + (value >> 2) + ((value & 0x03u) != 0);
}

/*
 * Jesko's method for drawing circles with only integer arithmetic and no multiplication/division.
 * Reference: https://en.wikipedia.org/wiki/Midpoint_circle_algorithm#cite_note-4
 * The Vector-06C display uses 4:3 pixels, so X offsets are compressed to 3/4
 * to keep the circle visually round on screen.
 * Note: this method is not perfectly accurate, and may produce slightly distorted
 * circles, especially for smaller radii.
*/
V6C_NOINLINE
void draw_circle(uint8_t cx, uint8_t cy, uint8_t r)
{
    uint8_t x = r;
    uint8_t y = 0;
    uint8_t t1 = r >> 4;   // small bias trick (Jesko-style tweak)

    while (x >= y)
    {
        uint8_t sx = draw_scale_x_4_3(x);
        uint8_t sy = draw_scale_x_4_3(y);

        // 8-way symmetry
        draw_pixel(cx + sx, cy + y);
        draw_pixel(cx - sx, cy + y);
        draw_pixel(cx + sx, cy - y);
        draw_pixel(cx - sx, cy - y);
        draw_pixel(cx + sy, cy + x);
        draw_pixel(cx - sy, cy + x);
        draw_pixel(cx + sy, cy - x);
        draw_pixel(cx - sy, cy - x);

        y++;
        t1 += y;

        int t2 = t1 - x;
        if (t2 >= 0)
        {
            t1 = t2;
            x--;
        }
    }
}

#endif /* DRAW_H */
