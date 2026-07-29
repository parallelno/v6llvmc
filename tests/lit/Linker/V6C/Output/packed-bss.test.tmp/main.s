.section .text._start,"ax",@progbits
.globl _start
_start:
  .short containers_inst_data_ptrs
  .short resources_inst_data_ptrs
  .short breakables_status
  .short room_tiledata
  .short overlays_runtime_data
  .short hero_resources
  .short rooms_spawn_rate
  .short backs_runtime_data
  .short temp_buff
  .short chars_runtime_data
  .short room_tiles_gfx_ptrs
  .short room_tiledata_backup
  .short hero_runtime_data
  .short os_io_data
  .short game_status
  .short palette
  .short global_items
  .short lv_data_init_tbl
  .short actor_data_head_ptr
  .short ram_disk_mode
  .short room_teleports_data
  .short global_states
  .short switch_statuses

