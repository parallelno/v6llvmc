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

/// Whether static stack allocation is enabled (-mv6c-static-stack).
bool getV6CStaticStackEnabled();

/// Whether pseudo expansion annotation comments are enabled.
bool getV6CAnnotatePseudosEnabled();

/// Pre-RA optimization pass: constant sinking past branches (O37).
FunctionPass *createV6CConstantSinkingPass();

/// Pre-RA optimization pass: dead PHI-constant elimination (O31).
FunctionPass *createV6CDeadPhiConstPass();

/// Post-RA optimization passes (M8).
FunctionPass *createV6CZeroTestOptPass();
FunctionPass *createV6CRedundantFlagElimPass();
FunctionPass *createV6CXchgOptPass();
FunctionPass *createV6CPeepholePass();
FunctionPass *createV6CBranchOptPass();
FunctionPass *createV6CLoadStoreOptPass();
FunctionPass *createV6CAccumulatorPlanningPass();
FunctionPass *createV6CLoadImmCombinePass();
FunctionPass *createV6CSPTrickOptPass();

/// IR-level optimization pass (M8).
FunctionPass *createV6CTypeNarrowingPass();

/// IR-level pass: convert loop base+counter to running pointer induction.
FunctionPass *createV6CLoopPointerInductionPass();

/// Post-RA pass: static stack allocation for non-reentrant functions (O10).
FunctionPass *createV6CStaticStackAllocPass();

/// Post-RA pass: spill forwarding (O16).
FunctionPass *createV6CSpillForwardingPass();

} // namespace llvm

#endif // LLVM_LIB_TARGET_V6C_V6C_H
