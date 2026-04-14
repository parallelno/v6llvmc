// Test case for O16: Post-RA Store-to-Load Forwarding
// c8080 reference version.

void use8(unsigned char x) {
    /* extern in v6llvmc version; stub here for c8080 */
}

unsigned char get8(void) {
    return 42;
}

void multi_ptr_copy(unsigned char *dst, unsigned char *src, unsigned char n) {
    unsigned char i;
    for (i = 0; i < n; i++) {
        dst[i] = src[i] + 1;
    }
}

unsigned char multi_live(unsigned char a, unsigned char b, unsigned char c) {
    unsigned char x = a + 1;
    unsigned char y = b + 2;
    use8(c);
    return x + y;
}

unsigned char nested_calls(unsigned char a, unsigned char b) {
    unsigned char x = get8();
    unsigned char y = a + x;
    use8(b);
    unsigned char z = get8();
    return y + z;
}

int main(int argc, char **argv) {
    unsigned char buf_dst[4];
    unsigned char buf_src[4];
    volatile unsigned char r;

    buf_dst[0] = 0; buf_dst[1] = 0; buf_dst[2] = 0; buf_dst[3] = 0;
    buf_src[0] = 10; buf_src[1] = 20; buf_src[2] = 30; buf_src[3] = 40;

    multi_ptr_copy(buf_dst, buf_src, 4);
    r = buf_dst[0];

    r = multi_live(1, 2, 3);
    r = nested_calls(5, 6);

    return r;
}
