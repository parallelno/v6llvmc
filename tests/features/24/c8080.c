// Pre-RA INX/DCX Pseudo — O41 feature test (c8080 version)

#define LEN 100

unsigned char array1[LEN];
unsigned char array2[LEN];

void fill_array(unsigned char start_val) {
    unsigned char i;
    for (i = 0; i < LEN; i++)
        array1[i] = start_val + i;
}

void copy_loop(void) {
    unsigned char i;
    for (i = 0; i < LEN; i++)
        array2[i] = array1[i];
}

unsigned int add_small(unsigned int x) {
    return x + 2;
}

unsigned int sub_small(unsigned int x) {
    return x - 1;
}

int main(int argc, char **argv) {
    fill_array(10);
    copy_loop();
    return 0;
}
