// Test case for O29: Cross-BB Immediate Value Propagation
// c8080 reference version

int action_a(void) { return 1; }
int action_b(void) { return 2; }

// Case 1: NE with lo8 == hi8 (0x4242)
int test_ne_same_bytes(int x) {
    if (x != 0x4242) {
        action_a();
    }
    action_b();
    return x;
}

// Case 2: EQ with lo8 == hi8
int test_eq_same_bytes(int x) {
    if (x == 0x4242) {
        action_a();
    }
    action_b();
    return x;
}

// Case 3: NE with lo8 != hi8 (control)
int test_ne_diff_bytes(int x) {
    if (x != 0x1234) {
        action_a();
    }
    action_b();
    return x;
}

// Case 4: NE with 0x0101
int test_ne_0101(int x) {
    if (x != 0x0101) {
        action_a();
    }
    action_b();
    return x;
}

int main(int argc, char **argv) {
    volatile int r;
    r = test_ne_same_bytes(0);
    r = test_ne_same_bytes(0x4242);
    r = test_ne_same_bytes(0x1234);
    r = test_eq_same_bytes(0);
    r = test_eq_same_bytes(0x4242);
    r = test_ne_diff_bytes(0);
    r = test_ne_diff_bytes(0x1234);
    r = test_ne_0101(0);
    r = test_ne_0101(0x0101);
    return 0;
}
