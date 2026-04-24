// c8080 reference for O64 test.

extern unsigned char op(unsigned char x);
extern void use5(unsigned char, unsigned char, unsigned char,
                 unsigned char, unsigned char);

unsigned char many_i8(unsigned char a, unsigned char b, unsigned char c,
                      unsigned char d, unsigned char e) {
    unsigned char x1 = op(a);
    unsigned char x2 = op(b);
    unsigned char x3 = op(c);
    unsigned char x4 = op(d);
    unsigned char x5 = op(e);
    use5(x1, x2, x3, x4, x5);
    return (unsigned char)(x1 ^ x2 ^ x3 ^ x4 ^ x5);
}

int main(int argc, char **argv) {
    many_i8(0x11, 0x22, 0x33, 0x44, 0x55);
    return 0;
}
