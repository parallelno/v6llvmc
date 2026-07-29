SECTIONS {
  _start = 0;
  .bss.pack 0x10a : { *(.bss.pack) *(.bss.pack.align) }
}

