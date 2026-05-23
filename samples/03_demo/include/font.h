#ifndef FONT_H
#define FONT_H

#include <stdint.h>
#include <v6c_rt_macros.h>
#include <v6c_consts.h>

V6C_NOINLINE
void fill_rect(uint8_t addr_x, uint8_t pos_y, uint8_t b, uint8_t h) {
    for (uint16_t x = addr_x; x < addr_x + b; ++x) {
        for (uint16_t y = pos_y; y < pos_y + h; ++y) {
            uint8_t* scr_pos = SCR_BUFF0_PTR + (x * SCR_HEIGHT) + y;
            *scr_pos = 0xFF;
        }
    }
}

uint8_t font[32 * 8] = {
    // font data for 32 chars (ASCII 0-31), each char is 8 bytes (8x8 pixels)
    // A
    0x00, 0x18, 0x24, 0x42, 0x7E, 0x42, 0x42, 0x00,
    // B
    0x00, 0x7C, 0x42, 0x7C, 0x42, 0x42, 0x7C, 0x00,
    // C
    0x00, 0x3C, 0x42, 0x40, 0x40, 0x42, 0x3C, 0x00,
    // D
    0x00, 0x78, 0x44, 0x42, 0x42, 0x44, 0x78, 0x00,
    // E
    0x00, 0x7E, 0x40, 0x7C, 0x40, 0x40, 0x7E, 0x00,
    // F
    0x00, 0x7E, 0x40, 0x7C, 0x40, 0x40, 0x40, 0x00,
    // G
    0x00, 0x3C, 0x42, 0x40, 0x4E, 0x42, 0x3C, 0x00,
    // H
    0x00, 0x42, 0x42, 0x7E, 0x42, 0x42, 0x42, 0x00,
};

// Draws a rasterized text with 8x8 font. Each byte in `text` is an ASCII char,
// and the caller is responsible for ensuring that the text fits on screen at the
// given (x,y) position.
// addr_x is the horizontal byte address (0-31) where the text starts. Each byte
// corresponds to 8 pixels.
V6C_NOINLINE
void draw_text(const char* text, uint8_t addr_x, uint8_t y) {
    char c;
    while ((c = *text)) {
        uint8_t* font_data = font + (c * 8); // each char is 8 bytes
        for (uint8_t i = 0; i < 8; ++i) {
            uint8_t line_data = font_data[i];
            uint8_t* scr_pos = SCR_BUFF0_PTR + ((addr_x + i) * SCR_HEIGHT) + y;
            *scr_pos = line_data;
        }
        ++text;
    }
}

#endif /* FONT_H */