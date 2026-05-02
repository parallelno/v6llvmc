/* O69: Direct frame-index load/store pseudos.
 * c8080 reference compile target. */

#define __attribute__(x)

typedef unsigned char u8;

volatile u8 g8;
volatile int g16;

__attribute__((noinline))
u8 load8_stack_arg(u8 a0, u8 a1, u8 a2, u8 a3,
                   u8 a4, u8 a5, u8 a6, u8 a7) {
    return a7;
}

__attribute__((noinline))
int load16_stack_arg(int a0, int a1, int a2, int a3) {
    return a0 + a1 + a2 + a3;
}

__attribute__((noinline))
u8 store8_local(u8 x) {
    volatile u8 slot;
    slot = x;
    return slot;
}

__attribute__((noinline))
int store16_local(int x) {
    volatile int slot;
    slot = x;
    return slot;
}

int main(int argc, char **argv) {
    (void)argc; (void)argv;
    g8 = load8_stack_arg(1, 2, 3, 4, 5, 6, 7, 8);
    g16 = load16_stack_arg(1, 2, 3, 4);
    g8 = store8_local(g8);
    g16 = store16_local(g16);
    return 0;
}
