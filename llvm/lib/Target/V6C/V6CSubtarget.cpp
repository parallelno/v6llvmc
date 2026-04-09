//===-- V6CSubtarget.cpp - V6C Subtarget Information ----------------------===//
//
// Part of the V6C backend for LLVM.
//
//===----------------------------------------------------------------------===//

#include "V6CSubtarget.h"
#include "V6CTargetMachine.h"

#define DEBUG_TYPE "v6c-subtarget"

#define GET_SUBTARGETINFO_TARGET_DESC
#define GET_SUBTARGETINFO_CTOR
#include "V6CGenSubtargetInfo.inc"

namespace llvm {

V6CSubtarget::V6CSubtarget(const Triple &TT, const std::string &CPU,
                             const std::string &FS,
                             const V6CTargetMachine &TM)
    : V6CGenSubtargetInfo(TT, CPU, /*TuneCPU*/ CPU, FS),
      TLInfo(TM, *this) {
  ParseSubtargetFeatures(CPU, /*TuneCPU*/ CPU, FS);
}

} // namespace llvm
