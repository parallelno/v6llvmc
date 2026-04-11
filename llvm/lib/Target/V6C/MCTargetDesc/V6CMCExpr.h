//===-- V6CMCExpr.h - V6C specific MC expression classes --------*- C++ -*-===//
//
// Part of the V6C backend for LLVM.
//
// Defines V6CMCExpr for lo8/hi8 byte extraction of 16-bit values,
// used by MVI instructions in the V6C_BR_CC16_IMM expansion.
//
//===----------------------------------------------------------------------===//

#ifndef LLVM_LIB_TARGET_V6C_MCTARGETDESC_V6CMCEXPR_H
#define LLVM_LIB_TARGET_V6C_MCTARGETDESC_V6CMCEXPR_H

#include "llvm/MC/MCExpr.h"

namespace llvm {

class V6CMCExpr : public MCTargetExpr {
public:
  enum VariantKind {
    VK_V6C_LO8, // Low byte of 16-bit value: <(expr)
    VK_V6C_HI8, // High byte of 16-bit value: >(expr)
  };

private:
  const VariantKind Kind;
  const MCExpr *Expr;

  explicit V6CMCExpr(VariantKind K, const MCExpr *E) : Kind(K), Expr(E) {}

public:
  static const V6CMCExpr *create(VariantKind K, const MCExpr *E,
                                 MCContext &Ctx);

  VariantKind getKind() const { return Kind; }
  const MCExpr *getSubExpr() const { return Expr; }

  void printImpl(raw_ostream &OS, const MCAsmInfo *MAI) const override;
  bool evaluateAsRelocatableImpl(MCValue &Res, const MCAsmLayout *Layout,
                                 const MCFixup *Fixup) const override;
  void visitUsedExpr(MCStreamer &S) const override;
  MCFragment *findAssociatedFragment() const override;
  void fixELFSymbolsInTLSFixups(MCAssembler &) const override {}
};

} // namespace llvm

#endif // LLVM_LIB_TARGET_V6C_MCTARGETDESC_V6CMCEXPR_H
