// Test case for O16: Post-RA Store-to-Load Forwarding
// Exercises spill/reload patterns where registers hold their spilled value
// at the reload point, enabling forwarding.

extern void use8(unsigned char x);
extern unsigned char get8(void);

// Case 1: Multi-pointer copy loop — high HL pressure, many spill/reload pairs
void multi_ptr_copy(unsigned char *dst, unsigned char *src, unsigned char n) {
    unsigned char i;
    for (i = 0; i < n; i++) {
        dst[i] = src[i] + 1;
    }
}

// Case 2: Multiple live values across a call — registers spilled, then reloaded
unsigned char multi_live(unsigned char a, unsigned char b, unsigned char c) {
    unsigned char x = a + 1;
    unsigned char y = b + 2;
    use8(c);
    return x + y;
}

// Case 3: Nested calls with retained values
unsigned char nested_calls(unsigned char a, unsigned char b) {
    unsigned char x = get8();
    unsigned char y = a + x;
    use8(b);
    unsigned char z = get8();
    return y + z;
}

int main(void) {
    unsigned char buf_dst[4] = {0, 0, 0, 0};
    unsigned char buf_src[4] = {10, 20, 30, 40};
    volatile unsigned char r;

    multi_ptr_copy(buf_dst, buf_src, 4);
    r = buf_dst[0];

    r = multi_live(1, 2, 3);
    r = nested_calls(5, 6);

    return r;
}
