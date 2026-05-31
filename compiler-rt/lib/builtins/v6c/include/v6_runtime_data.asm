	; This line is for proper formatting in VSCode
; TODO: write a script that generates this file

;===============================================================================
; For RAM memory usage check
;===============================================================================
RUNTIME_DATA	= $730D

;===============================================================================
; Hero Resources
;===============================================================================
; Defines the runtime values of all hero-owned resources.
; NOTE:
; - A maximum of 15 resources is supported.
; - `hero_res_sword` to `hero_res_spoon` are selectable resources shown in the UI.
; - Some resources are marked as quest-related.
; - Data must fit inside $100 block.

hero_resources:			= $730D
hero_res_score:			= hero_resources + 0  ; .word
hero_res_health:		= hero_resources + 2  ; .byte
hero_res_sword:			= hero_resources + 3  ; .byte (the first UI-selectable)
hero_res_snowflake:		= hero_resources + 4  ; .byte
hero_res_tnt:			= hero_resources + 5  ; .byte
hero_res_potion_health:	= hero_resources + 6  ; .byte
hero_res_popsicle_pie:	= hero_resources + 7  ; .byte
hero_res_laundry:		= hero_resources + 8  ; .byte (Quest resource)
hero_res_cabbage:		= hero_resources + 9  ; .byte (Quest resource)
hero_res_spoon:			= hero_resources + 10 ; .byte
hero_res_scarecrow:		= hero_resources + 11 ; .byte
hero_res_trap: 			= hero_resources + 12 ; .byte (Quest resource)
hero_res_not_used_03:	= hero_resources + 13 ; .byte
hero_res_not_used_04:	= hero_resources + 14 ; .byte
hero_res_not_used_06:	= hero_resources + 15 ; .byte
hero_res_end:			= hero_resources + 16 ; last resource + 1

; Currently selected resource low addr for use in the game UI.
;	NULL    - Indicates no resource selected.
game_ui_res_selected_ptr:	= hero_resources + 16 ; .byte
hero_resources_end:			= hero_resources + 17
HERO_RESOURCES_LEN = hero_resources_end - hero_resources

RES_SELECTABLE_FIRST	= hero_res_sword
RES_SELECTABLE_MAX		= hero_res_end - RES_SELECTABLE_FIRST

.if hero_resources>>8 != (hero_resources_end-1)>>8
	.error "ERROR: hero_resources must fit inside $100 block"
.endif


;===============================================================================
; OS I/O Data
;===============================================================================
;
; These variables are used to manage file operations and I/O interactions
; with the OS, including disk tracking and filename storage.

os_io_data:			= $731E
; the disk number to restore it before returning to the OS
; check RDS_DISK in os_consts.asm for more info

; Stores the current disk number used by the OS. Restore it before returning
; to the OS. See RDS_DISK in os_consts.asm for more info.
os_disk:			= os_io_data

; the last filename IO handled
; Stores the last filename accessed during I/O.
; Format:
;	.storage BASENAME_LEN
;	.byte "."
;	.storage EXT_LEN
;	.byte "\n$"
os_filename:		= os_disk + BYTE_LEN

OS_FILENAME_LEN_MAX = BASENAME_LEN + BYTE_LEN + EXT_LEN + WORD_LEN

; Points to the byte immediately after the loaded file.
os_file_data_ptr:	= os_filename + OS_FILENAME_LEN_MAX ; .word

os_io_data_end:		= os_file_data_ptr + WORD_LEN
OS_IO_DATA_LEN 		= os_io_data_end - os_io_data


;===============================================================================
; Switch Statuses:
;===============================================================================
; All statuses are stored in two bytes. Each bit represents the status of a
; specific switch. When the hero enters a room, any active switches trigger
; rendering of their associated decals.
;-------------------------------------------------------------------------------
; Data format:
;	.word	%UUUU_UNPB
;			where: N - NYAN CAT, P - POP CAT, B - BONGO CAT, U - unused
;-------------------------------------------------------------------------------
SWITCH_MASK_BONGO_CAT	= 0b0000_0001
SWITCH_MASK_POP_CAT		= 0b0000_0010
SWITCH_MASK_NYAN_CAT	= 0b0000_0100

switch_statuses:		= $732F
switch_statuses_end:	= switch_statuses + WORD_LEN
SWITCH_STATUSES_LEN = switch_statuses_end - switch_statuses

;===============================================================================
; Global Runtime States
;===============================================================================

global_states:			= $7331
; The current room idx within the current level
room_id:				= global_states ; .byte ; Range: [0, ROOMS_MAX-1]

; The index of the current level (must be located immediately after room_id)
level_id:				= global_states + 1 ; .byte

; Currently visible item in the game UI panel
; Value corresponds to item ID, range: [0, ITEMS_MAX-1]
game_ui_item_visible_addr:  = global_states + 2 ; .byte

border_color_idx:		= global_states + 3 ; .byte Current border color index
scr_offset_y:			= global_states + 4 ; .byte Vertical screen offset ($255 by default)

; Counts pending game updates to sync the game loop with interrupts.
; If < 0, no updates are pending.
; Incremented in the interruption routine.
; Checked and decremented in the game update.
game_updates_required:	= global_states + 5 ; .byte

; Temporary coordinates used during character movement logic:
char_temp_x:			= global_states + 6 ; .word
char_temp_y:			= global_states + 8 ; .word
global_states_end:		= global_states + 10
GLOBAL_STATES_LEN = global_states_end - global_states

;===============================================================================
; Characters Runtime Data
;===============================================================================
; Defines the per-instance runtime data for chars.
; NOTE:
; - A list of structs, one per char instance.
; - Accessed by the custom update and actor draw routines.
; - The char_update_ptr + 1 also serves as an Actor Runtime Status Code
;     (see actor_consts.asm).
; - CHAR_RUNTIME_DATA_LEN < $100.
; - Max active chars per room including dying but not dead: CHARS_MAX
; - The structure from char_update_ptr to char_data_next_ptr must match the
;     hero's runtime data structure for compatibility with shared functions.
; - The structure from char_update_ptr to char_speed_y must match the
;     overlay's runtime data structure for compatibility with shared functions.

CHARS_MAX = 15

; Base address for all char runtime data
chars_runtime_data:		= $733B
; A struct of a char runtime data.
char_update_ptr:		= chars_runtime_data + actor_update_ptr
char_draw_ptr:			= chars_runtime_data + actor_draw_ptr
char_status:			= chars_runtime_data + actor_status
char_status_timer:		= chars_runtime_data + actor_status_timer
char_anim_timer:		= chars_runtime_data + actor_anim_timer
char_anim_ptr:			= chars_runtime_data + actor_anim_ptr
char_erase_scr_addr:	= chars_runtime_data + actor_erase_scr_addr
char_erase_scr_addr_old:= chars_runtime_data + actor_erase_scr_addr_old
char_erase_wh:			= chars_runtime_data + actor_erase_wh
char_erase_wh_old:		= chars_runtime_data + actor_erase_wh_old
char_pos_x:				= chars_runtime_data + actor_pos_x
char_pos_y:				= chars_runtime_data + actor_pos_y
char_speed_x:			= chars_runtime_data + actor_speed_x
char_speed_y:			= chars_runtime_data + actor_speed_y
char_data_next_ptr:		= chars_runtime_data + 25 ; .word ; NULL if it's the last actor in the list
char_impacted_ptr:		= chars_runtime_data + 27 ; .word ; called by a hero, overlay, npc, etc. to affect this char
char_id:				= chars_runtime_data + 29 ; .byte
char_type:				= chars_runtime_data + 30 ; .byte
char_health:			= chars_runtime_data + 31 ; .byte ; Remaining health points
@data_end:				= chars_runtime_data + 32
CHAR_RUNTIME_DATA_LEN = @data_end - chars_runtime_data

chars_runtime_data_end_marker:	= chars_runtime_data + CHAR_RUNTIME_DATA_LEN * CHARS_MAX	; .word ACTOR_RUNTIME_DATA_END << 8
chars_runtime_data_end:			= chars_runtime_data_end_marker + ADDR_LEN
CHARS_RUNTIME_DATA_LEN			= chars_runtime_data_end - chars_runtime_data

.if CHAR_RUNTIME_DATA_LEN > $100
	.error "ERROR: CHAR_RUNTIME_DATA_LEN (" CHAR_RUNTIME_DATA_LEN ") > $100"
.endif

;===============================================================================
; Overlays Runtime Data
;===============================================================================
; Defines the per-instance runtime data for projectiles and VFX. Overlays are
; similar to chars but cannot receive impacts. However, they can impact chars.
; Overlays are not sorted by Y position and are rendered in an arbitrary order,
; always on top of all chars.
; NOTE:
; - A list of structs, one per overlay instance.
; - Accessed by the custom update and actor draw routines.
; - Data must fit inside $100 block.
; - Max active chars per room including dying but not dead: OVERLAYS_MAX.
; - The overlay_update_ptr + 1 also serves as an Actor Runtime Status Code
;     (see actor_consts.asm).
; - The structure from char_update_ptr to char_data_next_ptr must match the
;     hero's runtime data structure for compatibility with shared functions.
; - The structure from char_update_ptr to char_speed_y must match the
;     overlay's runtime data structure for compatibility with shared functions.

; Base address for all overlay runtime data
overlays_runtime_data:		= $751D
; A struct of a overlay runtime data.
overlay_update_ptr:			= overlays_runtime_data + actor_update_ptr
overlay_draw_ptr:			= overlays_runtime_data + actor_draw_ptr
overlay_status:				= overlays_runtime_data + actor_status
overlay_status_timer:		= overlays_runtime_data + actor_status_timer
overlay_anim_timer:			= overlays_runtime_data + actor_anim_timer
overlay_anim_ptr:			= overlays_runtime_data + actor_anim_ptr
overlay_erase_scr_addr:		= overlays_runtime_data + actor_erase_scr_addr
overlay_erase_scr_addr_old:	= overlays_runtime_data + actor_erase_scr_addr_old
overlay_erase_wh:			= overlays_runtime_data + actor_erase_wh
overlay_erase_wh_old:		= overlays_runtime_data + actor_erase_wh_old
overlay_pos_x:				= overlays_runtime_data + actor_pos_x
overlay_pos_y:				= overlays_runtime_data + actor_pos_y
overlay_speed_x:			= overlays_runtime_data + actor_speed_x
overlay_speed_y:			= overlays_runtime_data + actor_speed_y
@data_end:					= overlays_runtime_data + ACTOR_RUNTIME_DATA_LEN

OVERLAY_RUNTIME_DATA_LEN = @data_end - overlays_runtime_data
OVERLAYS_MAX = 9 ; max active overlays in the room

overlays_runtime_data_end_marker:	= overlays_runtime_data + OVERLAY_RUNTIME_DATA_LEN * OVERLAYS_MAX
overlays_runtime_data_end:			= overlays_runtime_data_end_marker + ADDR_LEN
OVERLAYS_RUNTIME_DATA_LEN			= overlays_runtime_data_end - overlays_runtime_data

.if overlays_runtime_data>>8 != (overlays_runtime_data_end - 1)>>8
	.error "ERROR: overlays_runtime_data must fit inside $100 block"
.endif

;===============================================================================
; Actor Runtime Data List
;===============================================================================
; - The list links the hero and non-dead chars runtime data together.
; - It's a singly-linked list with the head pointer actor_data_head_ptr.
; - The head points to the first actor runtime data (`hero_data_next_ptr` or
;     `char_data_next_ptr`), then the next, etc, ending with NULL.
; - Used to sort actors by Y position for correct rendering order.
; - One bubble sorting iteration per update.
; - The list is updated when chars are spawned or destroyed.

actor_data_head_ptr:	= $7600 ; .word

;===============================================================================
; Pointers to Current Level Data & Graphics
;===============================================================================
; This section holds data pointers to level-specific data such as rooms
; tiledata, resources, containers, the hero initial pose in the first room of
; the level, level, tile gparhics, and RAM-disk commands to access that data.
; NOTE:
; - Each level has its own set of level data. When the level is loaded, the
;     level data pointers and RAM-disk commands init this structire.

;------------------------------
; Level Data Table
;------------------------------
lv_data_init_tbl:				= $7602
lv_ram_disk_s_data:				= lv_data_init_tbl		; .byte RAM-disk command for Stack access
lv_ram_disk_m_data:				= lv_data_init_tbl + 1	; .byte RAM-disk command for Non-Stack access
lv_rooms_pptr:					= lv_data_init_tbl + 2	; .word Pointer to packed room data (tiledata + graphics tile idxs)
lv_resources_inst_data_pptr:	= lv_data_init_tbl + 4	; .word Pointer to resource instance data
lv_containers_inst_data_pptr:	= lv_data_init_tbl + 6	; .word Pointer to container instance data
lv_start_pos:					= lv_data_init_tbl + 8	; .word Hero start position (Y, X)
;------------------------------
; Graphics Init Table
;------------------------------
lv_gfx_init_tbl:				= lv_start_pos + WORD_LEN
lv_ram_disk_s_gfx:				= lv_gfx_init_tbl		; .byte RAM-disk command for Stack access
lv_ram_disk_m_gfx:				= lv_gfx_init_tbl + 1	; .byte RAM-disk command for Non-Stack access
lv_tiles_pptr:					= lv_gfx_init_tbl + 2	; .word Pointer to tile graphics data
@data_end:						= lv_gfx_init_tbl + 4
LEVEL_INIT_TBL_LEN = @data_end - lv_data_init_tbl

;===============================================================================
; Room Tiledata Backup
;===============================================================================
; A copy of the room tiledata. Used to restore the original tiledata after
; dialogs are displayed. Also used to preserve the state of breakable objects
; and restore the state of doors and containers.

ROOM_TILEDATA_BACKUP_LEN	= ROOM_WIDTH * ROOM_HEIGHT
room_tiledata_backup:		= $7610
room_tiledata_backup_end:	= room_tiledata_backup + ROOM_TILEDATA_BACKUP_LEN

;===============================================================================
; Temporary Buffer
;===============================================================================
; Usage:
; - unpacking tiled image index data
; - unpacking text data

TEMP_BUFF_LEN	= $200
temp_buff: 		= $7700

;===============================================================================
; Teleport Room IDs
;===============================================================================
; A table to convert teleport IDs to room IDs for the current room.
; NOTE:
; - When the hero steps on a teleport tile, the tiledata provides a teleport ID.
; - The teleport ID is used to look up the destination room ID in this table.
; - When a hero enters a room, the room's teleport data is copied from
;     the RAM-disk into this buffer.
;
;-------------------------------------------------------------------------------
; Data Layout:
;-------------------------------------------------------------------------------
; .byte - room_id for teleport_id = 0
; .byte - room_id for teleport_id = 1
; ...
; .byte - room_id for teleport_id = N
; Where N = TELEPORT_IDS_MAX - 1

; Defines the maximum number of unique teleport IDs per room.
TELEPORT_IDS_MAX = 16

room_teleports_data:		= $7900
room_teleports_data_end:	= room_teleports_data + TELEPORT_IDS_MAX
ROOM_TELEPORTS_DATA_LEN = room_teleports_data_end - room_teleports_data



;===============================================================================
; Game Statuses
;===============================================================================
; A collection of game state variables used to track progression, item usage,
; and trigger one-time events or dialogs.

GAME_STATUS_NOT_ACQUIRED	= 0
GAME_STATUS_ACQUIRED		= 1
GAME_STATUS_USED			= 2

game_status:					= $7910
game_status_cabbage_eaten:		= game_status		; Number of cabbages eaten
game_status_fire_extinguished:	= game_status + 1	; Number of fire walls extinguished
; To show "first-time use" dialogs
game_status_cabbage_healing:	= game_status + 2	; First time healing with cabbage
game_status_use_pie:			= game_status + 3	; First time using a pie
game_status_use_laundry:		= game_status + 4	; First time using clothes
game_status_use_spoon:			= game_status + 5	; First time using a spoon
game_status_first_freeze:		= game_status + 6	; First time freezing anyone
; Special states
game_status_fart:				= game_status + 7	; Fart status from cabbage
game_status_burner_quest_room:	= game_status + 8	; Index in burner_quest_room_ids array
game_status_mom:				= game_status + 9   ; Mom's status
	MOM_STATUS_FIRST_HI	= 0
	MOM_STATUS_HELP_BOB	= 1
	MOM_STATUS_CATCH_CATERPILLARS = 2
game_status_bob:				= game_status + 10
	BOB_STATUS_FIRST_HI			= 0
	BOB_STATUS_WAITING_SCARE	= 1
	BOB_STATUS_GOT_SCARECROW	= 2
	BOB_STATUS_SET_SCARECROW	= 3
	BOB_STATUS_HAPPY			= 4
game_status_used:				= game_status + 11 ; stores first usage of something
	TRAP_USED	= %0000_0001

game_status_reserved4:			= game_status + 12
game_status_reserved5:			= game_status + 13
game_status_reserved6:			= game_status + 14
game_status_reserved7:			= game_status + 15
game_status_end:				= game_status + 16
GAME_STATUS_LEN = game_status_end - game_status

;===============================================================================
; Room Tile Graphics Pointer Table
;===============================================================================
; Stores pointers to tile graphics used in the current room.
; NOTE:
; - When a hero enters a room, the room's data including tiledata and tile
;     graphics idxs are unpacked from the RAM-disk into this buffer and the
;     buffer above (room_tiles_gfx_ptrs & room_tiledata).
; - Room conststs of ROOM_WIDTH * ROOM_HEIGHT tiles. Each tile has its own
;     tiledata elements and tile graphics idx.
; - Tile graphics idx is used to render the tile.
;
;-------------------------------------------------------------------------------
; Data Layout:
;-------------------------------------------------------------------------------
; .loop ROOM_HEIGHT
;	.loop ROOM_WIDTH
;		.word - tile_gfx_addr
;	.endloop
; .endloop

ROOM_TILES_GFX_PTRS_LEN	= ROOM_WIDTH * ROOM_HEIGHT * ADDR_LEN
room_tiles_gfx_ptrs:		= $7920
room_tiles_gfx_ptrs_end:	= room_tiles_gfx_ptrs + ROOM_TILES_GFX_PTRS_LEN


;===============================================================================
; Room TileData Buffer
;===============================================================================
; Stores the tiledata for the current room.
; NOTE:
; - When a hero enters a room, the room's data including tiledata and tile
;     graphics idxs are unpacked from the RAM-disk into this buffer and the
;     buffer above (room_tiles_gfx_ptrs & room_tiledata).
; - Room conststs of ROOM_WIDTH * ROOM_HEIGHT tiles. Each tile has its own
;     tiledata elements and tile graphics idx.
; - Tiledata is used for collision detection, and game mechanics. Tiledata can
;     be a char, char spawner, container, door, and other interactive element.
;     See tiledata_consts.asm for all tiledata values.
; - Tiledata can be modified during gameplay, e.g. breakable objects, doors,
;     and containers can change their tiledata when broken/opened.
; - Tiledata is restored from the room_tiledata_backup buffer when dialogs
;     are displayed.
; - Data is $100-aligned and must fit inside $100 block.
;-------------------------------------------------------------------------------
; Data Layout:
;-------------------------------------------------------------------------------

; Data Layout:
; .loop ROOM_HEIGHT
;	.loop ROOM_WIDTH
;		.byte - tiledata
;	.endloop
; .endloop

ROOM_TILEDATA_LEN	= ROOM_WIDTH * ROOM_HEIGHT
room_tiledata:		= $7B00
room_tiledata_end:	= room_tiledata + ROOM_TILEDATA_LEN

.if room_tiledata>>8 != (room_tiledata_end-1)>>8
	.error "ERROR: room_tiledata must fit inside $100 block"
.endif

;===============================================================================
; Palette Data
;===============================================================================
; Holds the current color palette used by the game.
; Each color is one byte.
; Total length: 16 bytes.
palette: = $7BF0

;===============================================================================
; Container Instance Status Data
;===============================================================================
; Stores the status of all container instances in the current level.
;
; NOTE:
; - The data is divided into two sections:
;
;   1. Pointer Table:
;      - A list of low-byte pointers, one for each possible container_id.
;      - Each pointer points to the instance data for that container_id.
;      - If a container_id is unused in the level but higher IDs are used,
;        its pointer is set to NULL.
;
;   2. Instance Data Section:
;      - Contains pairs of tile_idx and room_id for each container instance.
;      - Each pair specifies the location of a container in the level.
;      - The room_id also encodes the container’s status:
;          * room_id ∈ [0, ROOMS_MAX-1] - container is present in that room.
;          * room_id = CONTAINERS_STATUS_ACQUIRED - container is acquired.
;
; - Data is $100-aligned and must fit inside $100 block.

;-------------------------------------------------------------------------------
; Data format:
;-------------------------------------------------------------------------------
; containers_inst_data_ptrs:
;   .byte [ptr to the instance data for first container_id used in the level]
;   .byte [... second container_id ...]
;   ...
;   .byte [... N-th container_id ...]
;   .byte [ptr to the addr immediately after the last instance data]
;   Where N = CONTAINER_UNIQUE_IDS - 1
;
; containers_inst_data:
;   - For each container_id listed above:
;     container_id_inst_data:
;	  	// instance data for first container_id used in the level
;       .byte [first tile_idx]
;       .byte [first room_id]
;       .byte [second tile_idx]
;       .byte [second room_id]
;       ...
;       .byte [M-th tile_idx]
;       .byte [M-th room_id]
;	    // instance data for second container_id used in the level
;       .byte [first tile_idx]
;       .byte [first room_id]
;       ...
;-------------------------------------------------------------------------------

CONTAINERS_UNIQUE_MAX			= 16
CONTAINERS_INST_DATA_PTRS_LEN	= $100
CONTAINERS_STATUS_ACQUIRED		= $ff

containers_inst_data_ptrs:	= $7C00
;containers_inst_data:		= containers_inst_data_ptrs + used_unique_containers (can vary) + 1
containers_inst_data_ptrs_end: = containers_inst_data_ptrs + CONTAINERS_INST_DATA_PTRS_LEN

.if containers_inst_data_ptrs>>8 != (containers_inst_data_ptrs_end-1)>>8
	.error "ERROR: containers_inst_data_ptrs must fit inside $100 block"
.endif

;===============================================================================
; Resource Instance Status Data
;===============================================================================
; Status data for resource instances in the level.
; NOTE:
; - It uses the Container Instance Status Data format.
; - Data is $100-aligned and must fit inside $100 block.

RESOURCES_UNIQUE_MAX			= 16
RESOURCES_INST_DATA_PTRS_LEN	= $100
RESOURCES_STATUS_ACQUIRED		= $ff

resources_inst_data_ptrs:	= $7D00
;resources_inst_data:		= resources_inst_data_ptrs + used_unique_resources (can vary) + 1
resources_inst_data_ptrs_end: = resources_inst_data_ptrs + RESOURCES_INST_DATA_PTRS_LEN

.if resources_inst_data_ptrs>>8 != (resources_inst_data_ptrs_end-1)>>8
	.error "ERROR: resources_inst_data_ptrs must fit inside $100 block"
.endif

;===============================================================================
; Breakables
;===============================================================================
; This section manages the statuses of breakable objects (crates, barrels, etc.)
; NOTE:
; - Supports up to 1016 breakables, 127 rooms, and two levels max.
; - Each room may contain a variable number of breakables.
; - Must be reset at game start.
; - When a player enters a room with breakables the first time,
;     breakables_status_buf_free_ptr is used to allocate a buffer for that room.
;     If the room has been visited before, the existing buffer is reused to store
;     the updated breakables' statuses.
; - Data is $100-aligned and must fit inside $100 block.
;
;-------------------------------------------------------------------------------
; Data Layout:
;-------------------------------------------------------------------------------
; breakables_status_buf_free_ptr:
;   - Points to the next available byte in breakables_status_bufs.
; breakables_status_buf_ptrs:
;   - Contains low-byte ptr from breakables_status_bufs for each room/level.
;   - Order:
;       .byte ptr to [room_0 in level_0]
;       ...			 [room_1 in level_0]
;       ...
;       ...			 [room_N in level_0]
;       ...			 [room_0 in level_1]
;       ...			 [room_1 in level_1]
;       ...
;       ...			 [room_N in level_M]
;   - Total entries: ROOMS_MAX * LEVELS_MAX
;
; breakables_status_bufs:
;   - Contains status for rooms that have been visited and contain breakables.
;   - Each byte holds the status of 8 breakables.
;   - Each bit represents a breakable's status: 0 - not broken, 1 - broken.
;   - Example: 9 breakables in a room with tile_id=A, B, C, J, K, O, P, X, Z.
;     Their statuses will be packed into two bytes:
;       .byte %IGFEDCBA
;       .byte %0000000J

BREAKABLES_ROOMS_PER_BYTE	= 8
BREAKABLES_ROOMS			= 128 ; max rooms that can have breakables
BREAKABLES_STATUS_BUF_LEN	= $100
BREAKABLES_MAX				= 1016
; 	1016 = (BREAKABLES_STATUS_BUF_LEN - 1 - BREAKABLES_ROOMS) * BREAKABLES_ROOMS_PER_BYTE
;	"-1" because breakables_status_buf_free_ptr takes one byte

breakables_status_buf_free_ptr:	= $7E00
breakables_status_buf_ptrs:		= breakables_status_buf_free_ptr + 1
breakables_status_bufs:			= breakables_status_buf_ptrs + BREAKABLES_ROOMS
breakables_status_buffs_end:	= breakables_status_buf_free_ptr + BREAKABLES_STATUS_BUF_LEN

.if LV0_BREAKABLES + LV1_BREAKABLES > BREAKABLES_MAX
	.error "ERROR: breakables in all levels: " LV0_BREAKABLES + LV1_BREAKABLES ". It exeeds BREAKABLES_MAX (" BREAKABLES_MAX ")"
.endif
.if breakables_status_buf_free_ptr>>8 != (breakables_status_buffs_end-1)>>8
	.error "ERROR: breakables_status_buf_free_ptr must fit inside $100 block"
.endif


;===============================================================================
; Back Runtime Data
;===============================================================================
; Stores per-instance runtime data for animated background tiles ("backs").
; NOTE:
; - A list of structs, one per back instance.
; - The back_anim_ptr + 1 also serves as an Actor Runtime States (see actor_consts.asm).
; - Data must fit inside $100 block.

; Base address for all back runtime data
backs_runtime_data:		= $7F00
; A struct of back runtime data.
back_anim_ptr:			= backs_runtime_data + 0	;.word TEMP_ADDR
back_scr_addr:			= backs_runtime_data + 2	;.word TEMP_WORD
back_anim_timer:		= backs_runtime_data + 4	;.byte TEMP_BYTE
back_anim_timer_speed:	= backs_runtime_data + 5	;.byte TEMP_BYTE
@data_end:				= backs_runtime_data + 6

BACK_RUNTIME_DATA_LEN = @data_end - backs_runtime_data
BACKS_MAX = 10

backs_runtime_data_end_marker:	= backs_runtime_data + BACK_RUNTIME_DATA_LEN * BACKS_MAX
backs_runtime_data_end:			= backs_runtime_data_end_marker + WORD_LEN
BACKS_RUNTIME_DATA_LEN = backs_runtime_data_end - backs_runtime_data

.if backs_runtime_data>>8 != (backs_runtime_data_end - 1)>>8
	.error "ERROR: backs_runtime_data must fit inside $100 block"
.endif

;===============================================================================
; Hero Runtime Data
;===============================================================================
; Contains all runtime state for the hero actor.
; NOTE:
; - Accessed by the custom update and actor draw routines.
; - The structure from hero_update_ptr to hero_data_next_ptr must match the
;     char's runtime data structure for compatibility with shared functions.
; - The hero_update_ptr + 1 also serves as an Actor Runtime Status Code
;     (see actor_consts.asm).

; Base address for hero runtime data
hero_runtime_data:			= $7F3E
; A struct of the hero runtime data.
hero_update_ptr:			= hero_runtime_data + actor_update_ptr
hero_draw_ptr:				= hero_runtime_data + actor_draw_ptr
hero_status:				= hero_runtime_data + actor_status
hero_status_timer:			= hero_runtime_data + actor_status_timer
hero_anim_timer:			= hero_runtime_data + actor_anim_timer
hero_anim_ptr:				= hero_runtime_data + actor_anim_ptr
hero_erase_scr_addr:		= hero_runtime_data + actor_erase_scr_addr
hero_erase_scr_addr_old:	= hero_runtime_data + actor_erase_scr_addr_old
hero_erase_wh:				= hero_runtime_data + actor_erase_wh
hero_erase_wh_old:			= hero_runtime_data + actor_erase_wh_old
hero_pos_x:					= hero_runtime_data + actor_pos_x
hero_pos_y:					= hero_runtime_data + actor_pos_y
hero_speed_x:				= hero_runtime_data + actor_speed_x
hero_speed_y:				= hero_runtime_data + actor_speed_y
hero_data_next_ptr:			= hero_runtime_data + 25 ; .word ; points to the next actor in the actor_data_head_ptr list for sorting
hero_impacted_ptr:			= hero_runtime_data + 27 ; .word ; called by a char, npc, overlay, etc. to affect the hero
hero_dir:					= hero_runtime_data + 29 ; .byte ; direction flag:
; format: %0000_0VDHD,
;	V - vertical movement (0 - disabled, 1 - enabled)
;	H - horizontal movement (0 - disabled, 1 - enabled)
;	D - direction (0 - left/down, 1 - right/up)
hero_type:					= hero_runtime_data + 30 ; .byte ; actor type (e.g. CHAR_TYPE_ALLY)
hero_runtime_data_end:		= hero_runtime_data + 31
HERO_RUNTIME_DATA_LEN = hero_runtime_data_end - hero_runtime_data


;===============================================================================
; Room Spawn Rates
;===============================================================================
; Defines char spawn rates for each room in the level.
; NOTE:
; - Each byte represents the spawn rate for one room (indexed by room_id).
; - Value meaning:
;     0   → 100% spawn chance (always spawn)
;     255 → 0% spawn chance (never spawn)
; - Data must fit inside $100 block.
;
;-------------------------------------------------------------------------------
; Data format:
;-------------------------------------------------------------------------------
; rooms_spawn_rate:
;   .byte [spawn rate room_id = 0]
;   .byte [... room_id = 1]
;   ...
;   .byte [... room_id = ROOMS_MAX-1]
;-------------------------------------------------------------------------------

rooms_spawn_rate:		= $7F5D
rooms_spawn_rate_end:	= rooms_spawn_rate + ROOMS_MAX
ROOMS_SPAWN_RATE_LEN = rooms_spawn_rate_end - rooms_spawn_rate

.if rooms_spawn_rate>>8 != (rooms_spawn_rate_end - 1)>>8
	.error "ERROR: rooms_spawn_rate must fit inside $100 block"
.endif

;===============================================================================
; Global Item Statuses
;===============================================================================
; Tracks the acquisition and usage status of each global items in the game.
; NOTE:
; - A maximum of 15 unique items is supported.
; - Item IDs correspond to tiledata indexes (see tiledata_consts.asm).
; - Item ID 0 is reserved for dialog-related tiledata. Not an actual item.
; - Each item can have one of three statuses:
ITEM_STATUS_NOT_ACQUIRED = 0  ; Item has not been obtained
ITEM_STATUS_ACQUIRED     = 1  ; Item is acquired but not yet used
ITEM_STATUS_USED         = 2  ; Item has been used

ITEMS_MAX				= 15
;-------------------------------------------------------------------------------
; Data Layout:
;-------------------------------------------------------------------------------
; .byte - status of item_id = 0 (reserved for dialog-related tiledata)
; .byte - status of item_id = 1
; .byte - status of item_id = 2
; ...
; .byte - status of item_id = ITEMS_MAX-1

global_items:		= $7F9D
global_items_end:	= global_items + ITEMS_MAX
GLOBAL_ITEMS_END = global_items_end - global_items

;===============================================================================
; RAM Disk Mode
;===============================================================================
; Stores the current RAM-disk mode.
; Used by the interrupt routine to restore the mode after execution.
ram_disk_mode:              = $7FAC ; BYTE_LEN

;===============================================================================
RUNTIME_DATA_END = $7FAC
;===============================================================================

; validation
.if RUNTIME_DATA_END > STACK_MIN_ADDR
	.error "RUNTIME_DATA_END (" RUNTIME_DATA_END ") > STACK_MIN_ADDR (" STACK_MIN_ADDR ")"
.endif


.if (char_update_ptr - chars_runtime_data) != (hero_update_ptr - hero_runtime_data)
	.error "hero & char runtime data must match from update_ptr to chars_runtime_data"
.endif
.if (char_update_ptr - chars_runtime_data) != (overlay_update_ptr - overlays_runtime_data)
	.error "hero & char & overlay runtime data must match from update_ptr to speed_y + 1"
.endif

.if (char_draw_ptr - chars_runtime_data) != (hero_draw_ptr - hero_runtime_data)
	.error "hero & char runtime data must match from update_ptr to chars_runtime_data"
.endif
.if (char_draw_ptr - chars_runtime_data) != (overlay_draw_ptr - overlays_runtime_data)
	.error "hero & char & overlay runtime data must match from update_ptr to speed_y + 1"
.endif

.if (char_status - chars_runtime_data) != (hero_status - hero_runtime_data)
	.error "hero & char runtime data must match from update_ptr to chars_runtime_data"
.endif
.if (char_status - chars_runtime_data) != (overlay_status - overlays_runtime_data)
	.error "hero & char & overlay runtime data must match from update_ptr to speed_y + 1"
.endif

.if (char_status_timer - chars_runtime_data) != (hero_status_timer - hero_runtime_data)
	.error "hero & char runtime data must match from update_ptr to chars_runtime_data"
.endif
.if (char_status_timer - chars_runtime_data) != (overlay_status_timer - overlays_runtime_data)
	.error "hero & char & overlay runtime data must match from update_ptr to speed_y + 1"
.endif

.if (char_anim_timer - chars_runtime_data) != (hero_anim_timer - hero_runtime_data)
	.error "hero & char runtime data must match from update_ptr to chars_runtime_data"
.endif
.if (char_anim_timer - chars_runtime_data) != (overlay_anim_timer - overlays_runtime_data)
	.error "hero & char & overlay runtime data must match from update_ptr to speed_y + 1"
.endif

.if (char_anim_ptr - chars_runtime_data) != (hero_anim_ptr - hero_runtime_data)
	.error "hero & char runtime data must match from update_ptr to chars_runtime_data"
.endif
.if (char_anim_ptr - chars_runtime_data) != (overlay_anim_ptr - overlays_runtime_data)
	.error "hero & char & overlay runtime data must match from update_ptr to speed_y + 1"
.endif

.if (char_erase_scr_addr - chars_runtime_data) != (hero_erase_scr_addr - hero_runtime_data)
	.error "hero & char runtime data must match from update_ptr to chars_runtime_data"
.endif
.if (char_erase_scr_addr - chars_runtime_data) != (overlay_erase_scr_addr - overlays_runtime_data)
	.error "hero & char & overlay runtime data must match from update_ptr to speed_y + 1"
.endif

.if (char_erase_scr_addr_old - chars_runtime_data) != (hero_erase_scr_addr_old - hero_runtime_data)
	.error "hero & char runtime data must match from update_ptr to chars_runtime_data"
.endif
.if (char_erase_scr_addr_old - chars_runtime_data) != (overlay_erase_scr_addr_old - overlays_runtime_data)
	.error "hero & char & overlay runtime data must match from update_ptr to speed_y + 1"
.endif

.if (char_erase_wh - chars_runtime_data) != (hero_erase_wh - hero_runtime_data)
	.error "hero & char runtime data must match from update_ptr to chars_runtime_data"
.endif
.if (char_erase_wh - chars_runtime_data) != (overlay_erase_wh - overlays_runtime_data)
	.error "hero & char & overlay runtime data must match from update_ptr to speed_y + 1"
.endif

.if (char_erase_wh_old - chars_runtime_data) != (hero_erase_wh_old - hero_runtime_data)
	.error "hero & char runtime data must match from update_ptr to chars_runtime_data"
.endif
.if (char_erase_wh_old - chars_runtime_data) != (overlay_erase_wh_old - overlays_runtime_data)
	.error "hero & char & overlay runtime data must match from update_ptr to speed_y + 1"
.endif

.if (char_pos_x - chars_runtime_data) != (hero_pos_x - hero_runtime_data)
	.error "hero & char runtime data must match from update_ptr to chars_runtime_data"
.endif
.if (char_pos_x - chars_runtime_data) != (overlay_pos_x - overlays_runtime_data)
	.error "hero & char & overlay runtime data must match from update_ptr to speed_y + 1"
.endif

.if (char_pos_y - chars_runtime_data) != (hero_pos_y - hero_runtime_data)
	.error "hero & char runtime data must match from update_ptr to chars_runtime_data"
.endif
.if (char_pos_y - chars_runtime_data) != (overlay_pos_y - overlays_runtime_data)
	.error "hero & char & overlay runtime data must match from update_ptr to speed_y + 1"
.endif

.if (char_speed_x - chars_runtime_data) != (hero_speed_x - hero_runtime_data)
	.error "hero & char runtime data must match from update_ptr to chars_runtime_data"
.endif
.if (char_speed_x - chars_runtime_data) != (overlay_speed_x - overlays_runtime_data)
	.error "hero & char & overlay runtime data must match from update_ptr to speed_y + 1"
.endif

.if (char_speed_y - chars_runtime_data) != (hero_speed_y - hero_runtime_data)
	.error "hero & char runtime data must match from update_ptr to chars_runtime_data"
.endif
.if (char_speed_y - chars_runtime_data) != (overlay_speed_y - overlays_runtime_data)
	.error "hero & char & overlay runtime data must match from update_ptr to speed_y + 1"
.endif

.if (char_data_next_ptr - chars_runtime_data) != (hero_data_next_ptr - hero_runtime_data)
	.error "hero & char runtime data must match from update_ptr to chars_runtime_data"
.endif
