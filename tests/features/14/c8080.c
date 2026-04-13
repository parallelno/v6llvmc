// Test case for O35: Conditional Return Over RET (Jcc-over-RET -> Rcc)
// c8080 reference version

int bar(int x) { return x + 1; }
int baz(int x) { return x + 2; }

int test_two_arg_tailcall(int x, int y) {
    if (x == 0) return bar(y);
    return 0;
}

int test_cond_zero_tailcall(int x) {
    if (x == 0) return bar(0);
    return 0;
}

int test_early_return(int x) {
    if (x) return bar(x);
    return 0;
}

int main(int argc, char **argv) {
    volatile int r;
    r = test_two_arg_tailcall(0, 5);
    r = test_two_arg_tailcall(3, 5);
    r = test_cond_zero_tailcall(0);
    r = test_cond_zero_tailcall(5);
    r = test_early_return(3);
    r = test_early_return(0);
    return 0;
}
