// c8080 reference for O61 Stage 6 (non-A i8 spill sources) test.

extern unsigned char op1(unsigned char x);
extern unsigned char op2(unsigned char x);
extern void use2(unsigned char a, unsigned char b);
extern void use3(unsigned char a, unsigned char b, unsigned char c);
extern void use4(unsigned char a, unsigned char b, unsigned char c,
                 unsigned char d);

unsigned char three_i8(unsigned char x, unsigned char y, unsigned char z) {
    unsigned char a = op1(x);
    unsigned char b = op2(y);
    unsigned char c = op1(z);
    use3(a, b, c);
    return (unsigned char)(a + b + c);
}

unsigned char four_i8(unsigned char x, unsigned char y,
                      unsigned char z, unsigned char w) {
    unsigned char a = op1(x);
    unsigned char b = op2(y);
    unsigned char c = op1(z);
    unsigned char d = op2(w);
    use4(a, b, c, d);
    return (unsigned char)(a + b + c + d);
}

int main(int argc, char **argv) {
    use2(three_i8(0x11, 0x22, 0x33),
         four_i8(0x44, 0x55, 0x66, 0x77));
    return 0;
}
