//===-- V6CMCTargetDesc.cpp - V6C Target Descriptions ---------------------===//
//
// Part of the V6C backend for LLVM.
//
//===----------------------------------------------------------------------===//

#include "V6CMCTargetDesc.h"
#include "V6CInstPrinter.h"
#include "V6CMCAsmInfo.h"
#include "TargetInfo/V6CTargetInfo.h"

#include "llvm/MC/MCInstrInfo.h"
#include "llvm/MC/MCRegisterInfo.h"
#include "llvm/MC/MCSubtargetInfo.h"
#include "llvm/MC/TargetRegistry.h"

#define GET_INSTRINFO_MC_DESC
#define ENABLE_INSTR_PREDICATE_VERIFIER
#include "V6CGenInstrInfo.inc"

#define GET_SUBTARGETINFO_MC_DESC
#include "V6CGenSubtargetInfo.inc"

#define GET_REGINFO_MC_DESC
#include "V6CGenRegisterInfo.inc"

using namespace llvm;

MCInstrInfo *llvm::createV6CMCInstrInfo() {
  MCInstrInfo *X = new MCInstrInfo();
  InitV6CMCInstrInfo(X);
  return X;
}

static MCRegisterInfo *createV6CMCRegisterInfo(const Triple &TT) {
  MCRegisterInfo *X = new MCRegisterInfo();
  InitV6CMCRegisterInfo(X, 0);
  return X;
}

static MCSubtargetInfo *createV6CMCSubtargetInfo(const Triple &TT,
                                                  StringRef CPU,
                                                  StringRef FS) {
  return createV6CMCSubtargetInfoImpl(TT, CPU, /*TuneCPU*/ CPU, FS);
}

static MCInstPrinter *createV6CMCInstPrinter(const Triple &T,
                                              unsigned SyntaxVariant,
                                              const MCAsmInfo &MAI,
                                              const MCInstrInfo &MII,
                                              const MCRegisterInfo &MRI) {
  if (SyntaxVariant == 0)
    return new V6CInstPrinter(MAI, MII, MRI);
  return nullptr;
}

extern "C" LLVM_EXTERNAL_VISIBILITY void LLVMInitializeV6CTargetMC() {
  RegisterMCAsmInfo<V6CMCAsmInfo> X(getTheV6CTarget());

  TargetRegistry::RegisterMCInstrInfo(getTheV6CTarget(), createV6CMCInstrInfo);
  TargetRegistry::RegisterMCRegInfo(getTheV6CTarget(),
                                    createV6CMCRegisterInfo);
  TargetRegistry::RegisterMCSubtargetInfo(getTheV6CTarget(),
                                          createV6CMCSubtargetInfo);
  TargetRegistry::RegisterMCInstPrinter(getTheV6CTarget(),
                                        createV6CMCInstPrinter);
  TargetRegistry::RegisterMCCodeEmitter(getTheV6CTarget(),
                                        createV6CMCCodeEmitter);
  TargetRegistry::RegisterMCAsmBackend(getTheV6CTarget(),
                                       createV6CAsmBackend);
}
