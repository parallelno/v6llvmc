//===--- I8080.cpp - Implement I8080/V6C target feature support ------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file implements I8080 (Vector 06c) TargetInfo objects.
//
//===----------------------------------------------------------------------===//

#include "I8080.h"
#include "clang/Basic/MacroBuilder.h"

using namespace clang;
using namespace clang::targets;

void I8080TargetInfo::getTargetDefines(const LangOptions &Opts,
                                       MacroBuilder &Builder) const {
  Builder.defineMacro("__I8080__");
  Builder.defineMacro("__V6C__");
}

ArrayRef<const char *> I8080TargetInfo::getGCCRegNames() const {
  static const char *const GCCRegNames[] = {
      "A", "B", "C", "D", "E", "H", "L", "SP", "FLAGS"};
  return llvm::ArrayRef(GCCRegNames);
}
