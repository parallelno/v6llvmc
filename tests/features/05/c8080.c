// Test case for O13: Load-Immediate Combining (Register Value Tracking)
// c8080 reference version

// Volatile to prevent optimization
volatile unsigned char sink8;
volatile unsigned int sink16;

void use8(unsigned char val) { sink8 = val; }
void use16(unsigned int val) { sink16 = val; }
unsigned char get8(void) { return sink8; }

void test_multi_zext(unsigned char a, unsigned char b) {
    unsigned int wide_a = a;
    unsigned int wide_b = b;
    use16(wide_a + wide_b);
}

void test_same_imm(void) {
    use8(42);
    use8(42);
}

void test_sequential_values(void) {
    use8(10);
    use8(11);
}

void test_mov_propagation(unsigned char a) {
    unsigned int w1 = a;
    use16(w1);
    unsigned int w2 = a;
    use16(w2);
}

int main(int argc, char **argv) {
    test_multi_zext(5, 10);
    test_same_imm();
    test_sequential_values();
    test_mov_propagation(7);
    return 0;
}
