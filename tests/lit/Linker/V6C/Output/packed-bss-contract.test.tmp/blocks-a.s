.section .bss.pack,"aw",@nobits,unique,1
.globl keep_same_object
keep_same_object:
  .zero 11

.section .bss.pack,"aw",@nobits,unique,2
.globl dead_same_object
dead_same_object:
  .zero 13

