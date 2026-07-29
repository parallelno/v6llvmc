.section .bss.pack.align,"aw",@nobits,unique,1
.globl anchor_100
anchor_100:
  .zero 100

.section .bss.pack.align,"aw",@nobits,unique,2
.globl anchor_300
anchor_300:
  .zero 300

.section .bss.pack.window,"aw",@nobits,unique,3
.globl window_120
window_120:
  .zero 120

.section .bss.pack.window,"aw",@nobits,unique,4
.globl window_256
window_256:
  .zero 256

.section .bss.pack.window,"aw",@nobits,unique,5
.globl window_200
window_200:
  .zero 200

.section .bss.pack.window,"aw",@nobits,unique,6
.globl equal_window_a
equal_window_a:
  .zero 20

.section .bss.pack.window,"aw",@nobits,unique,7
.globl equal_window_b
equal_window_b:
  .zero 20

.section .bss.pack,"aw",@nobits,unique,8
.globl filler_40
filler_40:
  .zero 40

.section .bss.pack,"aw",@nobits,unique,9
.globl filler_60
filler_60:
  .zero 60
