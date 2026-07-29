SECTIONS {
  _start = 0;
  .bss.pack : { *(.bss.pack.align) *(.bss.pack.window) *(.bss.pack) }
}

