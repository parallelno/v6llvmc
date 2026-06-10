// V6C Game: a simple game demo showcasing
//
// Build:
//   samples\04_game\build.bat
// Build .s output with annotations:
//   clang -target i8080-unknown-v6c -O2 main.c -S -o main.s -g -mllvm -mv6c-annotate-pseudos
//
// Expected output:

#include <stdint.h>
#include <stdbool.h>
#include <string.h>
#include <stdlib.h>
#include <v6c.h>
#include <v6c_rt_macros.h>
#include <v6c_interrupt.h>
#include <v6c_consts.h>
#include <v6c_controls_consts.h>
//#include <v6c_display.h>
#include <v6c_draw.h>
#include <v6c_math.h>

extern void v6_interruption();
V6C_NOINLINE_ASM_EXTERN
extern void v6_gc_init_song(uint8_t* ay_reg_data_ptrs, uint8_t* song_data, uint8_t ram_disk_mode);
V6C_NOINLINE_ASM_EXTERN
extern void v6_gc_start();

uint8_t v6_palette[16] = {
    0x00, 0x11, 0x22, 0x33,
    0x44, 0x55, 0x66, 0x77,
    0x88, 0x99, 0xAA, 0xBB,
    0xCC, 0xDD, 0xEE, 0xFF
};

uint8_t v6_scr_offset_y = 0;
uint8_t v6_game_updates_required = 0;
extern uint8_t v6_palette_update_request;
extern uint16_t v6_action_code;
extern uint8_t v6_gc_task_sps[];
extern uint8_t _song01_data[];
extern uint8_t _v6_gc_buffer[];
extern uint8_t song01_ay_reg_data_ptrs[];

//#define PERMANENT_SONG01_RAM_DISK_M PERMANENT_SONG01_RAM_DISK_M | RAM_DISK_M_8F
uint8_t song01_ram_disk_m = RAM_DISK_OFF_CMD;

#define LINES 100

void draw() {
    // Set the palette to a gradient to better visualize the lines and circles.
    //v6c_set_palette(palette + PALETTE_LEN - 1, true);

    // Draw 100 lines from the center of the screen to random points.
    for (int i = 0; i < LINES; i++) {
        uint16_t r1 = rand();
        uint8_t x1 = r1 & 0xFF;
        uint8_t y1 = (r1 >> 8);
        draw_line(SCR_BUFF0_ADDR_H, 127, 127, x1, y1);
    }

    // // Draw 10 circles at 127, 127 from 100 radius, each smaller by 10.
    for (int i = 0; i < 10; i++) {
        draw_circle(127, 127, 100 - i * 10, SCR_BUFF1_ADDR_H);
    }

    // Draw a sin wave across the screen across all 4 planes to test palette and different scr_addr_hi.
    for (uint8_t i = 0; i <= 10; i++) {
        for (int x = 0; x < 256; x++) {
            uint8_t y = 127 + sin8(x * 2 + i * 8) / 8 + i;
            draw_pixel(x, y, SCR_BUFF0_ADDR_H + ((i & 3) << 5));
        }
    }

    // Draw rectangles to test fill_rect.
    for (int i = 0; i < 3; i++) {
        fill_rect(40 - i * 4, 60 - i * 8, 200 - i * 8, 32, SCR_BUFF0_ADDR_H + ((i & 3) << 5));
    }
}

void main() {
    // Set an empty interrupt handler to avoid issues with enabled iterrupts and
    // no handler.
    v6c_set_interrupt_handler(v6_interruption);
    // Enable interrupts so the palette update can work, because it expects
    // interrupts to be enabled to function correctly.
    v6c_ei();

    // Init the pallete the palette update request to trigger the palette update
    // in the interrupt handler.
    v6_palette_update_request = PALETTE_UPD_REQ_YES;

    // Clear all 4 planes of the screen buffer.
    //memset(SCR_BUFF0_PTR, 0x00, SCR_BUFF_LEN * 4);

    //draw();
    v6_gc_init_song(song01_ay_reg_data_ptrs, _v6_gc_buffer, RAM_DISK_OFF_CMD);
    v6_gc_start();

    while(true){
    //     if (v6_action_code) {
    //         // output the hi8 and lo8 code into the debug port
    //         uint8_t code_hi = (v6_action_code >> 8) & 0xFF;
    //         uint8_t code_lo = v6_action_code & 0xFF;
    //         if(code_lo == CONTROL_CODE_UP){
    //             v6_scr_offset_y--;
    //         }
    //         if(code_lo == CONTROL_CODE_DOWN){
    //             v6_scr_offset_y++;
    //         }
    //     }
        v6c_hlt();
    }

    // #define TEXT_X 64
    // #define TEXT_Y 240
    // #define TEXT_DY 12
    //draw_text("WOW", TEXT_X, TEXT_Y, SCR_BUFF2_ADDR_H);
}