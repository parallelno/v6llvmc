// c8080 reference for O65 test (stages 1–3).

extern unsigned char op(unsigned char x);
extern void use1(unsigned char);
extern void use2(unsigned char, unsigned char);

unsigned char counter;
unsigned char flag;
unsigned char slot;

unsigned char xor_bytes(unsigned char a, unsigned char b, unsigned char c,
                        unsigned char d, unsigned char e) {
    unsigned char x1 = op(a);
    unsigned char x2 = op(b);
    unsigned char x3 = op(c);
    unsigned char x4 = op(d);
    unsigned char x5 = op(e);
    use1(x1);
    return (unsigned char)(x1 ^ x2 ^ x3 ^ x4 ^ x5);
}

unsigned char and_bytes(unsigned char a, unsigned char b, unsigned char c) {
    unsigned char x1 = op(a);
    unsigned char x2 = op(b);
    unsigned char x3 = op(c);
    use1(x1);
    return (unsigned char)(x1 & x2 & x3);
}

unsigned char or_bytes(unsigned char a, unsigned char b, unsigned char c) {
    unsigned char x1 = op(a);
    unsigned char x2 = op(b);
    unsigned char x3 = op(c);
    use1(x1);
    return (unsigned char)(x1 | x2 | x3);
}

unsigned char add_bytes(unsigned char a, unsigned char b, unsigned char c) {
    unsigned char x1 = op(a);
    unsigned char x2 = op(b);
    unsigned char x3 = op(c);
    use1(x1);
    return (unsigned char)(x1 + x2 + x3);
}

unsigned char xor_with_passthrough(unsigned char a, unsigned char b,
                                   unsigned char c, unsigned char d) {
    unsigned char x1 = op(a);
    unsigned char x2 = op(b);
    unsigned char x3 = op(c);
    unsigned char x4 = op(d);
    use2(x1, x2);
    return (unsigned char)((x1 ^ x2) ^ (x3 ^ x4));
}

void inc_via_ptr(unsigned char *p) { (*p)++; }
void dec_via_ptr(unsigned char *p) { (*p)--; }
void set_via_ptr(unsigned char *p) { *p = 0x42; }

void inc_volatile(volatile unsigned char *p) { (*p)++; }
void dec_volatile(volatile unsigned char *p) { (*p)--; }
void set_volatile(volatile unsigned char *p) { *p = 0x55; }

void inc_indexed(unsigned char *p, unsigned char i) { p[i]++; }
void set_indexed(unsigned char *p, unsigned char i) { p[i] = 0x77; }

void init_buf(unsigned char *p) {
    p[0] = 0;
    p[1] = 1;
    p[2] = 0xFF;
}

unsigned char inc_via_ptr_and_read(unsigned char *p) {
    (*p)++;
    return *p;
}

int main(int argc, char **argv) {
    xor_bytes(0x11, 0x22, 0x33, 0x44, 0x55);
    and_bytes(0xF0, 0x0F, 0xAA);
    or_bytes(0x01, 0x02, 0x04);
    add_bytes(0x10, 0x20, 0x30);
    xor_with_passthrough(0xA1, 0xB2, 0xC3, 0xD4);
    inc_via_ptr(&counter);
    dec_via_ptr(&counter);
    set_via_ptr(&flag);
    inc_volatile((volatile unsigned char *)&counter);
    dec_volatile((volatile unsigned char *)&counter);
    set_volatile((volatile unsigned char *)&flag);
    inc_indexed(&slot, 0);
    set_indexed(&slot, 1);
    init_buf(&slot);
    (void)inc_via_ptr_and_read(&counter);
    return 0;
}
