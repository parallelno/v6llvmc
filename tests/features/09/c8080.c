// Test case for O31: Dead PHI-Constant Elimination
// c8080 reference version

int bar(int x) { return x + 1; }

int test_ne_zero(int x) {
    if (x)
        return bar(x);
    return 0;
}

int test_eq_zero(int x) {
    if (!x)
        return 0;
    return bar(x);
}

int test_const_42(int x) {
    if (x == 42)
        return 42;
    return bar(x);
}

int test_different_const(int x) {
    if (x == 1)
        return 0;
    return bar(x);
}

int main(int argc, char **argv) {
    int r = test_ne_zero(5);
    r += test_eq_zero(0);
    r += test_const_42(42);
    r += test_different_const(1);
    return r;
}
