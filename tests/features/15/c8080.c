// Test case for O36: Redundant LXI After Zero-Test Branch
// c8080 reference version

int bar(int x) { return x + 1; }
int baz(int x, int y) { return x + y; }

int test_cond_zero_tailcall(int x) {
    if (x == 0) return bar(0);
    return x;
}

int test_cond_zero_return_zero(int x) {
    if (x == 0) return bar(0);
    return 0;
}

int test_nonzero_path(int x) {
    if (x != 0) return x;
    return bar(0);
}

int main(int argc, char **argv) {
    volatile int r;
    r = test_cond_zero_tailcall(0);
    r = test_cond_zero_tailcall(5);
    r = test_cond_zero_return_zero(0);
    r = test_cond_zero_return_zero(5);
    r = test_nonzero_path(0);
    r = test_nonzero_path(5);
    return 0;
}
