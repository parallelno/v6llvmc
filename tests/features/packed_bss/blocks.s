.section .bss.pack,"aw",@nobits,unique,1
.globl filler_block
filler_block:
  .zero 40

.section .bss.pack.align,"aw",@nobits,unique,2
.globl anchor_block
anchor_block:
  .zero 300

.section .bss.pack.window,"aw",@nobits,unique,3
.globl window_block
window_block:
  .zero 200

.section .bss.pack,"aw",@nobits,unique,4
.globl dead_block
dead_block:
  .zero 31
