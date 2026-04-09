void test_builtins(void) {
    __builtin_v6c_di();
    __builtin_v6c_ei();
    __builtin_v6c_hlt();
    __builtin_v6c_nop();
    unsigned char val = __builtin_v6c_in(0x10);
    __builtin_v6c_out(0x20, val);
}
