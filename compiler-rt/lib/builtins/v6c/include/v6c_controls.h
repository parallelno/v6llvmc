/*===---- v6c_controls.h - V6C control handling -------------------------===
 *
 * TODO: fill in
 *
 *===-----------------------------------------------------------------------===
 */

#ifndef V6C_CONTROLS_H
#define V6C_CONTROLS_H

#include <v6c_consts.h>
#include <v6c.h>
#include <v6c_controls_consts.h>
#include <v6c_rt_macros.h>

static uint8_t action_code = 0;

static
uint8_t keys_to_controls_arrows[] = {
			// bits that form an offset in this tbl: down, right, up, left. they are inversed
			// bits of data: 0,0,0,0, CONTROL_CODE_DOWN, CONTROL_CODE_UP, CONTROL_CODE_LEFT, CONTROL_CODE_RIGHT
			0b1111, // none
			0b1101,
			0b1011,
			0b1001,
			0b1110,
			0b1100,
			0b1010,
			0b1000,

			0b0111, // right + up + left
			0b0101, // right + up
			0b0011,
			0b0001,
			0b0110,
			0b0100,
			0b0010,	// right + up + down
			0b0000	// right + up + left + down
};

static
uint8_t keys_to_controls_alt_tab_space[] = {
			// bits that form an offset in this tbl: alt, tab, space. they are inversed
			// bits of data: CONTROL_CODE_FIRE1, CONTROL_CODE_FIRE2, CONTROL_CODE_KEY_SPACE, CONTROL_CODE_RETURN, 0,0,0,0
			0b11110000, // none
			0b01010000, // space
			0b11100000, // tab
			0b01000000, // tab + space
			0b10110000, // alt
			0b00010000, // alt + space
			0b10100000, // alt + tab
			0b00000000  // alt + space + tab
};

V6C_NOINLINE
void controls_keys_check(void){
	asm (
        "mvi a, %[port0_out_in]             \n"
        "out 0                              \n"
        // line 0
        "mvi a, %[key_code_row_0]           \n"
        "out 3                              \n"
        "in 2                               \n"
        "mov c, a                           \n"

		// line 7
		"mvi a, %[key_code_row_7]           \n"
		"out 3                              \n"
		"in 2                               \n"

		"ral                                \n" // extract KEY_CODE_SPACE
		"mov a, c                           \n"
		"ral                                \n" // add KEY_CODE_SPACE to the key row 0
		"ani 0b111                          \n" // bits: alt, tab, space, but inversed
        :
        : [port0_out_in] "i"(PORT0_OUT_IN),
          [key_code_row_0] "i"(KEY_CODE_ROW_0),
          [key_code_row_7] "i"(KEY_CODE_ROW_7)
    );

		HL_TO_A_PLUS_INT16(keys_to_controls_alt_tab_space);

    asm (
		"mov e, m                           \n"

		"mvi a, 0b11110000                  \n"
		"ana c                              \n"
        "RRC                                \n"
        "RRC                                \n"
        "RRC                                \n"
        "RRC                                \n"
        ::
          [keys_to_controls_arrows] "i"(keys_to_controls_arrows),
          [keys_to_controls_alt_tab_space] "i"(keys_to_controls_alt_tab_space)
    );

		HL_TO_A_PLUS_INT16(keys_to_controls_arrows);

    asm (
		"mov a, m                            \n"
		"ora e                               \n"
		"sta %[action_code]                  \n"
		"ret                                 \n"
        ::
		  [action_code] "i"(action_code),
          [keys_to_controls_arrows] "i"(keys_to_controls_arrows),
		  [keys_to_controls_alt_tab_space] "i"(keys_to_controls_alt_tab_space)
    );
}


V6C_NOINLINE
void controls_check(void){
    // asm (
    //     "jmp controls_keys_check            \n"
    // );
    controls_keys_check();
}

#undef V6C_RT
#endif /* V6C_CONTROLS_H */