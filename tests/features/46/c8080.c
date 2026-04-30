// Feature test 46 (c8080 baseline) -- O55 Pattern 2 reference.
// c8080 mnemonics differ, but the source-level shape is identical so
// the two compilers can be compared instruction-by-instruction in
// result.txt.

typedef unsigned char  u8;
typedef signed char    i8;
typedef unsigned short u16;

i8 const_zero(void) { return 0; }

volatile u8 g_sink;

void clear_sink_twice(void) {
    g_sink = 0;
    g_sink = 0;
}

i8 neg_or_seven(i8 a, i8 b) {
    return (a - b) < 0 ? (i8)0 : (i8)7;
}

volatile i8  g_a = -3;
volatile i8  g_b =  4;
volatile i8  g_out;

int main(int argc, char **argv) {
    (void)argc; (void)argv;
    g_out = const_zero();
    clear_sink_twice();
    g_out = neg_or_seven(g_a, g_b);
    return 0;
}
