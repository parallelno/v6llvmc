// Test case for O37: Deferred Zero-Load After Zero-Test
// c8080 reference version

int bar(int x) { return x + 1; }

int test_cond_zero_return_zero(int x) {
    if (x == 0) return bar(0);
    return 0;
}

int test_both_call_zero(int x) {
    if (x == 0) return bar(0);
    return bar(0);
}

int test_one_path_zero(int x) {
    if (x == 0) return bar(0);
    return x;
}

int main(int argc, char **argv) {
    volatile int r;
    r = test_cond_zero_return_zero(0);
    r = test_cond_zero_return_zero(5);
    r = test_both_call_zero(0);
    r = test_both_call_zero(5);
    r = test_one_path_zero(0);
    r = test_one_path_zero(5);
    return 0;
}
