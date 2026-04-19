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
#include "V6CInstrInfo.h"
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
#include "llvm/IR/Function.h"
#include "llvm/Target/TargetLoweringObjectFile.h"

#define DEBUG_TYPE "v6c-asm-printer"

namespace llvm {

class V6CAsmPrinter : public AsmPrinter {
public:
  V6CAsmPrinter(TargetMachine &TM, std::unique_ptr<MCStreamer> Streamer)
      : AsmPrinter(TM, std::move(Streamer)) {}

  StringRef getPassName() const override { return "V6C Assembly Printer"; }

  void emitFunctionBodyStart() override;
  void emitInstruction(const MachineInstr *MI) override;

  bool PrintAsmOperand(const MachineInstr *MI, unsigned OpNum,
                       const char *ExtraCode, raw_ostream &O) override;
};

void V6CAsmPrinter::emitFunctionBodyStart() {
  if (!getV6CAnnotatePseudosEnabled())
    return;

  const Function &F = MF->getFunction();
  const TargetRegisterInfo *TRI = MF->getSubtarget().getRegisterInfo();

  // Map LLVM IR type to C-like type string.
  auto TypeStr = [](Type *Ty) -> std::string {
    if (Ty->isVoidTy()) return "void";
    if (Ty->isIntegerTy(1)) return "bool";
    if (Ty->isIntegerTy(8)) return "char";
    if (Ty->isIntegerTy(16)) return "int";
    if (Ty->isPointerTy()) return "void*";
    return "?";
  };

  // Build C-like declaration string.
  std::string Decl = TypeStr(F.getReturnType());
  Decl += " ";
  Decl += F.getName().str();
  Decl += "(";

  // V6C calling convention: position-based register assignment.
  static const MCPhysReg ArgRegsI8[]  = {V6C::A, V6C::E, V6C::C};
  static const MCPhysReg ArgRegsI16[] = {V6C::HL, V6C::DE, V6C::BC};

  struct ParamInfo {
    std::string Name;
    std::string Reg;
  };
  SmallVector<ParamInfo, 4> Params;
  unsigned ArgIdx = 0;

  for (unsigned i = 0; i < F.arg_size(); ++i) {
    const Argument *Arg = F.getArg(i);
    Type *Ty = Arg->getType();
    std::string TStr = TypeStr(Ty);
    std::string Name = Arg->getName().empty()
                           ? ("arg" + std::to_string(i))
                           : Arg->getName().str();

    if (i > 0)
      Decl += ", ";
    Decl += TStr + " " + Name;

    std::string RegStr;
    if (ArgIdx < 3) {
      bool Is8Bit = Ty->isIntegerTy() && Ty->getIntegerBitWidth() <= 8;
      MCPhysReg Reg = Is8Bit ? ArgRegsI8[ArgIdx] : ArgRegsI16[ArgIdx];
      RegStr = TRI->getName(Reg);
    } else {
      RegStr = "stack";
    }
    Params.push_back({Name, RegStr});
    ++ArgIdx;
  }

  if (F.arg_size() == 0)
    Decl += "void";
  Decl += ")";

  OutStreamer->emitRawComment("=== " + Decl + " ===");
  for (const auto &P : Params) {
    OutStreamer->emitRawComment("  " + P.Name + " = " + P.Reg);
  }
}

void V6CAsmPrinter::emitInstruction(const MachineInstr *MI) {
  if (MI->getOpcode() == V6C::V6C_PSEUDO_COMMENT) {
    unsigned OrigOpc = MI->getOperand(0).getImm();
    const TargetInstrInfo *TII = MF->getSubtarget().getInstrInfo();
    OutStreamer->emitRawComment(Twine("--- ") + TII->getName(OrigOpc) + " ---");
    return;
  }

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
