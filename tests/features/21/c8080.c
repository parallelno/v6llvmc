// Static Stack Allocation — O10 feature test (c8080 version)
// Test: non-reentrant functions with spills

volatile int sink_val;

void use_val(int x) {
    sink_val = x;
}

int get_val(void) {
    return sink_val;
}

// Case 1: Three values live across calls — forces spills.
int heavy_spill(int a, int b) {
    int x = a + 1;
    int y = b + 2;
    int z = a + b;
    use_val(x);
    use_val(y);
    use_val(z);
    return x + y + z;
}

// Case 2: Nested calls with values preserved.
int nested_calls(int n) {
    int a = get_val();
    int b = get_val();
    int c = a + b + n;
    use_val(c);
    return a + b;
}

int main(int argc, char **argv) {
    int r;
    r = heavy_spill(10, 20);
    use_val(r);
    r = nested_calls(5);
    use_val(r);
    return r;
}
