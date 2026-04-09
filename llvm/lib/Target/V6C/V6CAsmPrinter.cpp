//===-- V6CAsmPrinter.cpp - V6C LLVM assembly writer ----------------------===//
//
// Part of the V6C backend for LLVM.
//
// Converts MachineFunction/MachineInstr representation into 8080 assembly
// text compatible with v6asm.
//
//===----------------------------------------------------------------------===//

#include "V6C.h"
#include "V6CMCInstLower.h"
#include "V6CSubtarget.h"
#include "V6CTargetMachine.h"
#include "MCTargetDesc/V6CInstPrinter.h"
#include "TargetInfo/V6CTargetInfo.h"

#include "llvm/CodeGen/AsmPrinter.h"
#include "llvm/CodeGen/MachineFunction.h"
#include "llvm/CodeGen/MachineInstr.h"
#include "llvm/MC/MCContext.h"
#include "llvm/MC/MCInst.h"
#include "llvm/MC/MCStreamer.h"
#include "llvm/MC/MCSymbol.h"
#include "llvm/MC/TargetRegistry.h"
#include "llvm/Target/TargetLoweringObjectFile.h"

#define DEBUG_TYPE "v6c-asm-printer"

namespace llvm {

class V6CAsmPrinter : public AsmPrinter {
public:
  V6CAsmPrinter(TargetMachine &TM, std::unique_ptr<MCStreamer> Streamer)
      : AsmPrinter(TM, std::move(Streamer)) {}

  StringRef getPassName() const override { return "V6C Assembly Printer"; }

  void emitInstruction(const MachineInstr *MI) override;

  bool PrintAsmOperand(const MachineInstr *MI, unsigned OpNum,
                       const char *ExtraCode, raw_ostream &O) override;
};

void V6CAsmPrinter::emitInstruction(const MachineInstr *MI) {
  V6CMCInstLower MCInstLowering(OutContext, *this);

  MCInst TmpInst;
  MCInstLowering.lowerInstruction(*MI, TmpInst);
  EmitToStreamer(*OutStreamer, TmpInst);
}

bool V6CAsmPrinter::PrintAsmOperand(const MachineInstr *MI, unsigned OpNum,
                                     const char *ExtraCode, raw_ostream &O) {
  if (ExtraCode && ExtraCode[0])
    return true; // Unknown modifier.

  const MachineOperand &MO = MI->getOperand(OpNum);
  switch (MO.getType()) {
  case MachineOperand::MO_Register:
    O << V6CInstPrinter::getRegisterName(MO.getReg());
    return false;
  case MachineOperand::MO_Immediate:
    O << MO.getImm();
    return false;
  default:
    return true;
  }
}

} // namespace llvm

extern "C" LLVM_EXTERNAL_VISIBILITY void LLVMInitializeV6CAsmPrinter() {
  llvm::RegisterAsmPrinter<llvm::V6CAsmPrinter> X(llvm::getTheV6CTarget());
}
