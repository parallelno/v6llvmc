.section .bss.pack,"aw",@nobits
.globl first_filler
first_filler:
  .zero 16

.section .other,"aw",@nobits
.globl other_block
other_block:
  .zero 16

.section .bss.pack.align,"aw",@nobits
.globl late_anchor
late_anchor:
  .zero 16

