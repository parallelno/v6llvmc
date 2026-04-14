// Honest Store/Load Pseudo Defs — O20 feature test (c8080 version)

#define LEN 100

unsigned char array1[LEN];
unsigned char array2[LEN];

void fill_array(unsigned char start_val) {
    unsigned char i;
    for (i = 0; i < LEN; i++)
        array1[i] = start_val + i;
}

void copy_array(void) {
    unsigned char i;
    for (i = 0; i < LEN; i++)
        array2[i] = array1[i];
}

int main(int argc, char **argv) {
    fill_array(42);
    copy_array();
    return array2[0] + array2[99];
}
