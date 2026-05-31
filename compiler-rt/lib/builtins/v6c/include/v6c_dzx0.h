/*===---- v6c_dxz0.h - ZX0 data decompressor for the V6C i8080 target ----===
 *
 * ZX0 8080 decoder by Ivan Gorodetsky - OLD FILE FORMAT v1
 * Based on ZX0 z80 decoder by Einar Saukas
 *   https://github.com/einar-saukas/ZX0
 *
 * Compressor: salvador by emmanuel-marty
 *   https://github.com/emmanuel-marty/salvador
 *   forward:  salvador -c   <input> <output>
 *   backward: salvador -b -c <input> <output>
 *
 * Functions
 * ---------
 *   dzx0     — Decompress ZX0-compressed data to flat RAM.
 *              V6C CC: HL = src (compressed), DE = dst (decompressed output)
 *
 *   dzx0_rd  — Decompress ZX0-compressed data to RAM Disk ($8000–$FFFF).
 *              Uses self-modifying code to patch the RAM Disk activation
 *              command and the intermediate store byte into MVI immediates
 *              at runtime.
 *              V6C CC: HL = src (compressed), DE = dst, A = bank cmd
 *
 * Linkage strategy
 * ----------------
 * Same as v6c_arith.h: V6C_RT = static naked noinline used v6c_rt_helper.
 * --gc-sections prunes unused copies at link time.
 *
 * Calling convention (V6C CC)
 * ---------------------------
 *   i16 arg1 → HL  ;  i16 arg2 → DE  ;  i8 arg3 → A
 * Both routines remap registers in their prologues so the algorithm
 * body can use DE = src and BC = dst as the original code expects.
 *
 * RAM Disk macros (dzx0_rd only)
 * -------------------------------
 * RAM_DISK_ON_BANK_NO_RESTORE() and RAM_DISK_OFF_NO_RESTORE() come from
 * v6c_macros.h.  Override them before including this header if your
 * hardware uses a different port:
 *
 *   #define RAM_DISK_ON_BANK_NO_RESTORE()  "out 0x20 \n\t"
 *   #define RAM_DISK_OFF_NO_RESTORE()      "xra a \n\t" "out 0x20 \n\t"
 *   #include "v6c_dzx0.h"
 *
 *===-----------------------------------------------------------------------===
 */

#ifndef __V6C_V6C_DXZ0_H
#define __V6C_V6C_DXZ0_H

#ifndef __V6C__
#error "<v6c_dxz0.h> is only valid for the V6C target"
#endif

#include <stdint.h>
#include "v6c_rt_macros.h"
#include "v6c_macros.h"

/* ------------------------------------------------------------------
 * dzx0 — Decompress ZX0-compressed data to flat RAM.
 *
 * Inputs  (V6C CC):
 *   HL = src  — pointer to compressed data
 *   DE = dst  — pointer to decompressed output buffer
 *
 * Output:
 *   Decompressed bytes written to [dst …).
 *   Returns (via RZ) when the end-of-stream marker is reached.
 *
 * Clobbers: A, B, C, D, E, H, L, FLAGS (all registers)
 * ------------------------------------------------------------------ */
V6C_RT void dzx0(uint8_t* src, uint8_t* dst) {
    __asm__ volatile (
        /* -- CC remapping: HL=src, DE=dst  →  DE=src, BC=dst ---------- */
        "XCHG                           \n\t"   /* HL=dst,  DE=src      */
        "MOV  B, H                      \n\t"   /* BC=dst               */
        "MOV  C, L                      \n\t"

        /* -- algorithm ------------------------------------------------- */
        "LXI  H, 0xFFFF                 \n\t"
        "PUSH H                         \n\t"
        "INX  H                         \n\t"
        "MVI  A, 0x80                   \n"

        "Ldxz0_literals%=:              \n\t"
        "CALL Ldxz0_elias%=             \n\t"
        "CALL Ldxz0_ldir%=              \n\t"
        "JC   Ldxz0_new_offset%=        \n\t"
        "CALL Ldxz0_elias%=             \n"

        "Ldxz0_copy%=:                  \n\t"
        "XCHG                           \n\t"
        "XTHL                           \n\t"
        "PUSH H                         \n\t"
        "DAD  B                         \n\t"
        "XCHG                           \n\t"
        "CALL Ldxz0_ldir%=              \n\t"
        "XCHG                           \n\t"
        "POP  H                         \n\t"
        "XTHL                           \n\t"
        "XCHG                           \n\t"
        "JNC  Ldxz0_literals%=          \n"

        "Ldxz0_new_offset%=:            \n\t"
        "CALL Ldxz0_elias%=             \n\t"
        "MOV  H, A                      \n\t"
        "POP  PSW                       \n\t"
        "XRA  A                         \n\t"
        "SUB  L                         \n\t"
        "RZ                             \n\t"   /* end of stream → return */
        "PUSH H                         \n\t"
        "RAR                            \n\t"
        "MOV  H, A                      \n\t"
        "LDAX D                         \n\t"
        "RAR                            \n\t"
        "MOV  L, A                      \n\t"
        "INX  D                         \n\t"
        "XTHL                           \n\t"
        "MOV  A, H                      \n\t"
        "LXI  H, 1                      \n\t"
        "CNC  Ldxz0_elias_backtrack%=   \n\t"
        "INX  H                         \n\t"
        "JMP  Ldxz0_copy%=              \n"

        /* -- @elias subroutine ----------------------------------------- */
        "Ldxz0_elias%=:                 \n\t"
        "INR  L                         \n"
        "Ldxz0_elias_loop%=:            \n\t"
        "ADD  A                         \n\t"
        "JNZ  Ldxz0_elias_skip%=        \n\t"
        "LDAX D                         \n\t"
        "INX  D                         \n\t"
        "RAL                            \n"
        "Ldxz0_elias_skip%=:            \n\t"
        "RC                             \n"
        "Ldxz0_elias_backtrack%=:       \n\t"
        "DAD  H                         \n\t"
        "ADD  A                         \n\t"
        "JNC  Ldxz0_elias_loop%=        \n\t"
        "JMP  Ldxz0_elias%=             \n"

        /* -- @ldir_ subroutine ----------------------------------------- */
        "Ldxz0_ldir%=:                  \n\t"
        "PUSH PSW                       \n"
        "Ldxz0_ldir1%=:                 \n\t"
        "LDAX D                         \n\t"
        "STAX B                         \n\t"
        "INX  D                         \n\t"
        "INX  B                         \n\t"
        "DCX  H                         \n\t"
        "MOV  A, H                      \n\t"
        "ORA  L                         \n\t"
        "JNZ  Ldxz0_ldir1%=             \n\t"
        "POP  PSW                       \n\t"
        "ADD  A                         \n\t"
        "RET                            \n\t"
    );
}

/* ------------------------------------------------------------------
 * dzx0_rd — Decompress ZX0-compressed data to RAM Disk ($8000–$FFFF).
 *
 * Uses self-modifying code: the RAM Disk activation command and the
 * intermediate store byte are patched into MVI immediates at runtime
 * via STA <label>+1.
 *
 * Inputs  (V6C CC):
 *   HL = src  — pointer to compressed data in main RAM
 *   DE = dst  — destination address inside the RAM Disk window
 *   A  = cmd  — RAM Disk bank-activation command (sent to the port)
 *
 * Output:
 *   Decompressed bytes written to [dst …) in RAM Disk space.
 *   Returns (via RZ) when the end-of-stream marker is reached.
 *
 * Clobbers: A, B, C, D, E, H, L, FLAGS (all registers)
 *
 * Note: RAM_DISK_ON_BANK_NO_RESTORE and RAM_DISK_OFF_NO_RESTORE are
 * provided by v6c_macros.h (included above).  Override before including
 * this header if your hardware uses a different port.
 * ------------------------------------------------------------------ */
V6C_RT void dzx0_rd(uint8_t* src, uint8_t* dst, uint8_t cmd) {
    __asm__ volatile (
        /* -- CC remapping: HL=src, DE=dst, A=cmd  →  DE=src, BC=dst, A=cmd */
        "XCHG                               \n\t"   /* HL=dst, DE=src; A unchanged */
        "MOV  B, H                          \n\t"   /* BC=dst                      */
        "MOV  C, L                          \n\t"

        /* -- algorithm ------------------------------------------------- */
        /* Patch cmd into the two MVI A immediates used for RAM Disk ON.   */
        "STA  Ldxz0rd_ramDiskCmd1%=+1       \n\t"
        "STA  Ldxz0rd_ramDiskCmd2%=+1       \n\t"
        "LXI  H, 0xFFFF                     \n\t"
        "PUSH H                             \n\t"
        "INX  H                             \n\t"
        "MVI  A, 0x80                       \n"

        "Ldxz0rd_literals%=:                \n\t"
        "CALL Ldxz0rd_elias%=               \n"

        /* -- ldir: copy from compressed stream to dst (in RAM Disk) ---- */
        "Ldxz0rd_ldir%=:                    \n\t"
        "STA  Ldxz0rd_restoreA1%=+1         \n"     /* save A before loop */
        "Ldxz0rd_ldir_loop%=:               \n\t"
        "LDAX D                             \n\t"   /* A = *src++          */
        "STA  Ldxz0rd_storeA%=+1            \n\t"   /* patch store byte    */
        /* turn on the RAM Disk (cmd already patched into MVI A below) */
        "Ldxz0rd_ramDiskCmd1%=:             \n\t"
        "MVI  A, 0                          \n\t"   /* immediate patched at runtime */
        RAM_DISK_ON_BANK_NO_RESTORE()
        "Ldxz0rd_storeA%=:                  \n\t"
        "MVI  A, 0                          \n\t"   /* immediate patched at runtime */
        "STAX B                             \n\t"   /* *dst++ = byte       */
        RAM_DISK_OFF_NO_RESTORE()
        "INX  D                             \n\t"
        "INX  B                             \n\t"
        "DCX  H                             \n\t"
        "MOV  A, H                          \n\t"
        "ORA  L                             \n\t"
        "JNZ  Ldxz0rd_ldir_loop%=           \n"
        "Ldxz0rd_restoreA1%=:               \n\t"
        "MVI  A, 0                          \n\t"   /* immediate patched at runtime */
        "ADD  A                             \n\t"
        "JC   Ldxz0rd_new_offset%=          \n\t"
        "CALL Ldxz0rd_elias%=               \n"

        /* -- copy: copy from already-decompressed RAM Disk data --------- */
        "Ldxz0rd_copy%=:                    \n\t"
        "XCHG                               \n\t"
        "XTHL                               \n\t"
        "PUSH H                             \n\t"
        "DAD  B                             \n\t"
        "XCHG                               \n"

        /* -- ldir_unpacked: copy within the RAM Disk window ------------- */
        "Ldxz0rd_ldir_unpacked%=:           \n\t"
        "STA  Ldxz0rd_restoreA2%=+1         \n\t"   /* save A before loop */
        /* turn on the RAM Disk */
        "Ldxz0rd_ramDiskCmd2%=:             \n\t"
        "MVI  A, 0                          \n\t"   /* immediate patched at runtime */
        RAM_DISK_ON_BANK_NO_RESTORE()
        "Ldxz0rd_ldirUnpackedLoop%=:        \n\t"
        "LDAX D                             \n\t"
        "STAX B                             \n\t"
        "INX  D                             \n\t"
        "INX  B                             \n\t"
        "DCX  H                             \n\t"
        "MOV  A, H                          \n\t"
        "ORA  L                             \n\t"
        "JNZ  Ldxz0rd_ldirUnpackedLoop%=    \n\t"
        RAM_DISK_OFF_NO_RESTORE()
        "Ldxz0rd_restoreA2%=:               \n\t"
        "MVI  A, 0                          \n\t"   /* immediate patched at runtime */
        "ADD  A                             \n\t"
        "XCHG                               \n\t"
        "POP  H                             \n\t"
        "XTHL                               \n\t"
        "XCHG                               \n\t"
        "JNC  Ldxz0rd_literals%=            \n"

        "Ldxz0rd_new_offset%=:              \n\t"
        "CALL Ldxz0rd_elias%=               \n\t"
        "MOV  H, A                          \n\t"
        "POP  PSW                           \n\t"
        "XRA  A                             \n\t"
        "SUB  L                             \n\t"
        "RZ                                 \n\t"   /* end of stream → return */
        "PUSH H                             \n\t"
        "RAR                                \n\t"
        "MOV  H, A                          \n\t"
        "LDAX D                             \n\t"
        "RAR                                \n\t"
        "MOV  L, A                          \n\t"
        "INX  D                             \n\t"
        "XTHL                               \n\t"
        "MOV  A, H                          \n\t"
        "LXI  H, 1                          \n\t"
        "CNC  Ldxz0rd_elias_backtrack%=     \n\t"
        "INX  H                             \n\t"
        "JMP  Ldxz0rd_copy%=                \n"

        /* -- @elias subroutine ----------------------------------------- */
        "Ldxz0rd_elias%=:                   \n\t"
        "INR  L                             \n"
        "Ldxz0rd_elias_loop%=:              \n\t"
        "ADD  A                             \n\t"
        "JNZ  Ldxz0rd_elias_skip%=          \n\t"
        "LDAX D                             \n\t"
        "INX  D                             \n\t"
        "RAL                                \n"
        "Ldxz0rd_elias_skip%=:              \n\t"
        "RC                                 \n"
        "Ldxz0rd_elias_backtrack%=:         \n\t"
        "DAD  H                             \n\t"
        "ADD  A                             \n\t"
        "JNC  Ldxz0rd_elias_loop%=          \n\t"
        "JMP  Ldxz0rd_elias%=               \n\t"
    );
}

#undef V6C_RT
#endif /* __V6C_V6C_DXZ0_H */
