.section .bss.pack,"aw",@nobits,unique,1
.globl keep_other_object
keep_other_object:
  .zero 17

.section .bss.pack,"aw",@nobits,unique,2
.globl dead_other_object
dead_other_object:
  .zero 19
