// interruption.h - interrupt handling utilities for V6C bare-metal applications.
#include <v6c_rt_macros.h>


// Sets a minimal interruption function.
V6C_RT
void reset_int() {
    __asm__ volatile (
        "mvi a, 0xC9 \n\t"
        "sta 0x38    \n\t"
    );
}



V6C_NOINLINE
void palette_init(uint8_t* palette)
{
    // PORT0_OUT_OUT = 0x88
    // PALETTE_LEN = 16
    register uint16_t hl_in asm("HL") = (uint16_t)palette;

    __asm__ volatile (
            "hlt             \n"
            "mvi a, 0x88     \n"
            "out 0           \n"
            "mvi b, 15       \n"
         "1: mov a, b        \n"
			"out 2           \n"
			"mov a, m        \n"
			"out 0x0C        \n"
			"push psw        \n"
			"pop psw         \n"
			"push psw        \n"
			"pop psw         \n"
			"dcx h           \n"
			"dcr b           \n"
			"out 0x0C        \n"
			"jp	1b           \n"
            :: "r"(hl_in) : "FLAGS"
    );
    return;
}