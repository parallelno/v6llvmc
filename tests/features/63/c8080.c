// c8080 reference for O82 — MOV chain collapse and dead high-byte elimination.
//
// c8080 naturally avoids the dead MVI and copy chain because it tracks
// liveness precisely and never emits an intermediate copy register for a
// single-consumer value.
//
// Compile:
//   tools\c8080\c8080.exe tests\features\63\c8080.c -a tests\features\63\c8080.asm

static int   acc_int;
static char  acc_char;

// Stub implementations of the external functions.
int get_val(void) { return acc_int; }
void use_byte(char b)              { acc_char ^= b; }
void draw_stub(char x1, char y1)   { acc_char ^= x1; acc_char ^= y1; }

void test_dead_hi(void) {
    int r = get_val();
    use_byte((char)(r >> 8));
}

void test_chain_and_dead_hi(void) {
    int r = get_val();
    draw_stub((char)r, (char)(r >> 8));
}

int main(int argc, char **argv) {
    acc_int = 0x1234;
    test_dead_hi();
    test_chain_and_dead_hi();
    return 0;
}
