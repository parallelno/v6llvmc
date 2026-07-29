ENTRY(_start)
SECTIONS {
  . = 0x100;
  .text : { *(.text*) }
  .bss.pack : { *(.bss.pack) }
}

