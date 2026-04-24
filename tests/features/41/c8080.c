// Test case for O49 — direct memory ALU/store ISel (M-operand
// instructions: ADD/SUB/AND/OR/XOR/CMP M, MVI M, INR M, DCR M).
//
// Compile:
//   tools\c8080\c8080.exe tests\features\41\c8080.c \
//       -a tests\features\41\c8080.asm

unsigned char add_m(unsigned char a, unsigned char *p) {
    return a + *p;
}

unsigned char sub_m(unsigned char a, unsigned char *p) {
    return a - *p;
}

unsigned char and_m(unsigned char a, unsigned char *p) {
    return a & *p;
}

unsigned char or_m(unsigned char a, unsigned char *p) {
    return a | *p;
}

unsigned char xor_m(unsigned char a, unsigned char *p) {
    return a ^ *p;
}

int cmp_m(unsigned char a, unsigned char *p) {
    return a == *p;
}

void store_imm(unsigned char *p) {
    *p = 0x42;
}

void inc_m(unsigned char *p) {
    (*p)++;
}

void dec_m(unsigned char *p) {
    (*p)--;
}

unsigned char sum_bytes(unsigned char *p, unsigned char n) {
    unsigned char s = 0;
    unsigned char i;
    for (i = 0; i < n; ++i) s += p[i];
    return s;
}

unsigned char buf[4] = {1, 2, 3, 4};

int main(int argc, char **argv) {
    unsigned char a = 0x10;
    a = add_m(a, buf);
    a = sub_m(a, buf + 1);
    a = and_m(a, buf + 2);
    a = or_m(a, buf + 3);
    a = xor_m(a, buf);
    cmp_m(a, buf);
    store_imm(buf);
    inc_m(buf + 1);
    dec_m(buf + 2);
    return sum_bytes(buf, 4);
}
