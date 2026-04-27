//===-- V6CTargetInfo.cpp - V6C Target Implementation ---------------------===//
//
// Part of the V6C backend for LLVM.
//
//===----------------------------------------------------------------------===//

#include "TargetInfo/V6CTargetInfo.h"
#include "llvm/MC/TargetRegistry.h"

namespace llvm {
Target &getTheV6CTarget() {
  static Target TheV6CTarget;
  return TheV6CTarget;
}
} // namespace llvm

extern "C" LLVM_EXTERNAL_VISIBILITY void LLVMInitializeV6CTargetInfo() {
  llvm::RegisterTarget<llvm::Triple::i8080> X(
      llvm::getTheV6CTarget(), "v6c", "Vector 06c (Intel 8080)", "V6C");
}

// LLVMInitializeV6CAsmParser is defined in AsmParser/V6CAsmParser.cpp.
