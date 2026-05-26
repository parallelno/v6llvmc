// c8080 reference for O81 — SELECT_CC i8 through accumulator.
// Compiled with: tools\c8080\c8080.exe tests\features\66\c8080.c -a tests\features\66\c8080.asm
//
// c8080 compiles each conditional select explicitly, so its output
// provides a hand-crafted reference for the optimal instruction sequence.

void fillscreen(void) {
    unsigned char *src = (unsigned char *)0xF800;
    unsigned char *dst = (unsigned char *)0x7802;
    unsigned char y, x;
    for (y = 0; y < 25; y++) {
        for (x = 0; x < 64; x++) {
            unsigned char b = *src++;
            *dst++ = (b & 4) ? 0x4F : 0x00;
        }
        dst += 15;
    }
}

void fillscreen_nonzero(void) {
    unsigned char *src = (unsigned char *)0xF800;
    unsigned char *dst = (unsigned char *)0x7802;
    unsigned char y, x;
    for (y = 0; y < 25; y++) {
        for (x = 0; x < 64; x++) {
            unsigned char b = *src++;
            *dst++ = (b & 4) ? 0xFE : 0x01;
        }
        dst += 15;
    }
}

int main(int argc, char **argv) {
    fillscreen();
    fillscreen_nonzero();
    return 0;
}
