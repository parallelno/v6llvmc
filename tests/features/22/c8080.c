// ADD16 DAD-Based Expansion — O40 feature test (c8080 version)

volatile int sink_val;

void use_val(int x) {
    sink_val = x;
}

int get_val(void) {
    return sink_val;
}

int nested_add(int n) {
    int a = get_val();
    int b = get_val();
    int c = a + b + n;
    use_val(c);
    return a + b;
}

int main(int argc, char **argv) {
    int r = nested_add(5);
    return r;
}
