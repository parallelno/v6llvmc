/* O11: Dual Cost Model — c8080 reference */

volatile unsigned char mem[16];

unsigned char read_offset1(unsigned char *p) {
    return *(p + 1);
}

unsigned char read_offset2(unsigned char *p) {
    return *(p + 2);
}

unsigned char read_offset3(unsigned char *p) {
    return *(p + 3);
}

unsigned char read_offset4(unsigned char *p) {
    return *(p + 4);
}

unsigned int sum_adjacent(unsigned char *p) {
    return (unsigned int)p[0] + p[1];
}

unsigned int sum_three(unsigned char *p) {
    return (unsigned int)p[0] + p[1] + p[2];
}

int main(int argc, char **argv) {
    unsigned char *p = (unsigned char *)mem;
    read_offset1(p);
    read_offset2(p);
    read_offset3(p);
    read_offset4(p);
    sum_adjacent(p);
    sum_three(p);
    return 0;
}
