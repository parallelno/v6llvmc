/* v6c.ld - Default linker script for V6C (Vector-06c / i8080) targets.
 *
 * Used by clang's V6C driver as the default `-T` argument for ld.lld.
 * The user can override it with their own `-T script.ld`, or tweak
 * specific symbols with e.g. `-Wl,--defsym=__stack_top=0xF000`.
 *
 * Memory map:
 *   0x0000 .. 0x00FF  - reserved (V6C boot vector area)
 *   0x0100 ..         - .text, .rodata, .data, .bss in that order
 *   __stack_top = 0x0000 - first PUSH wraps SP to 0xFFFE (top of RAM)
 *
 * crt0 places `_start` in `.text._start`, and the KEEP clause below
 * pins it at 0x0100 regardless of link order.
 */

ENTRY(_start)

SECTIONS {
  . = 0x0100;
  .text   : { KEEP(*(.text._start)) *(.text*) }
  .rodata : { *(.rodata*) }
  .data   : { *(.data*) }
  . = ALIGN(1);
  __bss_start = .;
  .bss    : { *(.bss* COMMON) }
  __bss_end = .;
  __stack_top = 0x0000;
}
