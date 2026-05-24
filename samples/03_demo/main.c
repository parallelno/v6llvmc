#include <stdint.h>
#include <string.h>
#include <stdlib.h>
#include <v6c.h>
#include <v6c_inter.h>
#include <v6c_consts.h>
//#include <v6c_draw.h>

#include "include/font.h"
#include "include/draw.h"

//#define DRAW_NEW


static const uint8_t palette[16] = {
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
    //v6c_set_palette(palette + PALETTE_LEN - 1);

    // memset(SCR_BUFF0_PTR, 0x00, SCR_BUFF_LEN * 4);
    // fill_rect(8, 50, 16, 156);
    // draw_text("HELLO WORLD", 10, 10);

    for (int i = 0; i < LINES; i++) {
        uint16_t r1 = rand();
        uint8_t x1 = r1 & 0xFF;
        uint8_t y1 = (r1 >> 8);
    #ifdef DRAW_NEW
        draw_line2(SCR_BUFF0_ADDR_H, 127, 127, x1, y1);
    #else
        draw_line(127, 127, x1, y1, SCR_ADDR_PTR);
    #endif
    }
}