SECTIONS {
  _start = 0;
  .bss.pack 0x100 : { *(.bss.pack) *(.other) *(.bss.pack.align) }
}

