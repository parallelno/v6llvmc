//===-- V6CInstPrinter.cpp - Convert V6C MCInst to assembly ---------------===//
//
// Part of the V6C backend for LLVM.
//
//===----------------------------------------------------------------------===//

#include "V6CInstPrinter.h"
#include "V6CMCTargetDesc.h"
#include "llvm/MC/MCExpr.h"
#include "llvm/MC/MCInst.h"
#include "llvm/MC/MCInstrInfo.h"
#include "llvm/MC/MCRegisterInfo.h"
#include "llvm/Support/FormattedStream.h"

using namespace llvm;

#define DEBUG_TYPE "asm-printer"

// Include the auto-generated portion of the assembly writer.
#include "V6CGenAsmWriter.inc"

void V6CInstPrinter::printInst(const MCInst *MI, uint64_t Address,
                                StringRef Annot, const MCSubtargetInfo &STI,
                                raw_ostream &O) {
  printInstruction(MI, Address, O);
  printAnnotation(O, Annot);
}

void V6CInstPrinter::printOperand(const MCInst *MI, unsigned OpNo,
                                   raw_ostream &O) {
  const MCOperand &Op = MI->getOperand(OpNo);

  if (Op.isReg()) {
    O << getRegisterName(Op.getReg());
  } else if (Op.isImm()) {
    // Print immediates as hex with 0x prefix for v6asm compatibility.
    // Mask to 16 bits — the widest immediate the 8080 supports.
    int64_t Val = Op.getImm();
    uint64_t UVal = static_cast<uint64_t>(Val) & 0xFFFF;
    if (UVal <= 9)
      O << UVal;
    else
      O << formatHex(UVal);
  } else if (Op.isExpr()) {
    Op.getExpr()->print(O, &MAI);
  }
}

void V6CInstPrinter::printBrTarget(const MCInst *MI, unsigned OpNo,
                                    raw_ostream &O) {
  const MCOperand &Op = MI->getOperand(OpNo);

  if (Op.isImm()) {
    O << formatHex(static_cast<uint64_t>(Op.getImm()));
  } else if (Op.isExpr()) {
    Op.getExpr()->print(O, &MAI);
  }
}
