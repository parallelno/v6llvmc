/*===---- v6c_os_consts.h - RDS/CP/M OS constants for the V6C target ------===
 *
 * System call numbers, addresses, and file I/O constants for the RDS OS
 * (based on CP/M 2.2 and MicroDos 3).  Translated from v6_os_consts.asm.
 *
 * References:
 *   https://github.com/ImproverX/RDS/blob/master/manuals/rds-rpro.txt
 *   https://www.seasip.info/Cpm/bdos.html
 *   https://www.seasip.info/Cpm/fcb.html
 *   http://www.cpm.z80.de/manuals/cpm22-m.pdf
 *
 *===----------------------------------------------------------------------===
 */

#ifndef __V6C_V6C_OS_CONSTS_H
#define __V6C_V6C_OS_CONSTS_H

#ifndef __V6C__
#error "<v6c_os_consts.h> is only valid for the V6C target"
#endif

#include <stdint.h>

/* =======================================================
 * CP/M BDOS function numbers
 * ======================================================= */
#define CPM_SUB_PRINT       9u      /* Print a '$'-terminated string */
#define CPM_SUB_F_DMAOFF    26u     /* Set custom I/O file buffer address (128 bytes) */
#define CPM_SUB_F_OPEN      15u     /* Open file */
#define CPM_SUB_F_READ      20u     /* Read file sequentially */
#define CPM_SUB_F_WRITE     21u     /* Write file sequentially */
#define CPM_SUB_F_CLOSE     16u     /* Close file */
#define CPM_SUB_F_MAKE      22u     /* Create file */
#define CPM_SUB_F_DELETE    19u     /* Delete file */
#define CPM_SUB_F_SFIRST    17u     /* Search for first matching file */
#define CPM_SUB_DRV_GET     25u     /* Get current drive */
#define CPM_SUB_DRV_SET     14u     /* Set current drive */

/* =======================================================
 * CP/M system addresses
 * ======================================================= */
#define CPM_BDOS            0x0005u /* BDOS entry point (call here) */
#define CPM_EXIT            0x0000u /* Warm-boot / exit to OS */

#define CPM_FCB             0x005Cu /* Default File Control Block */
#define FILE_NAME_ADDR      (CPM_FCB + 1u)
#define CPM_DMA_BUFFER      0x0080u /* Default DMA buffer */
#define CPM_DMA_BUFFER_LEN  128u    /* DMA buffer size in bytes */
#define CPM_FCB_LEN         (CPM_DMA_BUFFER - CPM_FCB) /* 36 bytes */

#define BASENAME_LEN        8u      /* 8-character base file name */
#define EXT_LEN             3u      /* 3-character extension */
#define FILENAME_LEN        (BASENAME_LEN + EXT_LEN)

/* =======================================================
 * CP/M BDOS return codes
 * ======================================================= */
#define CPM_MSG_ERROR       0xFFu   /* General error */
#define CPM_MSG_SUCCESS     0x00u   /* Success */
#define CPM_MSG_EOF         0x01u   /* End of file */
#define CPM_MSG_INVALID_FCB 0x09u   /* Invalid FCB */

/* =======================================================
 * RDS system addresses
 * ======================================================= */
/** Contains the disk number (0 = currently selected, 1 = A:, 2 = B:, ...). */
#define RDS_DISK            0x0004u

/** Screen buffer mode register.  Normally contains 0x23.
 *  Set to RDS_SCR_MODE_ON to map 0xA000–0xDFFF to the screen buffer. */
#define RDS_SCR_MODE        0x003Cu
#define RDS_SCR_MODE_ON     0u

/** RDS mode register.  Set to RDS_MODE_0 or RDS_MODE_1 to enter RDS mode. */
#define RDS_MODE            0x003Eu
#define RDS_MODE_0          0x80u   /* 0x100–0xF400 user RAM, console enabled */
#define RDS_MODE_1          0x81u   /* 0x100–0xFFFF user RAM, console disabled */

/* =======================================================
 * RDS BDOS extended function numbers
 * ======================================================= */
#define RDS_SUB_SCR_MODE    0x0u    /* Set the RDS screen mode */

/* =======================================================
 * Disk identifiers
 * ======================================================= */
#define DISK_CURRENT        0u      /* Currently selected disk */
#define DISK_A              1u
#define DISK_B              2u

/* =======================================================
 * Build flags
 * ======================================================= */
#define V6_OS_LOAD_STORE_META   0u

#endif /* __V6C_V6C_OS_CONSTS_H */
