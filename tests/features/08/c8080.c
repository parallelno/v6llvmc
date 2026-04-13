// Test case for O27: i16 Zero-Test Optimization
// c8080 reference version

int bar(int x) { return x + 1; }
int baz(int x) { return x + 2; }

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

int test_while_loop(int n) {
    volatile int sum = 0;
    while (n) {
        sum += n;
        n--;
    }
    return sum;
}

int test_null_ptr(int *p) {
    if (p)
        return *p;
    return -1;
}

int main(int argc, char **argv) {
    int r = test_ne_zero(5);
    r += test_eq_zero(0);
    r += test_while_loop(10);
    int val = 42;
    r += test_null_ptr(&val);
    return r;
}
