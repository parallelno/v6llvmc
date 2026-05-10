#include <stdint.h>

// screen consts
#define SCR_ADDR         0x8000
#define SCR_WIDTH        256
#define SCR_HEIGHT       256
#define SCR_BYTES_H      SCR_HEIGHT
#define SCR_BYTES_W      (SCR_WIDTH >> 3)

#define V6C_RT static __attribute__((noinline, used))

V6C_RT void reset_int() {
    __asm__ volatile (
        "mvi a, 0xC9 \n\t"
        "sta 0x38    \n\t"
    );
}

V6C_RT void palette_init(uint8_t* palette)
{
    // PORT0_OUT_OUT = 0x88
    // PALETTE_LEN = 16
    register uint16_t hl_in asm("HL") = (uint16_t)palette;

    __asm__ volatile (
            "hlt              \n"

            "mvi	a, 0x88   \n"
            "out	0         \n"
            "mvi	b, 15     \n"
"loop:	     mov	a, b      \n"
			"out	2        \n"
			"mov a, m        \n"
			"out 0x0C        \n"
			"push psw        \n"
			"pop psw         \n"
			"push psw        \n"
			"pop psw         \n"
			"dcx h           \n"
			"dcr b           \n"
			"out 0x0C        \n"
			"jp	loop        \n"
            "RET              \n\t"
            :: "r"(hl_in) : "FLAGS"
    );
    return;
}


__attribute__((noinline)) static
void fill_screen() {
    for (uint16_t y = 0; y < SCR_HEIGHT; ++y) {
        for (uint8_t x = 0; x < SCR_BYTES_W; ++x) {
            uint8_t* scr_pos = (uint8_t*)(SCR_ADDR + (y * SCR_BYTES_W ) + x);
            *scr_pos = 0xFF; // set all pixels in this byte to on
        }
    }
}

__attribute__((noinline)) static
void fill_rect(uint8_t addr_x, uint8_t pos_y, uint8_t b, uint8_t h) {
    for (uint16_t x = addr_x; x < addr_x + b; ++x) {
        for (uint16_t y = pos_y; y < pos_y + h; ++y) {
            uint8_t* scr_pos = (uint8_t*)(SCR_ADDR + (x * SCR_BYTES_H ) + y);
            *scr_pos = 0xFF;
        }
    }
}

// Draws a rasterized text with 8x8 font. Each byte in `text` is an ASCII char,
// and the caller is responsible for ensuring that the text fits on screen at the
// given (x,y) position.
// addr_x is the horizontal byte address (0-31) where the text starts. Each byte
// corresponds to 8 pixels.
V6C_RT void draw_text(const char* text, uint8_t addr_x, uint8_t y, uint8_t* font) {
    while (char c = *text) {
        uint8_t* font_data = font + (c * 8); // each char is 8 bytes
        for (uint8_t i = 0; i < 8; ++i) {
            uint8_t line_data = font_data[i];
            uint8_t* scr_pos = (uint8_t*)(SCR_ADDR + ((addr_x + i) * SCR_BYTES_H) + y);
            *scr_pos = line_data;
        }
        ++text;
    }
}

uint8_t palette[16] = {
    0x00, 0x11, 0x22, 0x33,
    0x44, 0x55, 0x66, 0x77,
    0x88, 0x99, 0xAA, 0xBB,
    0xCC, 0xDD, 0xEE, 0xFF
};
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

void main(){

    __builtin_v6c_ei();
    reset_int();
    palette_init(palette);

    //fill_screen();
    fill_rect(8, 50, 16, 156);
    draw_text("HELLO WORLD", 10, 10, font);

    __builtin_v6c_di();
    __builtin_v6c_hlt();
}