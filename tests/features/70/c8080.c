/* O88: MVI-through-MOV collapse — c8080 reference
 * c8080 is a simple Z80/8080 C compiler that generates straightforward code
 * without the BUILD_PAIR indirection. Its output is the baseline to compare
 * cycle counts against.
 *
 * NOTE: c8080 uses 'int' as 16-bit and 'char' as 8-bit.
 *       Unsigned char promotion is implicit.
 */
typedef unsigned char u8;
typedef unsigned int  u16;
typedef signed char   s8;

s8 sin_lut[256];

s8 lookup_zext(u8 angle) {
    return sin_lut[angle];
}

u16 zext_add(u8 a, u16 b) {
    return (u16)a + b;
}

int main(int argc, char **argv) {
    volatile s8  r1 = lookup_zext(42);
    volatile u16 r2 = zext_add(10, 100);
    return 0;
}
