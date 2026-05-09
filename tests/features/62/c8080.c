// c8080 reference for O80 — i8 zero-test compare via INR/DCR.

unsigned char op_acc;

unsigned char op1(unsigned char x) { op_acc ^= x; return (unsigned char)(x + 1); }
void          sink(unsigned char x) { op_acc ^= x; }
void          use2(unsigned char a, unsigned char b) { op_acc ^= a; op_acc ^= b; }

unsigned char shape_a(unsigned char a) {
    if (a) return 1;
    return 0;
}

unsigned char shape_a_dead(unsigned char x, unsigned char y) {
    if (y) return x;
    return 0;
}

unsigned char shape_a_live(unsigned char val_in_A, unsigned char cond) {
    unsigned char r = op1(val_in_A);
    if (cond) return (unsigned char)(r + 1);
    return r;
}

unsigned char shape_a_live_loop(unsigned char seed, unsigned char n) {
    unsigned char acc = seed;
    while (n) {
        acc = op1(acc);
        n--;
    }
    return acc;
}

int main(int argc, char **argv) {
    use2(shape_a(0x11),            shape_a(0));
    use2(shape_a_dead(0x22, 0x33), shape_a_dead(0x44, 0));
    use2(shape_a_live(0x55, 1),    shape_a_live(0x66, 0));
    sink(shape_a_live_loop(0x77, 5));
    return 0;
}
