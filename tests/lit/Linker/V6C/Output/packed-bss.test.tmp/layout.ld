ENTRY(_start)
SECTIONS {
  . = 0x100;
  .text : { *(.text*) }
  . = 0x200;
  __bss_start = .;
  .bss.pack : {
    *(.bss.pack.align)
    *(.bss.pack.window)
    *(.bss.pack)
  }
  __bss_end = .;
  arena_size = SIZEOF(.bss.pack);
}

