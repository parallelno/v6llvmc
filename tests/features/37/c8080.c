// c8080 reference for Stage 4 test — plain C (no __attribute__).

unsigned char op_acc;

unsigned char op1(unsigned char x) { op_acc ^= x; return (unsigned char)(x + 1); }
unsigned char op2(unsigned char x) { op_acc ^= x; return (unsigned char)(x + 2); }
void use2(unsigned char a, unsigned char b) { op_acc ^= a; op_acc ^= b; }

unsigned char a_spill_r8_reload(unsigned char x, unsigned char y) {
    unsigned char a = op1(x);
    unsigned char b = op2(y);
    return a + b;
}

unsigned char k2_i8(unsigned char x, unsigned char y, unsigned char z) {
    unsigned char a = op1(x);
    unsigned char b = op2(y);
    unsigned char s1 = (unsigned char)(a + b);
    unsigned char c = op2(z);
    return (unsigned char)(s1 + a + c);
}

unsigned char multi_src_i8(unsigned char x, unsigned char y, unsigned char c) {
    unsigned char a;
    if (c) a = op1(x);
    else   a = op2(x);
    unsigned char b = op2(y);
    return a + b;
}

unsigned int g_u16;
unsigned char g_u8;

void mixed_widths(unsigned int x16, unsigned char x8) {
    unsigned int a16 = (unsigned int)op1((unsigned char)x16) + x16;
    unsigned char a8  = op2(x8);
    unsigned int b16 = (unsigned int)op2((unsigned char)x16);
    unsigned char b8  = op1(x8);
    g_u16 = a16 + b16;
    g_u8  = (unsigned char)(a8 + b8);
}

int main(int argc, char **argv) {
    use2(a_spill_r8_reload(0x11, 0x22), k2_i8(0x33, 0x44, 0x55));
    use2(multi_src_i8(0x66, 0x77, 1), 0);
    mixed_widths(0xabcd, 0xef);
    return 0;
}
