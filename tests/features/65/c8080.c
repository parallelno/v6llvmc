// c8080 reference for O84 — INX/DCX-through-spill round-trip fold.
//
// c8080 emits tighter code without round-trip MOV sequences because it
// operates directly on HL for in-place increments before storing.
// This file provides the reference assembly for cycle/byte comparison.
//
// Compile:
//   %C8080% tests\features\65\c8080.c -a tests\features\65\c8080.asm

typedef unsigned short u16;
typedef unsigned char  u8;

static u8 flags[200];

u16 sieve_count(u16 n) {
    u16 i, k, count, i_sq;

    for (k = 0; k < n; k++) flags[k] = 0;

    count = (u16)(n - 2);
    i_sq  = 4;
    for (i = 2; i_sq < n; ++i) {
        if (!flags[i]) {
            for (k = i_sq; k < n; k = (u16)(k + i)) {
                if (!flags[k]) count = (u16)(count - 1);
                flags[k] = 1;
            }
        }
        i_sq = (u16)(i_sq + i + i + 1);
    }
    return count;
}

int main(int argc, char **argv) {
    (void)argc; (void)argv;
    u16 c = sieve_count(200);
    return (int)((u8)c ^ (u8)(c >> 8));
}
