#include <stdint.h>
#include <string.h>
#include <stdlib.h>
#include <v6c.h>
#include <v6c_inter.h>
#include <v6c_consts.h>

#include "include/font.h"
#include "include/draw.h"


uint8_t palette[16] = {
    0x00, 0x11, 0x22, 0x33,
    0x44, 0x55, 0x66, 0x77,
    0x88, 0x99, 0xAA, 0xBB,
    0xCC, 0xDD, 0xEE, 0xFF
};

#define LINES 8

uint8_t pos[] = {
    255, 0xFE,
    255, 0xFA,
    255, 0xC8,
    255, 0x8C,
    255, 0x7F,
    255, 0x64,
    255, 0x28,
    255, 0x00
};

void main() {
    // v6c_set_empty_interrupt();
    // v6c_ei();
    // // clean up the screen.
    // v6c_set_palette(palette + PALETTE_LEN - 1);

    // memset(SCR_BUFF0_PTR, 0x00, SCR_BUFF_LEN * 4);
    // fill_rect(8, 50, 16, 156);
    // draw_text("HELLO WORLD", 10, 10);

    // draw 100 random lines.
    for (int i = 0; i < LINES; i++) {
        // uint16_t r = rand();
        // uint8_t hi = r >> 8;
        // uint8_t lo = r & 0xFF;
        // uint8_t x = min(hi, 250) + 3; // [3, 253]
        // uint8_t y = min(lo, 250) + 3; // [3, 253]
        //draw_line(127, 127, x, y, SCR_ADDR_PTR);
        uint8_t x = pos[0 + i*2];
        uint8_t y = pos[1 + i*2];
        //draw_line2(SCR_BUFF0_ADDR_H, 127, 127, x, y);
        draw_line(127, 127, x, y, SCR_ADDR_PTR);
    }
}