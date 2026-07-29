SECTIONS {
  _start = 0;
  .bss.pack 0x10a : {
    *(.bss.pack.align)
    *(.bss.pack.window)
    *(.bss.pack)
  }
  after_pack = .;
  arena_addr = ADDR(.bss.pack);
  arena_size = SIZEOF(.bss.pack);
}

