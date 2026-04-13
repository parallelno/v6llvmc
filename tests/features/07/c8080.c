// Test case for O23: Conditional Tail Call Optimization
// c8080 reference version

int bar(int x) { return x + 1; }
int baz(int x) { return x + 2; }

int test_pattern_a(int x) {
    if (x)
        return bar(x);
    return 0;
}

int test_pattern_b(int x) {
    if (x)
        return 0;
    return bar(x);
}

int test_pattern_c(int x) {
    if (x)
        return bar(x);
    return baz(x);
}

int main(int argc, char **argv) {
    int r = test_pattern_a(1);
    r += test_pattern_b(0);
    r += test_pattern_c(1);
    return r;
}
