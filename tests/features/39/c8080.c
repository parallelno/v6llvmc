// c8080 reference for O61 Stage 5 (DE/BC i16 spill sources) test.

extern unsigned int op_u16(unsigned int x);
extern unsigned int op2_u16(unsigned int x);
extern void use3_u16(unsigned int a, unsigned int b, unsigned int c);
extern void use2_u16(unsigned int a, unsigned int b);

unsigned int de_bc_three(unsigned int x, unsigned int y, unsigned int z) {
    unsigned int a = op_u16(x);
    unsigned int b = op2_u16(y);
    unsigned int c = op_u16(z);
    use3_u16(a, b, c);
    return (unsigned int)(a + b + c);
}

unsigned int de_one_reload(unsigned int x, unsigned int y) {
    unsigned int a = op_u16(x);
    unsigned int b = op2_u16(y);
    return (unsigned int)(a + b);
}

int main(int argc, char **argv) {
    use2_u16(de_bc_three(0x1111, 0x2222, 0x3333),
             de_one_reload(0x4444, 0x5555));
    return 0;
}
