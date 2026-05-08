#include <stdint.h>

int addi16(int a, uint8_t c) {
    while ((c <<= 1)) {
        a += 1;
    }
    return a;
}
