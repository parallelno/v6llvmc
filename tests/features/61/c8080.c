// c8080 reference for O79 — MVI R + ALU R → ALU-imm fold.
// Plain baseline; c8080 has its own peephole for ALU-immediate
// patterns. Cycle/byte costs serve as the comparison anchor.

typedef unsigned char u8;

extern volatile u8 g_sink;

u8 fold_add(u8 a) { return a + 0x0F; }
u8 fold_sub(u8 a) { return a - 0x05; }
u8 fold_and(u8 a) { return a & 0xF0; }
u8 fold_or (u8 a) { return a | 0x01; }
u8 fold_xor(u8 a) { return a ^ 0x55; }
int fold_cmp(u8 a) { return (a == 0x42) ? 1 : 0; }
u8 fold_chain(u8 a) { return ((a + 5) & 0xF0) ^ 0x10; }

u8 fold_spill(u8 x0, u8 x1, u8 x2, u8 x3,
              u8 x4, u8 x5, u8 x6, u8 x7) {
    u8 s = x0;
    s ^= x1; s ^= x2; s ^= x3;
    s ^= x4; s ^= x5; s ^= x6;
    s ^= x7;
    return s;
}

volatile u8 g_sink;

int main(int argc, char **argv) {
    (void)argc; (void)argv;
    g_sink = fold_add(0x10);
    g_sink = fold_sub(0x10);
    g_sink = fold_and(0xAB);
    g_sink = fold_or(0xAA);
    g_sink = fold_xor(0xAA);
    g_sink = (u8)fold_cmp(0x42);
    g_sink = fold_chain(0x07);
    g_sink = fold_spill(1, 2, 3, 4, 5, 6, 7, 8);
    return 0;
}
