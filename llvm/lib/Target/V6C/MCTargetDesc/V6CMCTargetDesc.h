//===-- V6CMCTargetDesc.h - V6C Target Descriptions -------------*- C++ -*-===//
//
// Part of the V6C backend for LLVM.
//
//===----------------------------------------------------------------------===//

#ifndef LLVM_LIB_TARGET_V6C_MCTARGETDESC_V6CMCTARGETDESC_H
#define LLVM_LIB_TARGET_V6C_MCTARGETDESC_V6CMCTARGETDESC_H

#include "llvm/Support/DataTypes.h"
#include <memory>

namespace llvm {

class MCAsmBackend;
class MCCodeEmitter;
class MCContext;
class MCInstrInfo;
class MCRegisterInfo;
class MCSubtargetInfo;
class MCTargetOptions;
class Target;

MCInstrInfo *createV6CMCInstrInfo();
MCCodeEmitter *createV6CMCCodeEmitter(const MCInstrInfo &MCII,
                                       MCContext &Ctx);
MCAsmBackend *createV6CAsmBackend(const Target &T,
                                   const MCSubtargetInfo &STI,
                                   const MCRegisterInfo &MRI,
                                   const MCTargetOptions &Options);

} // namespace llvm

#define GET_REGINFO_ENUM
#include "V6CGenRegisterInfo.inc"

#define GET_INSTRINFO_ENUM
#define GET_INSTRINFO_MC_HELPER_DECLS
#include "V6CGenInstrInfo.inc"

#define GET_SUBTARGETINFO_ENUM
#include "V6CGenSubtargetInfo.inc"

#endif // LLVM_LIB_TARGET_V6C_MCTARGETDESC_V6CMCTARGETDESC_H
