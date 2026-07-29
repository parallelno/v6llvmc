SECTIONS {
  _start = 0;
  .bss.pack 0xff00 : { *(.bss.pack) }
}

