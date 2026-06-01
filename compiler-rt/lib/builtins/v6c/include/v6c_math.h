/* v6c_math.h - V6C 8/16-bit integer trigonometry.
 *
 * Provides sin8() and cos8(): signed-char in / signed-char out
 * lookup-table approximations of sine and cosine.
 *
 * Angle convention
 * ----------------
 * The input angle is a signed char reinterpreted as an unsigned
 * 0-255 index covering one full circle (each unit ≈ 1.406°):
 *
 *   0   →   0°      (sin = 0)
 *   64  →  90°      (sin = +127, max)
 *   128 → 180°      (sin = 0)
 *   192 → 270°      (sin = -127, min)
 *
 * Return value
 * ------------
 * The result is scaled to the signed-char range:
 *   sin8(angle) ≈ round(127.0 * sin(2π * (uint8_t)angle / 256))
 *   cos8(angle) ≈ round(127.0 * cos(2π * (uint8_t)angle / 256))
 *
 * Maximum absolute error: < 1 LSB.
 *
 * cos8(angle) == sin8(angle + 64)   (90° phase shift)
 *
 *
 * The 256-byte alignment guarantee is critical: it ensures the low
 * byte of the table base address is always 0, so the angle byte can
 * be loaded directly into L without any address arithmetic.
 *
 * Linkage
 * -------
 * Both functions and the lookup table are static (per-TU). Unused
 * copies are pruned by the linker's --gc-sections pass.
 */

#ifndef V6C_MATH_H
#define V6C_MATH_H

#include <stdint.h>
#include <v6c_rt_macros.h>

/* ------------------------------------------------------------------
 * Sine lookup table.
 *
 * sin_lut[i] = (int8_t)round(127.0 * sin(2.0 * M_PI * i / 256.0))
 *
 * Must be 256-byte aligned so that the low byte of its address is
 * always 0x00 after LXI H, sin_lut.  This allows indexing as:
 *   LXI H, sin_lut  ; H = base_hi, L = 0x00
 *   MOV L, A        ; L = angle
 *   MOV A, M        ; A = sin_lut[angle]
 * ------------------------------------------------------------------ */
static const int8_t sin_lut[256] /*__attribute__((aligned(256)))*/ = {
    /*   0 ..  15 */   0,   3,   6,   9,  12,  16,  19,  22,  25,  28,  31,  34,  37,  40,  43,  46,
    /*  16 ..  31 */  49,  51,  54,  57,  60,  63,  65,  68,  71,  73,  76,  78,  81,  83,  85,  88,
    /*  32 ..  47 */  90,  92,  94,  96,  98, 100, 102, 104, 106, 107, 109, 110, 112, 113, 115, 116,
    /*  48 ..  63 */ 117, 118, 120, 121, 122, 122, 123, 124, 125, 125, 126, 126, 126, 127, 127, 127,
    /*  64 ..  79 */ 127, 127, 127, 127, 126, 126, 126, 125, 125, 124, 123, 122, 122, 121, 120, 118,
    /*  80 ..  95 */ 117, 116, 115, 113, 112, 110, 109, 107, 106, 104, 102, 100,  98,  96,  94,  92,
    /*  96 .. 111 */  90,  88,  85,  83,  81,  78,  76,  73,  71,  68,  65,  63,  60,  57,  54,  51,
    /* 112 .. 127 */  49,  46,  43,  40,  37,  34,  31,  28,  25,  22,  19,  16,  12,   9,   6,   3,
    /* 128 .. 143 */   0,  -3,  -6,  -9, -12, -16, -19, -22, -25, -28, -31, -34, -37, -40, -43, -46,
    /* 144 .. 159 */ -49, -51, -54, -57, -60, -63, -65, -68, -71, -73, -76, -78, -81, -83, -85, -88,
    /* 160 .. 175 */ -90, -92, -94, -96, -98,-100,-102,-104,-106,-107,-109,-110,-112,-113,-115,-116,
    /* 176 .. 191 */-117,-118,-120,-121,-122,-122,-123,-124,-125,-125,-126,-126,-126,-127,-127,-127,
    /* 192 .. 207 */-127,-127,-127,-127,-126,-126,-126,-125,-125,-124,-123,-122,-122,-121,-120,-118,
    /* 208 .. 223 */-117,-116,-115,-113,-112,-110,-109,-107,-106,-104,-102,-100, -98, -96, -94, -92,
    /* 224 .. 239 */ -90, -88, -85, -83, -81, -78, -76, -73, -71, -68, -65, -63, -60, -57, -54, -51,
    /* 240 .. 255 */ -49, -46, -43, -40, -37, -34, -31, -28, -25, -22, -19, -16, -12,  -9,  -6,  -3,
};

/* ------------------------------------------------------------------
 * sin8 — integer sine approximation.
 *
 * Input:  angle  — full-circle angle in 1/256-turn units (signed char
 *                  reinterpreted as 0-255; each unit ≈ 1.406°).
 * Output: signed char in [-127, 127] ≈ round(127 * sin(2π*angle/256)).
 * ------------------------------------------------------------------ */
V6C_NOINLINE
int8_t sin8(int8_t angle)
{
    // register int8_t _a asm("L") = angle;
    // register int8_t _r asm("A");
    // asm (
    //     "LXI H, %[tbl]  \n"   /* H = high byte of table, L = 0 (aligned) */
    //     "MOV A, M       \n"   /* A = sin_lut[angle]                       */
    //     : "=r" (_r)
    //     : "0" (_a), [tbl] "i" (sin_lut)
    //     : "HL"
    // );
    // return _r;
    return sin_lut[(uint8_t)angle];
}

/* ------------------------------------------------------------------
 * cos8 — integer cosine approximation.
 *
 * Input:  angle  — full-circle angle in 1/256-turn units (same as sin8).
 * Output: signed char in [-127, 127] ≈ round(127 * cos(2π*angle/256)).
 *
 * Implemented as sin8(angle + 64), since cos(x) = sin(x + 90°) and
 * 90° corresponds to 64 units in 1/256-turn notation.
 *
 * Assembly (7 bytes, 32 cycles):
 *   ADI  0x40        ; 2B  8cc — angle += 64 (wraps modulo 256)
 *   LXI H, sin_lut   ; 3B 12cc — load table base (L=0 by alignment)
 *   MOV L, A         ; 1B  8cc — L = angle + 64
 *   MOV A, M         ; 1B  8cc — A = sin_lut[(angle+64) & 0xFF]
 * ------------------------------------------------------------------ */
V6C_INLINE
int8_t cos8(int8_t angle)
{
    register int8_t _a asm("L") = angle;
    register int8_t _r asm("A");
    asm (
        "ADI  0x40      \n"   /* A = angle + 64 (wraps in 8 bits)         */
        "LXI H, %[tbl]  \n"   /* H = high byte of table, L = 0 (aligned)  */
        "MOV L, A       \n"   /* L = (angle + 64) & 0xFF                  */
        "MOV A, M       \n"   /* A = sin_lut[(angle+64) & 0xFF] = cos(a)  */
        : "=r" (_r)
        : "0" (_a), [tbl] "i" (sin_lut)
        : "HL"
    );
    return _r;
}

#undef V6C_NOINLINE_ASM

#endif /* V6C_MATH_H */
