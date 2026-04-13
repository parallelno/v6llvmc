// Test case for O30: Conditional Return Peephole (Jcc RET → Rcc)
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

int test_multi_cond(int x) {
    if (x == 1)
        return 10;
    if (x == 2)
        return 20;
    return bar(x);
}

int test_null_guard(int *p) {
    if (p)
        return *p;
    return -1;
}

int main(int argc, char **argv) {
    int r = test_ne_zero(5);
    r += test_eq_zero(0);
    r += test_multi_cond(1);
    r += test_multi_cond(2);
    r += test_multi_cond(3);
    int val = 42;
    r += test_null_guard(&val);
    return r;
}
