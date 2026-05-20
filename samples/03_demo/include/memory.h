#ifndef MEMORY_H
#define MEMORY_H

#include <stdint.h>
#include <stdbool.h>

// Vector 06c memory layout

// screen layout:
// four screen planes.
// each plane is 0x2000 bytes, 256x256 pixels, 1 bit per pixel.
// each byte encodes a horizontal line of 8 pixels, with bit 0 = rightmost pixel.
// the first byte of each plane corresponds to the bottom-left 8 pixels of the screen.
// bytes grow bottom to top, then left to right.


// Screen memory in Mode 256: 4 planes of 0x2000 bytes each, at 0x8000, 0xa000,
// 0xc000, 0xe000.
// In each plane each byte encodes a horizontal line of 8 pixels, with bit 0 =
// rightmost pixel.
// The pixel color index is determined by the combination of bits across the 4 planes:
// color index = (plane3_bit << 3) | (plane2_bit << 2) | (plane1_bit << 1) | plane0_bit
#define SCR_LEN  0x2000
#define SCR0_ADDR (uint8_t*)0x8000
#define SCR1_ADDR (uint8_t*)0xa000
#define SCR2_ADDR (uint8_t*)0xc000
#define SCR3_ADDR (uint8_t*)0xe000

// The palette is an array of 16 bytes, where each byte encodes a color in RGB332 format:
// %BBGGGRRR, where R, G are the 3-bit values for red and green, and 2-bits for
// blue intensity.

// screen consts
#define SCR_WIDTH        256
#define SCR_HEIGHT       256
#define SCR_BYTES_H      SCR_HEIGHT
#define SCR_BYTES_W      (SCR_WIDTH >> 3)



#endif /* MEMORY_H */