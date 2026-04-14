// Test case for O39: Interprocedural Register Allocation (IPRA) Integration
// c8080 reference version.

int sink;

void action_a(void) {
    sink = 1;
}

void action_b(void) {
    sink = 2;
}

int test_ne_same_bytes(int x) {
    if (x != 0x4242) {
        action_a();
    }
    action_b();
    return x;
}

int test_eq_same_bytes(int x) {
    if (x == 0x4242) {
        action_a();
    }
    action_b();
    return x;
}

int main(int argc, char **argv) {
    volatile int r;
    r = test_ne_same_bytes(0);
    r = test_ne_same_bytes(0x4242);
    r = test_eq_same_bytes(0);
    r = test_eq_same_bytes(0x4242);
    return sink + r;
}