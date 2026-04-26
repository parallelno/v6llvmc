//===- V6C.cpp ------------------------------------------------------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// The V6C target is the LLVM backend for the Vector-06c home computer, which
// is built around the Intel 8080 / KR580VM80A CPU. The 8080 has a flat 16-bit
// address space (64 KiB) and no PC-relative addressing, so all V6C
// relocations are absolute. There is no GOT, no PLT, and no dynamic linking.
//
// V6C ELF uses the private machine ID llvm::ELF::EM_V6C (0x8080) and the
// following relocation types (see llvm/lib/Target/V6C/MCTargetDesc/
// V6CFixupKinds.h):
//
//   R_V6C_8   = 1   8-bit absolute value
//   R_V6C_16  = 2   16-bit absolute address (little-endian)
//   R_V6C_LO8 = 3   low byte of a 16-bit absolute address
//   R_V6C_HI8 = 4   high byte of a 16-bit absolute address
//
//===----------------------------------------------------------------------===//

#include "Symbols.h"
#include "Target.h"
#include "lld/Common/ErrorHandler.h"
#include "llvm/BinaryFormat/ELF.h"
#include "llvm/Support/Endian.h"

using namespace llvm;
using namespace llvm::object;
using namespace llvm::support::endian;
using namespace llvm::ELF;
using namespace lld;
using namespace lld::elf;

// V6C relocation type values. These mirror the RelocType enum in
// llvm/lib/Target/V6C/MCTargetDesc/V6CFixupKinds.h. They are kept in sync
// manually because lld must not depend on V6C target backend headers.
enum : uint32_t {
  R_V6C_NONE = 0,
  R_V6C_8    = 1,
  R_V6C_16   = 2,
  R_V6C_LO8  = 3,
  R_V6C_HI8  = 4,
};

namespace {
class V6C final : public TargetInfo {
public:
  V6C();
  RelExpr getRelExpr(RelType type, const Symbol &s,
                     const uint8_t *loc) const override;
  void relocate(uint8_t *loc, const Relocation &rel,
                uint64_t val) const override;
};
} // namespace

V6C::V6C() {
  // V6C images sit in the low 64 KiB of address space. The Vector-06c ROM
  // load address is 0x0100 (CP/M-style); a custom linker script normally
  // overrides this anyway.
  defaultImageBase = 0x100;

  // HLT (0x76) is the safest choice for trap padding on the 8080: if control
  // ever reaches a hole in the link image, the CPU halts instead of executing
  // garbage. Pad to the 4-byte width expected by lld.
  trapInstr = {0x76, 0x76, 0x76, 0x76};
}

RelExpr V6C::getRelExpr(RelType type, const Symbol &s,
                        const uint8_t *loc) const {
  switch (type) {
  case R_V6C_8:
  case R_V6C_16:
  case R_V6C_LO8:
  case R_V6C_HI8:
    return R_ABS;
  default:
    error(getErrorLocation(loc) + "unrecognized relocation " +
          toString(type));
    return R_NONE;
  }
}

void V6C::relocate(uint8_t *loc, const Relocation &rel, uint64_t val) const {
  switch (rel.type) {
  case R_V6C_8:
    // 8-bit absolute. Accept either signed (-128..127) or unsigned (0..255).
    checkIntUInt(loc, val, 8, rel);
    *loc = static_cast<uint8_t>(val & 0xFF);
    break;
  case R_V6C_16:
    // 16-bit absolute, little-endian. Accept either signed or unsigned 16-bit.
    checkIntUInt(loc, val, 16, rel);
    write16le(loc, val & 0xFFFF);
    break;
  case R_V6C_LO8:
    // Low byte of a 16-bit absolute. No overflow check: explicit byte
    // extraction from a wider value (matches lo8(expr) in the V6C asm).
    *loc = static_cast<uint8_t>(val & 0xFF);
    break;
  case R_V6C_HI8:
    // High byte of a 16-bit absolute. Same rationale as R_V6C_LO8.
    *loc = static_cast<uint8_t>((val >> 8) & 0xFF);
    break;
  default:
    error(getErrorLocation(loc) + "unrecognized relocation " +
          toString(rel.type));
  }
}

TargetInfo *elf::getV6CTargetInfo() {
  static V6C target;
  return &target;
}
