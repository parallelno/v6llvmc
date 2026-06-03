// V6C Demo: draws lines from center to random points.
// This demo shows how to use the draw_line() builtin to draw lines on the
// screen, and how to use the rand() builtin to generate random numbers.
//
// Build:
//   samples\03_demo\build.bat
// Build .s Output with annotations:
//   clang -target i8080-unknown-v6c -O2 main.c -S -o main.s -g -mllvm -mv6c-annotate-pseudos
//
// Run in the emulator:
//   v6emul --rom main.rom --load-addr 0x0100 --halt-exit
//
// Expected output: animation of lines drawn from (127, 127) to random points

#include <stdint.h>
#include <string.h>
#include <stdlib.h>
#include <v6c.h>
#include <v6c_inter.h>
#include <v6c_consts.h>
#include <v6c_draw.h>
#include <v6c_math.h>

#include "include/font.h"

#define DRAW_NEW

static uint8_t palette[16] = {
    0x00, 0x11, 0x22, 0x33,
    0x44, 0x55, 0x66, 0x77,
    0x88, 0x99, 0xAA, 0xBB,
    0xCC, 0xDD, 0xEE, 0xFF
};

#define LINES 100

void main() {
    v6c_set_empty_interrupt();
    v6c_ei();
    // clean up the screen.
    v6c_set_palette(palette + PALETTE_LEN - 1);

    // memset(SCR_BUFF0_PTR, 0x00, SCR_BUFF_LEN * 4);
    // // fill_rect(8, 50, 16, 156);
    // // draw_text("HELLO WORLD", 10, 10);

    // // Draw 100 lines from the center of the screen to random points.
    // for (int i = 0; i < LINES; i++) {
    //     uint16_t r1 = rand();
    //     uint8_t x1 = r1 & 0xFF;
    //     uint8_t y1 = (r1 >> 8);
    // #ifdef DRAW_NEW
    //     draw_line(SCR_BUFF0_ADDR_H, 127, 127, x1, y1);
    // #else
    //     draw_line_old(127, 127, x1, y1, SCR_ADDR_PTR);
    // #endif
    // }

    // // Draw 10 circles at 127, 127 from 100 radius, each smaller by 10.
    // for (int i = 0; i < 10; i++) {
    //     draw_circle(127, 127, 100 - i * 10, SCR_BUFF1_ADDR_H);
    // }

    // // Draw a sin wave across the screen across all 4 planes to test palette and different scr_addr_hi.
    // for (uint8_t i = 0; i <= 10; i++) {
    //     for (int x = 0; x < 256; x++) {
    //         uint8_t y = 127 + sin8(x + i) / 4 + i;
    //         draw_pixel(x, y, SCR_BUFF0_ADDR_H + ((i & 3) << 5));
    //     }
    // }

    // Draw rectangles to test fill_rect.
    // for (int i = 0; i < 3; i++) {
    //     fill_rect(40 - i * 4, 60 - i * 8, 200 - i * 8, 32, SCR_BUFF0_ADDR_H + ((i & 3) << 5));
    // }
    // test reqtangle
    fill_rect(129, 128, 32, 32, SCR_BUFF0_ADDR_H);
}