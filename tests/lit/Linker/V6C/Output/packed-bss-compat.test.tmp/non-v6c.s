.section .bss.pack,"aw",@nobits
.globl non_v6c_filler
non_v6c_filler:
  .zero 16

.section .bss.pack.align,"aw",@nobits
.globl non_v6c_anchor
non_v6c_anchor:
  .zero 16

