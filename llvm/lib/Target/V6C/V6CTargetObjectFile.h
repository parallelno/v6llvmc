//===-- V6CTargetObjectFile.h - V6C Object Info -----------------*- C++ -*-===//
//
// Part of the V6C backend for LLVM.
//
// The V6C ultimately targets flat binaries, but during the MC assembly phase
// we use generic ELF sections as a convenient container. The flat binary
// writer (M6) will strip all metadata.
//
//===----------------------------------------------------------------------===//

#ifndef LLVM_LIB_TARGET_V6C_V6CTARGETOBJECTFILE_H
#define LLVM_LIB_TARGET_V6C_V6CTARGETOBJECTFILE_H

#include "llvm/CodeGen/TargetLoweringObjectFileImpl.h"

namespace llvm {

class V6CTargetObjectFile : public TargetLoweringObjectFileELF {
public:
  void Initialize(MCContext &Ctx, const TargetMachine &TM) override {
    TargetLoweringObjectFileELF::Initialize(Ctx, TM);
  }
};

} // namespace llvm

#endif // LLVM_LIB_TARGET_V6C_V6CTARGETOBJECTFILE_H
