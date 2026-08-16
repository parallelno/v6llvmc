volatile int sink;

int static_probe(int parameter) {
    int local = parameter + 0x123;
    volatile int addressable = local + 1;
    sink = addressable;
    return local;
}

int dynamic_probe(int parameter) {
    int local = parameter + 0x234;
    volatile int addressable = local + 1;
    sink = addressable;
    return local;
}

int main(int argc, char **argv) {
    return static_probe(0x1122) + dynamic_probe(0x3344);
}
