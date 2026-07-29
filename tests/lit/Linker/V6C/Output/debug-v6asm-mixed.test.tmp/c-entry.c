extern unsigned char asm_leaf(void);

unsigned char c_entry(void) {
  return asm_leaf() + 1;
}

