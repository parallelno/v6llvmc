ENTRY(_start)
SECTIONS {
  . = 0x100;
  .text : { *(.text*) }
  .bss.pack : {
    KEEP(*keep.o(.bss.pack))
    *(.bss.pack)
  }
}

