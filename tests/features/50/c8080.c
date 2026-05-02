/* O02 baseline test for c8080 (Z80 backend reference). */

extern unsigned char ext_sink(unsigned char v);

struct S { unsigned char x, y, z, w; };
struct S g_s;

unsigned char sum4_global(void) {
    return g_s.x + g_s.y + g_s.z + g_s.w;
}

volatile unsigned char g_a, g_b, g_c, g_d;
void write4_globals(unsigned char v) {
    g_a = v;
    g_b = v + 1;
    g_c = v + 2;
    g_d = v + 3;
}

unsigned char sum4_array(const unsigned char *p) {
    unsigned char s = p[0];
    s += p[1];
    s += p[2];
    s += p[3];
    return s;
}

unsigned char g_arr[4];

int main(int argc, char **argv) {
    (void)argc; (void)argv;
    g_arr[0] = 1; g_arr[1] = 2; g_arr[2] = 3; g_arr[3] = 4;
    unsigned char r1 = sum4_global();
    unsigned char r2 = sum4_array(g_arr);
    write4_globals(r1 + r2);
    return ext_sink(g_a + g_b + g_c + g_d);
}
