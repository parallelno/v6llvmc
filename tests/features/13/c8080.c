// Test case for O28: Branch Threading Through JMP-Only Blocks
// Conditional branch to a block containing only JMP should be
// redirected directly to the JMP's target (thread through).

int bar(int x) { return x + 1; }
int baz(int x) { return x + 2; }

// Pattern A: if (x == 0) return bar(0); return 0;
int test_cond_zero_tailcall(int x) {
    if (x == 0) return bar(0);
    return 0;
}

// Pattern B: Two conditions → same tail call block.
int test_two_cond_tailcall(int x, int y) {
    if (x) return bar(x);
    if (y) return bar(x);
    return 0;
}

// Pattern C: Simple pass-through tail call (baseline).
int test_simple_tailcall(int x) {
    if (x) return bar(x);
    return 0;
}

int main(int argc, char **argv) {
    volatile int r;
    r = test_cond_zero_tailcall(0);
    r = test_cond_zero_tailcall(5);
    r = test_two_cond_tailcall(1, 0);
    r = test_two_cond_tailcall(0, 1);
    r = test_two_cond_tailcall(0, 0);
    r = test_simple_tailcall(5);
    r = test_simple_tailcall(0);
    return 0;
}
