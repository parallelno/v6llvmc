//===-- V6CFixupKinds.h - V6C Specific Fixup Entries ------------*- C++ -*-===//
//
// Part of the V6C backend for LLVM.
//
//===----------------------------------------------------------------------===//

#ifndef LLVM_LIB_TARGET_V6C_MCTARGETDESC_V6CFIXUPKINDS_H
#define LLVM_LIB_TARGET_V6C_MCTARGETDESC_V6CFIXUPKINDS_H

#include "llvm/MC/MCFixup.h"

namespace llvm {
namespace V6C {

enum Fixups {
  /// 8-bit absolute value (immediate operand at byte offset 1).
  fixup_v6c_8 = FirstTargetFixupKind,

  /// 16-bit absolute address (at byte offset 1, little-endian).
  fixup_v6c_16,

  /// Low byte of 16-bit address (for MVI in V6C_BR_CC16_IMM).
  fixup_v6c_lo8,

  /// High byte of 16-bit address (for MVI in V6C_BR_CC16_IMM).
  fixup_v6c_hi8,

  // Marker
  fixup_v6c_invalid,
  NumTargetFixupKinds = fixup_v6c_invalid - FirstTargetFixupKind
};

/// V6C ELF relocation types.
/// Since we use EM_NONE, these are private to the V6C toolchain.
enum RelocType {
  R_V6C_NONE = 0,
  R_V6C_8    = 1,   ///< 8-bit absolute value
  R_V6C_16   = 2,   ///< 16-bit absolute address (little-endian)
  R_V6C_LO8  = 3,   ///< Low byte of 16-bit address
  R_V6C_HI8  = 4,   ///< High byte of 16-bit address
};

} // namespace V6C
} // namespace llvm

#endif // LLVM_LIB_TARGET_V6C_MCTARGETDESC_V6CFIXUPKINDS_H
