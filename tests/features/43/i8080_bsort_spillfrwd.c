#define N 16
#include <stdint.h>
#include <c8080/io.h>
uint8_t ARR[N];

// Bubble sort.
void bsort(uint8_t *arr, uint8_t n) {
    for (uint8_t i = 0; i < n - 1; i++) {
        for (uint8_t j = 0; j < n - 1 - i; j++) {
            uint8_t a = arr[j];
            uint8_t b = arr[j + 1];
            if (a > b) {
                arr[j]     = b;
                arr[j + 1] = a;
            }
        }
    }
}

void print_arr(uint8_t *arr, uint8_t n) {
    for (uint8_t i = 0; i < n; i++) {
        out(0xED, arr[i]);
    }
}

int main(int argc, char **argv) {
    (void)argc; (void)argv;
    asm{
        di
    }
    bsort(ARR, N);
    print_arr(ARR, N);
    asm{
        halt
    }
    return 0;
}