#include <stdint.h>
#include <string.h>
#include <stdlib.h>
#include <v6c.h>
#include <v6c_inter.h>
#include <v6c_consts.h>

#include "include/font.h"
#include "include/draw.h"


static const uint8_t palette[16] = {
    0x00, 0x11, 0x22, 0x33,
    0x44, 0x55, 0x66, 0x77,
    0x88, 0x99, 0xAA, 0xBB,
    0xCC, 0xDD, 0xEE, 0xFF
};

//#define NEW_DRAW
#define RAND_LINES

#ifdef RAND_LINES
#define LINES 100
#else
#define LINES 8
#endif

#define POS_X 195
static const uint8_t pos[] = {
    0xC2, 0x23,//0x58, //0xFE,
    POS_X, 0xFA,
    POS_X, 0xC8,
    POS_X, 0x8C,
    POS_X, 0x7F,
    POS_X, 0x64,
    POS_X, 0x28,
    POS_X, 0x00
};

void main() {
    // v6c_set_empty_interrupt();
    // v6c_ei();
    // // clean up the screen.
    // v6c_set_palette(palette + PALETTE_LEN - 1);

    // memset(SCR_BUFF0_PTR, 0x00, SCR_BUFF_LEN * 4);
    // fill_rect(8, 50, 16, 156);
    // draw_text("HELLO WORLD", 10, 10);

    volatile uint8_t x, y;
    // draw 100 random lines.
    for (int i = 0; i < LINES; i++) {
#ifdef RAND_LINES
        uint16_t r = rand();
        uint8_t hi = r >> 8;
        uint8_t lo = r & 0xFF;
        x = min(hi, 250) + 3; // [3, 253]
        y = min(lo, 250) + 3; // [3, 253]
#else
        x = pos[0 + i*2];
        y = pos[1 + i*2];
#endif

#ifdef NEW_DRAW
        draw_line2(SCR_BUFF0_ADDR_H, 127, 127, x, y);
#else
        draw_line(127, 127, x, y, SCR_ADDR_PTR);
#endif
    }

}