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
#include "llvm/ADT/StringSet.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/GlobalVariable.h"
#include "llvm/IR/Module.h"
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

  bool doInitialization(Module &M) override;
  bool runOnMachineFunction(MachineFunction &MF) override;

  void emitFunctionBodyStart() override;
  void emitInstruction(const MachineInstr *MI) override;

  bool PrintAsmOperand(const MachineInstr *MI, unsigned OpNum,
                       const char *ExtraCode, raw_ostream &O) override;

private:
  /// Names of functions tagged `__attribute__((annotate("v6c-rt-helper")))`
  /// in the current module. Populated in doInitialization().
  StringSet<> RTHelperNames;
};

bool V6CAsmPrinter::doInitialization(Module &M) {
  // Scan `@llvm.global.annotations` once per module to find functions
  // tagged with `__attribute__((annotate("v6c-rt-helper")))` so we can
  // suppress them from .s output unless -mv6c-print-rt-helpers is on.
  RTHelperNames.clear();
  if (auto *GA = M.getNamedGlobal("llvm.global.annotations")) {
    if (auto *CA = dyn_cast_or_null<ConstantArray>(GA->getInitializer())) {
      for (auto &Op : CA->operands()) {
        auto *CS = dyn_cast<ConstantStruct>(&*Op);
        if (!CS || CS->getNumOperands() < 2)
          continue;
        auto *F = dyn_cast<Function>(
            CS->getOperand(0)->stripPointerCasts());
        auto *StrGV = dyn_cast<GlobalVariable>(
            CS->getOperand(1)->stripPointerCasts());
        if (!F || !StrGV || !StrGV->hasInitializer())
          continue;
        auto *CDA = dyn_cast<ConstantDataArray>(StrGV->getInitializer());
        if (!CDA || !CDA->isCString())
          continue;
        if (CDA->getAsCString() == "v6c-rt-helper")
          RTHelperNames.insert(F->getName());
      }
    }
  }
  return AsmPrinter::doInitialization(M);
}

bool V6CAsmPrinter::runOnMachineFunction(MachineFunction &MF) {
  // Suppress auto-included v6c_arith.h runtime helpers from human-readable
  // asm output unless explicitly requested via -mv6c-print-rt-helpers.
  // Only applies to text (`-S`) emission — when emitting an object file
  // (`-filetype=obj`) every helper must still be encoded so the linker
  // can resolve calls to `__mulqi3` etc.
  if (!getV6CPrintRTHelpersEnabled() && OutStreamer->hasRawTextSupport() &&
      RTHelperNames.contains(MF.getName()))
    return false;
  return AsmPrinter::runOnMachineFunction(MF);
}

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

  // V6C calling convention: free-list allocator (mirrors
  // V6CArgAllocator in V6CISelLowering.cpp). i8 args take from
  // {A,B,C,D,E,L,H}; i16 args take from {HL,DE,BC}; taking an i16 pair
  // removes its two halves from the i8 list and vice versa.
  SmallVector<MCPhysReg, 7> FreeI8 = {V6C::A, V6C::B, V6C::C,
                                      V6C::D, V6C::E, V6C::L, V6C::H};
  SmallVector<MCPhysReg, 3> FreeI16 = {V6C::HL, V6C::DE, V6C::BC};
  auto dropReg = [](SmallVectorImpl<MCPhysReg> &L, MCPhysReg R) {
    auto It = std::find(L.begin(), L.end(), R);
    if (It != L.end())
      L.erase(It);
  };
  auto pairOf = [](MCPhysReg H) -> MCPhysReg {
    switch (H) {
    case V6C::H: case V6C::L: return V6C::HL;
    case V6C::D: case V6C::E: return V6C::DE;
    case V6C::B: case V6C::C: return V6C::BC;
    default: return MCRegister::NoRegister;
    }
  };
  auto halves = [](MCPhysReg P) -> std::pair<MCPhysReg, MCPhysReg> {
    switch (P) {
    case V6C::HL: return {V6C::H, V6C::L};
    case V6C::DE: return {V6C::D, V6C::E};
    case V6C::BC: return {V6C::B, V6C::C};
    default: return {MCRegister::NoRegister, MCRegister::NoRegister};
    }
  };
  auto takeI8 = [&]() -> MCPhysReg {
    if (FreeI8.empty()) return MCRegister::NoRegister;
    MCPhysReg R = FreeI8.front();
    FreeI8.erase(FreeI8.begin());
    if (MCPhysReg P = pairOf(R)) dropReg(FreeI16, P);
    return R;
  };
  auto takeI16 = [&]() -> MCPhysReg {
    if (FreeI16.empty()) return MCRegister::NoRegister;
    MCPhysReg P = FreeI16.front();
    FreeI16.erase(FreeI16.begin());
    auto Hs = halves(P);
    dropReg(FreeI8, Hs.first);
    dropReg(FreeI8, Hs.second);
    return P;
  };

  struct ParamInfo {
    std::string Name;
    std::string Reg;
  };
  SmallVector<ParamInfo, 4> Params;

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

    bool Is8Bit = Ty->isIntegerTy() && Ty->getIntegerBitWidth() <= 8;
    MCPhysReg Reg = Is8Bit ? takeI8() : takeI16();
    std::string RegStr = Reg ? std::string(TRI->getName(Reg)) : "stack";
    Params.push_back({Name, RegStr});
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
  case MachineOperand::MO_Register: {
    // V6CAsmParser rejects long-form pair names HL/DE/BC; print them as
    // their 8080-canonical first-half (H/D/B) instead so inline-asm output
    // round-trips through the integrated assembler.
    Register Reg = MO.getReg();
    unsigned AltIdx = V6C::NoRegAltName;
    if (V6C::GR16AllRegClass.contains(Reg))
      AltIdx = V6C::Pair8080;
    O << V6CInstPrinter::getRegisterName(Reg, AltIdx);
    return false;
  }
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
