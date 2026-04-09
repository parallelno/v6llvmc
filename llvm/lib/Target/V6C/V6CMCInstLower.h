//===-- V6CMCInstLower.h - Lower MachineInstr to MCInst ---------*- C++ -*-===//
//
// Part of the V6C backend for LLVM.
//
//===----------------------------------------------------------------------===//

#ifndef LLVM_LIB_TARGET_V6C_V6CMCINSTLOWER_H
#define LLVM_LIB_TARGET_V6C_V6CMCINSTLOWER_H

#include "llvm/Support/Compiler.h"

namespace llvm {

class AsmPrinter;
class MachineInstr;
class MachineOperand;
class MCContext;
class MCInst;
class MCOperand;
class MCSymbol;

/// Lowers MachineInstr objects into MCInst objects.
class V6CMCInstLower {
public:
  V6CMCInstLower(MCContext &Ctx, AsmPrinter &Printer)
      : Ctx(Ctx), Printer(Printer) {}

  void lowerInstruction(const MachineInstr &MI, MCInst &OutMI) const;

private:
  MCContext &Ctx;
  AsmPrinter &Printer;

  MCOperand lowerSymbolOperand(const MachineOperand &MO,
                               MCSymbol *Sym) const;
};

} // namespace llvm

#endif // LLVM_LIB_TARGET_V6C_V6CMCINSTLOWER_H
