/* O54: Optimal stack adjustment via PUSH/POP for small frames.
 *
 * Goal: produce a function with a small (2- or 4-byte) hardware
 * stack frame so the prologue/epilogue's LXI+DAD+SPHL sequence is
 * exercised. Calling an opaque `extern` (without `nocallback`)
 * keeps `worker` ineligible for V6CAllocaPromote / V6CStaticStackAlloc
 * (O10), and holding multiple i8 values across the calls forces a
 * register spill.
 *
 * Compile (no extra flags needed under -O2):
 *   llvm-build\bin\clang.exe -target i8080-unknown-v6c -O2 -S \
 *       tests\features\47\v6llvmc.c -o tests\features\47\v6llvmc_new01.asm
 */

__attribute__((noinline))
int error_stack_arg(int x, int y, int z, int w, int a){
    return x+y+z+w+a;
}

__attribute__((noinline))
int reg_args(int x, int y, int z, int w, int a){
    return x+y+z;
}

volatile int i_p[] = {1, 2, 3, 4, 5};

int main(int argc, char **argv) {
    (void)argc; (void)argv;
    int res = error_stack_arg(i_p[0], i_p[1], i_p[2], i_p[3], i_p[4]);
    __builtin_v6c_out(0xED, res);
    res = reg_args(i_p[0], i_p[1], i_p[2], i_p[3], i_p[4]);
    __builtin_v6c_out(0xED, res);
    __builtin_v6c_hlt();
    return 0;
}
