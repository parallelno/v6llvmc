SECTIONS {
  _start = 0;
  .bss 0x10a : { *(.bss*) }
  .other : { *(.other) }
}

