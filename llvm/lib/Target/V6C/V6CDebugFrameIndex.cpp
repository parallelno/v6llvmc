//===-- V6CDebugFrameIndex.cpp - Final debug frame locations -------------===//
//
// Part of the V6C backend for LLVM.
//
//===----------------------------------------------------------------------===//

#include "V6C.h"
#include "V6CInstrInfo.h"
#include "V6CMachineFunctionInfo.h"
#include "llvm/CodeGen/MachineFunctionPass.h"
#include "llvm/CodeGen/MachineModuleInfo.h"

using namespace llvm;

namespace {

class V6CDebugFrameIndex : public MachineFunctionPass {
public:
  static char ID;
  V6CDebugFrameIndex() : MachineFunctionPass(ID) {}

  StringRef getPassName() const override {
    return "V6C Debug Frame-Index Locations";
  }

  bool runOnMachineFunction(MachineFunction &MF) override;
};

} // namespace

char V6CDebugFrameIndex::ID = 0;

bool V6CDebugFrameIndex::runOnMachineFunction(MachineFunction &MF) {
  if (!MF.getMMI().hasDebugInfo())
    return false;

  const auto *MFI = MF.getInfo<V6CMachineFunctionInfo>();
  bool Changed = false;
  for (MachineBasicBlock &MBB : MF) {
    for (MachineInstr &MI : MBB) {
      if (!MI.isDebugValue())
        continue;
      for (MachineOperand &MO : MI.operands()) {
        if (!MO.isFI())
          continue;
        const int FI = MO.getIndex();
        if (MCSymbol *Patch = MFI->getO61PatchSymbol(FI)) {
          MO.ChangeToMCSymbol(Patch, V6CII::MO_PATCH_IMM);
          Changed = true;
        } else if (MFI->hasStaticStack() && MFI->hasStaticSlot(FI)) {
          MO.ChangeToGA(MFI->getStaticStackGV(), MFI->getStaticOffset(FI));
          Changed = true;
        }
      }
    }
  }
  return Changed;
}

FunctionPass *llvm::createV6CDebugFrameIndexPass() {
  return new V6CDebugFrameIndex();
}