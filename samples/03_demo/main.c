/*
This is a demo project to stress out the V6C backend with various code patterns,
to help identify and fix bugs and performance issues. It is not intended to be a
real application or library, and deliberately uses some bad practices (global
variables, etc.) to generate more interesting codegen patterns. The main goal is
to prove that the V6C backend can handle a variety of challenging code patterns.
*/
#include <stdint.h>
#include <string.h>
#include <stdlib.h>
#include <v6c.h>

#include "include/font.h"
#include "include/draw.h"
#include "include/rnd.h"
#include "include/interruption.h"
#include "include/memory.h"


#define SCREEN0_ADDR (void*)0x8000
#define SCREEN0_LEN  0x2000

uint8_t palette[16] = {
    0x00, 0x11, 0x22, 0x33,
    0x44, 0x55, 0x66, 0x77,
    0x88, 0x99, 0xAA, 0xBB,
    0xCC, 0xDD, 0xEE, 0xFF
};

void main() {

    // __v6c_ei();
    // reset_int();
    //palette_init(palette);

    //fill_screen();
    //fill_rect(8, 50, 16, 156);
    //draw_text("HELLO WORLD", 10, 10);


    // clean up the screen.
    //memset(SCREEN0_ADDR, 0x00, SCREEN0_LEN);

        uint16_t r = rnd();
        uint16_t r = rnd();
        uint8_t hi = r >> 8;
        uint8_t lo = r & 0xFF;
        uint8_t x = min(hi, 250) + 3; // [3, 253]
        uint8_t y = min(lo, 250) + 3; // [3, 253]
        draw_line(127, 127, x, y, SCREEN0_ADDR);

    // draw 100 random lines.
    // for (int i = 0; i < 100; i++) {
    //     uint16_t r = rnd();
    //     uint8_t hi = r >> 8;
    //     uint8_t lo = r & 0xFF;
    //     uint8_t x = min(hi, 250) + 3; // [3, 253]
    //     uint8_t y = min(lo, 250) + 3; // [3, 253]
    //     draw_line(127, 127, x, y, SCREEN0_ADDR);
    // }

    __v6c_di();
    __v6c_hlt();
}