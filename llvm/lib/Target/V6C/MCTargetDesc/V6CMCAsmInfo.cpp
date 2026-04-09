//===-- V6CMCAsmInfo.cpp - V6C asm properties -----------------------------===//
//
// Part of the V6C backend for LLVM.
//
//===----------------------------------------------------------------------===//

#include "V6CMCAsmInfo.h"
#include "llvm/TargetParser/Triple.h"

namespace llvm {

V6CMCAsmInfo::V6CMCAsmInfo(const Triple &TT, const MCTargetOptions &Options) {
  CodePointerSize = 2;
  CalleeSaveStackSlotSize = 2;
  CommentString = ";";
  PrivateGlobalPrefix = ".L";
  PrivateLabelPrefix = ".L";
  LabelSuffix = ":";
  SeparatorString = "\n";
  AlignmentIsInBytes = true;
  UsesELFSectionDirectiveForBSS = true;
  // 8080 assembly uses uppercase mnemonics matched by TableGen AsmString.
  // Data directives compatible with common 8080 assemblers.
  Data8bitsDirective = "\tDB\t";
  Data16bitsDirective = "\tDW\t";
  Data32bitsDirective = nullptr; // No native 32-bit data directive.
  Data64bitsDirective = nullptr;
  ZeroDirective = nullptr; // No .zero equivalent; use DB 0 sequences.
  AscizDirective = nullptr; // No null-terminated string directive.
  HasDotTypeDotSizeDirective = false;
  HasSingleParameterDotFile = false;
  IsLittleEndian = true;
}

} // namespace llvm
