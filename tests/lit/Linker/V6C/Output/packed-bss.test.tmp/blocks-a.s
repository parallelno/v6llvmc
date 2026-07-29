.section .bss.pack.align,"aw",@nobits,unique,1
.globl containers_inst_data_ptrs
containers_inst_data_ptrs:
  .zero 256

.section .bss.pack.align,"aw",@nobits,unique,2
.globl resources_inst_data_ptrs
resources_inst_data_ptrs:
  .zero 256

.section .bss.pack.align,"aw",@nobits,unique,3
.globl breakables_status
breakables_status:
  .zero 256

.section .bss.pack.align,"aw",@nobits,unique,4
.globl room_tiledata
room_tiledata:
  .zero 240

.section .bss.pack.window,"aw",@nobits,unique,5
.globl overlays_runtime_data
overlays_runtime_data:
  .zero 227

.section .bss.pack.window,"aw",@nobits,unique,6
.globl hero_resources
hero_resources:
  .zero 17

.section .bss.pack.window,"aw",@nobits,unique,7
.globl rooms_spawn_rate
rooms_spawn_rate:
  .zero 64

.section .bss.pack.window,"aw",@nobits,unique,8
.globl backs_runtime_data
backs_runtime_data:
  .zero 62

.section .bss.pack,"aw",@nobits,unique,9
.globl temp_buff
temp_buff:
  .zero 512

.section .bss.pack,"aw",@nobits,unique,10
.globl chars_runtime_data
chars_runtime_data:
  .zero 482

.section .bss.pack,"aw",@nobits,unique,11
.globl room_tiles_gfx_ptrs
room_tiles_gfx_ptrs:
  .zero 480

.section .bss.pack,"aw",@nobits,unique,12
.globl dead_block
dead_block:
  .zero 199

