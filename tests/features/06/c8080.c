// Test case for O6: LDA/STA for Absolute Address Loads/Stores
// c8080 reference version

#define PORT_A  (*(volatile unsigned char*)0x100)
#define PORT_B  (*(volatile unsigned char*)0x200)

unsigned char read_port(void) {
    return PORT_A;
}

void write_port(unsigned char val) {
    PORT_A = val;
}

void copy_port(void) {
    PORT_B = PORT_A;
}

int main(int argc, char **argv) {
    write_port(42);
    copy_port();
    unsigned char r = read_port();
    return r;
}
