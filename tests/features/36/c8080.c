// Test case for O61 Stage 3 — c8080 reference.

unsigned int op_acc;

unsigned int op1(unsigned int x) { op_acc ^= x; return x + 1; }
unsigned int op2(unsigned int x) { op_acc ^= x; return x + 2; }

unsigned int multi_src_de(unsigned int x, unsigned int y, unsigned int c) {
    unsigned int a;
    if (c)
        a = op1(x);
    else
        a = op2(x);
    unsigned int b = op2(y);
    return a + b;
}

unsigned int k2_two_reloads(unsigned int x, unsigned int y, unsigned int z) {
    unsigned int a = op1(x);
    unsigned int b = op2(y);
    unsigned int s1 = a + b;
    unsigned int c = op2(z);
    return s1 + a + c;
}

unsigned int g1, g2;

int main(int argc, char **argv) {
    g1 = multi_src_de(0x1234, 0x5678, 1);
    g2 = k2_two_reloads(0xaaaa, 0xbbbb, 0xcccc);
    return 0;
}
