//===- V6C.cpp - V6C (I8080) ABI Implementation --------------------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#include "ABIInfoImpl.h"
#include "TargetInfo.h"

using namespace clang;
using namespace clang::CodeGen;

//===----------------------------------------------------------------------===//
// V6C (Intel 8080 / Vector 06c) ABI Implementation.
//
// Calling convention: V6C_CConv
//   Arg1: i8→A, i16→HL
//   Arg2: i8→E, i16→DE
//   Arg3: i8→C, i16→BC
//   Arg4+: stack (right-to-left, caller cleans)
//   Return: i8→A, i16→HL, i32→DE:HL
//===----------------------------------------------------------------------===//

namespace {

class V6CABIInfo : public DefaultABIInfo {
public:
  V6CABIInfo(CodeGenTypes &CGT) : DefaultABIInfo(CGT) {}

  ABIArgInfo classifyReturnType(QualType Ty) const {
    if (Ty->isVoidType())
      return ABIArgInfo::getIgnore();

    unsigned TySize = getContext().getTypeSize(Ty);

    // i8 return in A — don't extend to i16.
    if (Ty->isIntegralOrEnumerationType() && TySize <= 8)
      return ABIArgInfo::getDirect();

    // i16 return in HL, i32 return in DE:HL — direct.
    if (TySize <= 32)
      return ABIArgInfo::getDirect();

    // Larger returns via sret pointer.
    return getNaturalAlignIndirect(Ty);
  }

  ABIArgInfo classifyArgumentType(QualType Ty) const {
    unsigned TySize = getContext().getTypeSize(Ty);

    // i8 — don't extend to i16 (8080 has 8-bit registers).
    if (Ty->isIntegralOrEnumerationType() && TySize <= 8)
      return ABIArgInfo::getDirect();

    // Everything else passes directly (register or stack, decided by backend).
    return ABIArgInfo::getDirect();
  }

  void computeInfo(CGFunctionInfo &FI) const override {
    if (!getCXXABI().classifyReturnType(FI))
      FI.getReturnInfo() = classifyReturnType(FI.getReturnType());
    for (auto &I : FI.arguments())
      I.info = classifyArgumentType(I.type);
  }

  Address EmitVAArg(CodeGenFunction &CGF, Address VAListAddr,
                    QualType Ty) const override {
    return EmitVAArgInstr(CGF, VAListAddr, Ty, classifyArgumentType(Ty));
  }
};

class V6CTargetCodeGenInfo : public TargetCodeGenInfo {
public:
  V6CTargetCodeGenInfo(CodeGenTypes &CGT)
      : TargetCodeGenInfo(std::make_unique<V6CABIInfo>(CGT)) {}
};

} // namespace

std::unique_ptr<TargetCodeGenInfo>
CodeGen::createV6CTargetCodeGenInfo(CodeGenModule &CGM) {
  return std::make_unique<V6CTargetCodeGenInfo>(CGM.getTypes());
}
