.section .text._start,"ax",@progbits
.globl _start
_start:
  .short oversized_window

.section .bss.pack.window,"aw",@nobits,unique,1
.globl oversized_window
oversized_window:
  .zero 257
