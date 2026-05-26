// c8080 reference for O85 — TypeNarrowing: narrow i16 up-counter with arithmetic users.
// Compiled with: tools\c8080\c8080.exe tests\features\67\c8080.c -a tests\features\67\c8080.asm
//
// c8080 uses unsigned char (i8) naturally for loop counters, so its output
// provides the reference for the optimal narrowed-counter instruction sequence.

typedef unsigned char uint8_t;
typedef unsigned short uint16_t;

// PRIMARY test: Case B — counter used in XOR arithmetic, no GEP indexed by i.
uint16_t iter_xor_mix(uint8_t seed) {
    uint16_t acc = seed;
    uint8_t i;  // c8080 uses i8 counter naturally
    for (i = 0; i < 64; i++) {
        acc += acc ^ (uint16_t)i;
    }
    return acc;
}

// SECONDARY test: Case B — counter's next value (i+1) used in arithmetic.
uint16_t iter_xor_next(uint8_t seed) {
    uint16_t acc = seed;
    uint8_t i;
    for (i = 0; i < 64; i++) {
        acc += acc ^ (uint16_t)(i + 1);
    }
    return acc;
}

// TERTIARY test: Case A (no improvement) — array access with GEP + counter arithmetic.
uint16_t weighted_sum(uint8_t *arr) {
    uint16_t s = 0;
    uint8_t i;
    for (i = 0; i < 64; i++) {
        s += (uint16_t)arr[i] + i;
    }
    return s;
}

int main(int argc, char **argv) {
    uint8_t arr[64];
    uint8_t k;
    for (k = 0; k < 64; k++) arr[k] = k;
    return (int)(iter_xor_mix(7) + iter_xor_next(7) + weighted_sum(arr)) & 0xFF;
}
