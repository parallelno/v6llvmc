//===-- V6CStaticStackAlloc.cpp - Static Stack for Non-Reentrant Fns ------===//
//
// Part of the V6C backend for LLVM.
//
// O10: Static Stack Allocation for Non-Reentrant Functions.
//
// For functions that are provably non-reentrant (norecurse, not reachable
// from interrupt handlers, address not taken), replace the stack frame
// with a statically-allocated global memory region.  This turns expensive
// SP-relative spill/reload sequences (52cc+) into direct global memory
// accesses via STA/LDA/SHLD/LHLD (16-24cc).
//
// Algorithm:
//   1. On first invocation, compute interrupt reachability via BFS from
//      all interrupt-attributed functions.
//   2. For each eligible function: create a per-function global
//      @__v6c_ss.<funcname>, record the frame-index-to-offset mapping
//      in V6CMachineFunctionInfo, and zero out frame object sizes so PEI
//      skips prologue/epilogue SP adjustment.
//
//===----------------------------------------------------------------------===//

#include "V6C.h"
#include "V6CMachineFunctionInfo.h"
#include "MCTargetDesc/V6CMCTargetDesc.h"

#include "llvm/CodeGen/MachineFrameInfo.h"
#include "llvm/CodeGen/MachineFunction.h"
#include "llvm/CodeGen/MachineFunctionPass.h"
#include "llvm/CodeGen/MachineModuleInfo.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/GlobalVariable.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Module.h"
#include "llvm/Support/Debug.h"

#include <queue>

using namespace llvm;

#define DEBUG_TYPE "v6c-static-stack-alloc"

namespace {

class V6CStaticStackAlloc : public MachineFunctionPass {
public:
  static char ID;
  V6CStaticStackAlloc() : MachineFunctionPass(ID) {}

  StringRef getPassName() const override {
    return "V6C Static Stack Allocation (O10)";
  }

  void getAnalysisUsage(AnalysisUsage &AU) const override {
    AU.addRequired<MachineModuleInfoWrapperPass>();
    AU.setPreservesAll();
    MachineFunctionPass::getAnalysisUsage(AU);
  }

  bool runOnMachineFunction(MachineFunction &MF) override;

private:
  /// Whether module-level analysis has been performed.
  bool ModuleAnalyzed = false;

  /// Set of functions reachable from interrupt handlers.
  SmallPtrSet<const Function *, 16> InterruptReachable;

  void analyzeInterruptReachability(Module &M);
  bool isFunctionEligible(const Function &F, const MachineFunction &MF) const;
};

} // end anonymous namespace

char V6CStaticStackAlloc::ID = 0;

/// BFS from interrupt-attributed functions to find all transitively
/// reachable functions.
void V6CStaticStackAlloc::analyzeInterruptReachability(Module &M) {
  std::queue<const Function *> Worklist;

  for (const Function &F : M) {
    if (F.hasFnAttribute("interrupt")) {
      InterruptReachable.insert(&F);
      Worklist.push(&F);
    }
  }

  while (!Worklist.empty()) {
    const Function *F = Worklist.front();
    Worklist.pop();

    for (const BasicBlock &BB : *F) {
      for (const Instruction &I : BB) {
        const auto *CB = dyn_cast<CallBase>(&I);
        if (!CB)
          continue;
        const Function *Callee = CB->getCalledFunction();
        if (!Callee || Callee->isDeclaration())
          continue;
        if (InterruptReachable.insert(Callee).second)
          Worklist.push(Callee);
      }
    }
  }

  LLVM_DEBUG(dbgs() << "V6CStaticStackAlloc: " << InterruptReachable.size()
                    << " functions reachable from interrupt handlers\n");
}

bool V6CStaticStackAlloc::isFunctionEligible(
    const Function &F, const MachineFunction &MF) const {
  // Must have norecurse attribute (inferred by PostOrderFunctionAttrs at -O2).
  if (!F.hasFnAttribute(Attribute::NoRecurse))
    return false;

  // Must not be an interrupt handler itself.
  if (F.hasFnAttribute("interrupt"))
    return false;

  // Must not be reachable from any interrupt handler.
  if (InterruptReachable.count(&F))
    return false;

  // Must not have its address taken (could be called via function pointer
  // from interrupt context).
  if (F.hasAddressTaken())
    return false;

  // Must have non-fixed frame objects (spill slots or locals).
  const MachineFrameInfo &MFI = MF.getFrameInfo();
  bool HasNonFixedObjects = false;
  for (int I = 0, E = MFI.getObjectIndexEnd(); I < E; ++I) {
    if (!MFI.isDeadObjectIndex(I) && MFI.getObjectSize(I) > 0) {
      HasNonFixedObjects = true;
      break;
    }
  }
  if (!HasNonFixedObjects)
    return false;

  return true;
}

bool V6CStaticStackAlloc::runOnMachineFunction(MachineFunction &MF) {
  Module &M = *MF.getFunction().getParent();

  // Perform module-level analysis once.
  if (!ModuleAnalyzed) {
    analyzeInterruptReachability(M);
    ModuleAnalyzed = true;
  }

  const Function &F = MF.getFunction();
  if (!isFunctionEligible(F, MF))
    return false;

  MachineFrameInfo &MFI = MF.getFrameInfo();
  auto *FuncInfo = MF.getInfo<V6CMachineFunctionInfo>();

  LLVM_DEBUG(dbgs() << "V6CStaticStackAlloc: allocating static frame for "
                    << F.getName() << "\n");

  // First pass: compute total size needed for this function's frame objects.
  int64_t TotalSize = 0;
  for (int I = 0, E = MFI.getObjectIndexEnd(); I < E; ++I) {
    if (MFI.isDeadObjectIndex(I))
      continue;
    int64_t ObjSize = MFI.getObjectSize(I);
    if (ObjSize > 0)
      TotalSize += ObjSize;
  }

  if (TotalSize == 0)
    return false;

  // Create a per-function global variable with the exact size needed.
  LLVMContext &Ctx = M.getContext();
  auto *ArrTy = ArrayType::get(Type::getInt8Ty(Ctx), TotalSize);
  std::string GVName = ("__v6c_ss." + F.getName()).str();
  auto *GV = new GlobalVariable(
      M, ArrTy, /*isConstant=*/false, GlobalValue::InternalLinkage,
      ConstantAggregateZero::get(ArrTy), GVName);
  GV->setAlignment(Align(1));

  // Second pass: assign static offsets for each non-fixed, non-dead
  // frame object.
  int64_t Offset = 0;
  for (int I = 0, E = MFI.getObjectIndexEnd(); I < E; ++I) {
    if (MFI.isDeadObjectIndex(I))
      continue;
    int64_t ObjSize = MFI.getObjectSize(I);
    if (ObjSize <= 0)
      continue;

    FuncInfo->addStaticSlot(I, Offset);
    Offset += ObjSize;

    LLVM_DEBUG(dbgs() << "  FI#" << I << ": size=" << ObjSize
                      << " -> static offset " << Offset - ObjSize << "\n");
  }

  // Mark the function for static stack usage.
  FuncInfo->setStaticStack(GV);

  // Zero out frame object sizes so PEI computes StackSize = 0.
  // This eliminates prologue/epilogue SP adjustment.
  for (int I = 0, E = MFI.getObjectIndexEnd(); I < E; ++I) {
    if (!MFI.isDeadObjectIndex(I) && MFI.getObjectSize(I) > 0) {
      MFI.setObjectSize(I, 0);
    }
  }

  LLVM_DEBUG(dbgs() << "  Static stack size: " << TotalSize << " bytes\n");

  return true;
}

FunctionPass *llvm::createV6CStaticStackAllocPass() {
  return new V6CStaticStackAlloc();
}
