/* O17: Redundant Flag-Setting Elimination test case.
 * c8080 version for comparison.
 */

unsigned char g_port;

void countdown(unsigned char n) {
    while (n != 0) {
        g_port = n;
        n--;
    }
}

void countup(unsigned char start) {
    unsigned char i;
    i = start;
    while (i != 0) {
        g_port = i;
        i++;
    }
}

int xor_test(int a, int b) {
    int r;
    r = a ^ b;
    if (r == 0)
        return 1;
    return 0;
}

int sub_test(int a, int b) {
    int r;
    r = a - b;
    if (r == 0)
        return 1;
    return 0;
}

int main(int argc, char **argv) {
    countdown(5);
    countup(250);
    xor_test(5, 5);
    sub_test(10, 10);
    return 0;
}
