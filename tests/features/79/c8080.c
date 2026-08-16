volatile unsigned char byte_sink;
volatile unsigned int word_sink;

void leaf(unsigned int value) {
    unsigned int local = value + 1;
    word_sink = local;
}

void middle(unsigned int value) {
    leaf(value + 2);
    byte_sink = (unsigned char)value;
}

int main(int argc, char **argv) {
    byte_sink = 0x5a;
    middle(3);
    return 0;
}
