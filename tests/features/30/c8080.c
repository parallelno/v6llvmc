// Test case for O48: Scavenger-Based Pseudo Expansion
// c8080 reference version.

void use8(unsigned char x) { /* stub */ }
void use16(unsigned int x) { /* stub */ }

void copy_pair(unsigned char *dst, const unsigned char *src) {
    unsigned char a = src[0];
    unsigned char b = src[1];
    dst[0] = a;
    dst[1] = b;
}

unsigned int load16_via_ptr(unsigned int *p) {
    return *p;
}

unsigned int g_val;

unsigned int load16_global() {
    return g_val;
}

unsigned char sum_array(const unsigned char *arr, unsigned char n) {
    unsigned char sum = 0;
    unsigned char i;
    for (i = 0; i < n; i++) {
        sum += arr[i];
    }
    return sum;
}

int main(int argc, char **argv) {
    unsigned char src[4];
    unsigned char dst[4];
    src[0] = 10; src[1] = 20; src[2] = 30; src[3] = 40;
    copy_pair(dst, src);
    use8(dst[0]);
    use8(dst[1]);

    unsigned int val16 = 0x1234;
    unsigned int r16 = load16_via_ptr(&val16);
    use16(r16);

    g_val = 0xABCD;
    unsigned int r_g = load16_global();
    use16(r_g);

    unsigned char s = sum_array(src, 4);
    use8(s);

    return 0;
}
