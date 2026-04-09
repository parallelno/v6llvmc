void test_inline_asm(void) {
    asm volatile("NOP");
    asm volatile("DI");
    unsigned char val;
    asm volatile("IN 0x10" : "=a"(val));
}
