.section .bss.pack,"aw",@nobits,unique,1
.globl room_tiledata_backup
room_tiledata_backup:
  .zero 240

.section .bss.pack,"aw",@nobits,unique,2
.globl hero_runtime_data
hero_runtime_data:
  .zero 31

.section .bss.pack,"aw",@nobits,unique,3
.globl os_io_data
os_io_data:
  .zero 17

.section .bss.pack,"aw",@nobits,unique,4
.globl game_status
game_status:
  .zero 16

.section .bss.pack,"aw",@nobits,unique,5
.globl palette
palette:
  .zero 16

.section .bss.pack,"aw",@nobits,unique,6
.globl global_items
global_items:
  .zero 15

.section .bss.pack,"aw",@nobits,unique,7
.globl lv_data_init_tbl
lv_data_init_tbl:
  .zero 14

.section .bss.pack,"aw",@nobits,unique,8
.globl actor_data_head_ptr
actor_data_head_ptr:
  .zero 2

.section .bss.pack,"aw",@nobits,unique,9
.globl ram_disk_mode
ram_disk_mode:
  .zero 1

.section .bss.pack,"aw",@nobits,unique,10
.globl room_teleports_data
room_teleports_data:
  .zero 16

.section .bss.pack,"aw",@nobits,unique,11
.globl global_states
global_states:
  .zero 10

.section .bss.pack,"aw",@nobits,unique,12
.globl switch_statuses
switch_statuses:
  .zero 2

