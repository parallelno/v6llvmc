//===-- V6C.h - Top-level interface for V6C representation ------*- C++ -*-===//
//
// Part of the V6C backend for LLVM.
//
//===----------------------------------------------------------------------===//

#ifndef LLVM_LIB_TARGET_V6C_V6C_H
#define LLVM_LIB_TARGET_V6C_V6C_H

#include "llvm/Target/TargetMachine.h"

namespace llvm {

class V6CTargetMachine;
class FunctionPass;

FunctionPass *createV6CISelDag(V6CTargetMachine &TM,
                                CodeGenOptLevel OptLevel);

/// Get the configured V6C start address (-mv6c-start-address, default 0x0100).
unsigned getV6CStartAddress();

/// Post-RA optimization passes (M8).
FunctionPass *createV6CZeroTestOptPass();
FunctionPass *createV6CXchgOptPass();
FunctionPass *createV6CPeepholePass();
FunctionPass *createV6CBranchOptPass();
FunctionPass *createV6CLoadStoreOptPass();
FunctionPass *createV6CAccumulatorPlanningPass();
FunctionPass *createV6CSPTrickOptPass();

/// IR-level optimization pass (M8).
FunctionPass *createV6CTypeNarrowingPass();

/// IR-level pass: convert loop base+counter to running pointer induction.
FunctionPass *createV6CLoopPointerInductionPass();

} // namespace llvm

#endif // LLVM_LIB_TARGET_V6C_V6C_H
