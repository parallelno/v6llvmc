//===-- V6CSubtarget.h - Define Subtarget for V6C ---------------*- C++ -*-===//
//
// Part of the V6C backend for LLVM.
//
//===----------------------------------------------------------------------===//

#ifndef LLVM_LIB_TARGET_V6C_V6CSUBTARGET_H
#define LLVM_LIB_TARGET_V6C_V6CSUBTARGET_H

#include "V6CFrameLowering.h"
#include "V6CISelLowering.h"
#include "V6CInstrInfo.h"
#include "V6CRegisterInfo.h"
#include "llvm/CodeGen/TargetSubtargetInfo.h"
#include "llvm/Target/TargetMachine.h"

#include "MCTargetDesc/V6CMCTargetDesc.h"

#define GET_SUBTARGETINFO_HEADER
#include "V6CGenSubtargetInfo.inc"

namespace llvm {

class V6CTargetMachine;

class V6CSubtarget : public V6CGenSubtargetInfo {
  V6CFrameLowering FrameLowering;
  V6CInstrInfo InstrInfo;
  V6CRegisterInfo RegInfo;
  V6CTargetLowering TLInfo;

public:
  V6CSubtarget(const Triple &TT, const std::string &CPU,
                const std::string &FS, const V6CTargetMachine &TM);

  const V6CInstrInfo *getInstrInfo() const override { return &InstrInfo; }
  const V6CFrameLowering *getFrameLowering() const override {
    return &FrameLowering;
  }
  const V6CTargetLowering *getTargetLowering() const override {
    return &TLInfo;
  }
  const V6CRegisterInfo *getRegisterInfo() const override { return &RegInfo; }

  void ParseSubtargetFeatures(StringRef CPU, StringRef TuneCPU, StringRef FS);
};

} // namespace llvm

#endif // LLVM_LIB_TARGET_V6C_V6CSUBTARGET_H
