//===-- V6CMCExpr.cpp - V6C specific MC expression classes ----------------===//
//
// Part of the V6C backend for LLVM.
//
//===----------------------------------------------------------------------===//

#include "V6CMCExpr.h"
#include "llvm/MC/MCAsmLayout.h"
#include "llvm/MC/MCAssembler.h"
#include "llvm/MC/MCContext.h"
#include "llvm/MC/MCStreamer.h"
#include "llvm/MC/MCValue.h"

using namespace llvm;

const V6CMCExpr *V6CMCExpr::create(VariantKind K, const MCExpr *E,
                                   MCContext &Ctx) {
  return new (Ctx) V6CMCExpr(K, E);
}

void V6CMCExpr::printImpl(raw_ostream &OS, const MCAsmInfo *MAI) const {
  // v6asm syntax: <(expr) for lo8, >(expr) for hi8
  OS << (Kind == VK_V6C_LO8 ? '<' : '>') << '(';
  Expr->print(OS, MAI);
  OS << ')';
}

bool V6CMCExpr::evaluateAsRelocatableImpl(MCValue &Res,
                                          const MCAsmLayout *Layout,
                                          const MCFixup *Fixup) const {
  MCValue Value;
  if (!Expr->evaluateAsRelocatable(Value, Layout, Fixup))
    return false;

  if (Value.isAbsolute()) {
    // Constant: fold immediately.
    int64_t Val = Value.getConstant();
    if (Kind == VK_V6C_LO8)
      Res = MCValue::get(Val & 0xFF);
    else
      Res = MCValue::get((Val >> 8) & 0xFF);
    return true;
  }

  // Symbol reference: can't fold — preserve for fixup/relocation.
  Res = Value;
  return true;
}

void V6CMCExpr::visitUsedExpr(MCStreamer &S) const {
  S.visitUsedExpr(*Expr);
}

MCFragment *V6CMCExpr::findAssociatedFragment() const {
  return Expr->findAssociatedFragment();
}
