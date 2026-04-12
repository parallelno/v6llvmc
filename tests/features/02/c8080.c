/* O18 Loop Counter DEC+Branch Peephole - c8080 test */

unsigned char output_port;

/* Simple countdown loop */
void countdown(unsigned char n) {
    while (n != 0) {
        output_port = n;
        n--;
    }
}

/* Simple decrement-and-test loop */
unsigned char count_down(unsigned char n) {
    while (n != 0) {
        n--;
    }
    return n;
}

int main(int argc, char **argv) {
    countdown(5);
    return count_down(10);
}
