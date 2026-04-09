//===-- V6CMCAsmInfo.h - V6C asm properties ---------------------*- C++ -*-===//
//
// Part of the V6C backend for LLVM.
//
//===----------------------------------------------------------------------===//

#ifndef LLVM_LIB_TARGET_V6C_MCTARGETDESC_V6CMCASMINFO_H
#define LLVM_LIB_TARGET_V6C_MCTARGETDESC_V6CMCASMINFO_H

#include "llvm/MC/MCAsmInfo.h"

namespace llvm {

class Triple;

class V6CMCAsmInfo : public MCAsmInfo {
public:
  explicit V6CMCAsmInfo(const Triple &TT, const MCTargetOptions &Options);
};

} // namespace llvm

#endif // LLVM_LIB_TARGET_V6C_MCTARGETDESC_V6CMCASMINFO_H
