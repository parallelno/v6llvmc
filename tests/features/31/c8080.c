// Test case for O60: Commutable ALU Operand Selection
// c8080 reference version.

void use8(unsigned char x) { /* stub */ }
void use16(unsigned int x) { /* stub */ }

unsigned char sum_add(unsigned char a, unsigned char b) { return a + b; }
unsigned char sum_and(unsigned char a, unsigned char b) { return a & b; }
unsigned char sum_or (unsigned char a, unsigned char b) { return a | b; }
unsigned char sum_xor(unsigned char a, unsigned char b) { return a ^ b; }

volatile unsigned char g_sink8;

unsigned char both_live(unsigned char a, unsigned char b) {
    unsigned char s = a + b;
    g_sink8 = a;
    g_sink8 = b;
    return s;
}

unsigned char spill_pressure(unsigned char a, unsigned char b,
                             unsigned char c, unsigned char d) {
    unsigned char t1 = c + d;
    g_sink8 = t1;
    return a + b;
}

unsigned char arr_sum(unsigned char a[], unsigned int n) {
    unsigned char s = 0;
    for (unsigned int i = 0; i < n; ++i)
        s += a[i];
    return s;
}


unsigned int sum16(unsigned int a, unsigned int b) { return a + b; }

int main(int argc, char **argv) {
    use8(sum_add(3, 4));
    use8(sum_and(0xF0, 0x0F));
    use8(sum_or (0x10, 0x20));
    use8(sum_xor(0xAA, 0x55));
    use8(both_live(7, 9));
    use8(spill_pressure(1, 2, 3, 4));
    use16(sum16(0x1234, 0x5678));
    unsigned char arr[4] = {1, 2, 3, 4};
    use8(arr_sum(arr, 4));
    return 0;
}
