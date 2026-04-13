// Test case for O38: XRA+CMP i8 Zero-Test Peephole
// c8080 reference version

int bar(int x) { return x + 1; }

int test_two_cond_tailcall(int x, int y) {
    if (x) return bar(x);
    if (y) return bar(x);
    return 0;
}

int test_simple_zero_check(int val) {
    if (val) return 1;
    return 0;
}

int test_nz_branch(int a, int b) {
    if (a) return b;
    return 0;
}

int main(int argc, char **argv) {
    volatile int r;
    r = test_two_cond_tailcall(0, 0);
    r = test_two_cond_tailcall(1, 0);
    r = test_two_cond_tailcall(0, 1);
    r = test_simple_zero_check(0);
    r = test_simple_zero_check(5);
    r = test_nz_branch(0, 10);
    r = test_nz_branch(3, 10);
    return 0;
}
