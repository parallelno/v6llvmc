//===-- V6CTargetInfo.h - V6C Target Implementation -------------*- C++ -*-===//
//
// Part of the V6C backend for LLVM.
//
//===----------------------------------------------------------------------===//

#ifndef LLVM_LIB_TARGET_V6C_TARGETINFO_V6CTARGETINFO_H
#define LLVM_LIB_TARGET_V6C_TARGETINFO_V6CTARGETINFO_H

namespace llvm {
class Target;

Target &getTheV6CTarget();
} // namespace llvm

#endif // LLVM_LIB_TARGET_V6C_TARGETINFO_V6CTARGETINFO_H
