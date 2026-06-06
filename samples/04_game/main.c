// V6C Game: a simple game demo showcasing
//
// Build:
//   samples\04_game\build.bat
// Build .s output with annotations:
//   clang -target i8080-unknown-v6c -O2 main.c -S -o main.s -g -mllvm -mv6c-annotate-pseudos
//
// Expected output:

#include <stdint.h>
#include <string.h>
#include <stdlib.h>
#include <v6c.h>
#include <v6c_interrupt.h>
#include <v6c_consts.h>
#include <v6c_draw.h>
#include <v6c_math.h>

static uint8_t palette[16] = {
    0x00, 0x11, 0x22, 0x33,
    0x44, 0x55, 0x66, 0x77,
    0x88, 0x99, 0xAA, 0xBB,
    0xCC, 0xDD, 0xEE, 0xFF
};

#define LINES 100

void main() {
    // Set an empty interrupt handler to avoid issues with enabled iterrupts and
    // no handler.
    v6c_set_interrupt_handler(v6c_interrupt_handler);
    // Enable interrupts so the palette update can work, because it expects
    // interrupts to be enabled to function correctly.
    v6c_ei();
    // Set the palette to a gradient to better visualize the lines and circles.
    v6c_set_palette(palette + PALETTE_LEN - 1, true);

    // Clear all 4 planes of the screen buffer.
    memset(SCR_BUFF0_PTR, 0x00, SCR_BUFF_LEN * 4);

    // #define TEXT_X 64
    // #define TEXT_Y 240
    // #define TEXT_DY 12
    //draw_text("WOW", TEXT_X, TEXT_Y, SCR_BUFF2_ADDR_H);
}