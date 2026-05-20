// Minimal V6C ROM: emits a byte on the debug port and halts.
//
// Build:
//   clang -O2 -target i8080-unknown-v6c main.c -o main.rom
//
// Run in the emulator:
//   v6emul --rom main.rom --load-addr 0x0100 --halt-exit --dump-cpu
//
// Expected output: TEST_OUT port=0xED value=0x42
#include <stdint.h>

int main(void) {
    __builtin_v6c_out(0xED, 0x42);
    __builtin_v6c_hlt();
    return 0;
}
