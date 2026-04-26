// End-to-end test for the O-LLD plan (native ld.lld + crt0 + linker script).
//
// Builds a bubble-sort over a statically initialized 16-element array and
// emits the sorted result to V6C port 0xED (one byte per element).
//
// Expected output on port 0xED, in order:
//   0x01 0x05 0x07 0x0C 0x10 0x17 0x1F 0x23
//   0x2A 0x37 0x42 0x55 0x63 0x7E 0x99 0xBC
//
// This file is a self-contained replacement for the bsort case used in the
// plan's Verification step. Unlike tests/features/43/v6llvmc_bsort_spillfrwd.c,
// the array here lives in .data (statically initialized), so the test
// exercises the linker's .data layout in addition to .text/.bss.

#include <stdint.h>

#define N 16

// Statically initialized — must end up in .data, not .bss.
uint8_t ARR[N] = {
    0x42, 0x01, 0x99, 0x17, 0x05, 0xBC, 0x2A, 0x10,
    0x7E, 0x23, 0x37, 0x0C, 0x55, 0x1F, 0x63, 0x07,
};

__attribute__((noinline))
void bsort_for(uint8_t *arr, uint8_t n) {
    for (uint8_t i = 0; i < n - 1; i++) {
        uint8_t j = 0;
        while (j < n - 1 - i) {
            uint8_t a = arr[j];
            uint8_t b = arr[j + 1];
            if (a > b) {
                arr[j]     = b;
                arr[j + 1] = a;
            }
            j++;
        }
    }
}

__attribute__((noinline))
void print_arr(const uint8_t *arr, uint8_t n) {
    for (uint8_t i = 0; i < n; i++) {
        __builtin_v6c_out(0xED, arr[i]);
    }
}

int main(int argc, char **argv) {
    (void)argc; (void)argv;
    __builtin_v6c_di();
    bsort_for(ARR, N);
    print_arr(ARR, N);
    __builtin_v6c_hlt();
    return 0;
}
