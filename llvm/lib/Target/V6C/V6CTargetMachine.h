//===-- V6CTargetMachine.h - Define TargetMachine for V6C -------*- C++ -*-===//
//
// Part of the V6C backend for LLVM.
//
//===----------------------------------------------------------------------===//

#ifndef LLVM_LIB_TARGET_V6C_V6CTARGETMACHINE_H
#define LLVM_LIB_TARGET_V6C_V6CTARGETMACHINE_H

#include "V6CSubtarget.h"
#include "llvm/Target/TargetMachine.h"
#include <memory>
#include <optional>

namespace llvm {

class TargetLoweringObjectFile;

class V6CTargetMachine : public LLVMTargetMachine {
public:
  V6CTargetMachine(const Target &T, const Triple &TT, StringRef CPU,
                    StringRef FS, const TargetOptions &Options,
                    std::optional<Reloc::Model> RM,
                    std::optional<CodeModel::Model> CM, CodeGenOptLevel OL,
                    bool JIT);

  ~V6CTargetMachine() override;

  const V6CSubtarget *getSubtargetImpl() const;
  const V6CSubtarget *getSubtargetImpl(const Function &) const override;

  TargetPassConfig *createPassConfig(PassManagerBase &PM) override;

  TargetLoweringObjectFile *getObjFileLowering() const override {
    return TLOF.get();
  }

private:
  V6CSubtarget SubTarget;
  std::unique_ptr<TargetLoweringObjectFile> TLOF;
};

} // namespace llvm

#endif // LLVM_LIB_TARGET_V6C_V6CTARGETMACHINE_H
