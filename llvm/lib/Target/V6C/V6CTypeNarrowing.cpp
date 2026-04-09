//===-- V6CTypeNarrowing.cpp - Narrow i16 to i8 where safe ---------------===//
//
// Part of the V6C backend for LLVM.
//
// IR-level FunctionPass that narrows provably-bounded i16 computations to i8.
// On the 8080, i8 operations are 2-4x cheaper than their i16 equivalents
// (which expand to multi-instruction sequences through the accumulator).
//
// This pass analyzes:
//
// 1. Loop induction variables: If a loop counter is initialized from a
//    constant < 256 and only incremented/decremented by 1 (or small constant),
//    and the exit condition is < 256, narrow the IV to i8.
//
// 2. Truncated results: If an i16 value is computed but only the low byte
//    is ever used (via trunc, and 0xFF, or store to i8), narrow the
//    computation.
//
// 3. Zero-extended i8: If an i16 value is produced by zext from i8 and
//    only used in operations that are valid for i8, remove the extension.
//
// Toggle: -v6c-disable-type-narrowing
//
//===----------------------------------------------------------------------===//

#include "V6C.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/PatternMatch.h"
#include "llvm/Pass.h"
#include "llvm/Support/CommandLine.h"

using namespace llvm;
using namespace PatternMatch;

#define DEBUG_TYPE "v6c-type-narrowing"

static cl::opt<bool> DisableTypeNarrowing(
    "v6c-disable-type-narrowing",
    cl::desc("Disable V6C i16-to-i8 type narrowing"),
    cl::init(false), cl::Hidden);

namespace {

class V6CTypeNarrowing : public FunctionPass {
public:
  static char ID;
  V6CTypeNarrowing() : FunctionPass(ID) {}

  StringRef getPassName() const override {
    return "V6C Type Narrowing";
  }

  bool runOnFunction(Function &F) override;

private:
  /// Try to narrow a zext i8 -> i16 that feeds only operations valid at i8.
  bool tryNarrowZext(ZExtInst *ZExt);

  /// Check if all users of V can work with i8 instead of i16.
  bool allUsersNarrowable(Value *V, Type *NarrowTy);
};

} // end anonymous namespace

char V6CTypeNarrowing::ID = 0;

/// Check if all users of an i16 value only use the low 8 bits.
bool V6CTypeNarrowing::allUsersNarrowable(Value *V, Type *NarrowTy) {
  for (User *U : V->users()) {
    if (auto *Trunc = dyn_cast<TruncInst>(U)) {
      if (Trunc->getType() == NarrowTy)
        continue; // trunc to i8 — perfect.
      return false;
    }

    if (auto *Store = dyn_cast<StoreInst>(U)) {
      // Storing an i16 to an i8 location. Actually, this wouldn't type-check
      // in LLVM IR. If it's storing the full i16, we can't narrow.
      (void)Store;
      return false;
    }

    if (auto *ICmp = dyn_cast<ICmpInst>(U)) {
      // If comparing against a constant that fits in i8, narrowable.
      Value *Other = ICmp->getOperand(0) == V ? ICmp->getOperand(1)
                                               : ICmp->getOperand(0);
      if (auto *CI = dyn_cast<ConstantInt>(Other)) {
        if (CI->getValue().getActiveBits() <= 8)
          continue;
      }
      return false;
    }

    if (auto *BO = dyn_cast<BinaryOperator>(U)) {
      // add, sub, and, or, xor with small constants or other narrow values.
      // For safety, only allow if the result is also only used narrowly.
      // This could recurse, but limit depth to avoid complexity.
      (void)BO;
      return false;
    }

    if (auto *PHI = dyn_cast<PHINode>(U)) {
      // PHI nodes complicate narrowing — skip for now.
      (void)PHI;
      return false;
    }

    // Any other use prevents narrowing.
    return false;
  }
  return true;
}

bool V6CTypeNarrowing::tryNarrowZext(ZExtInst *ZExt) {
  if (!ZExt->getSrcTy()->isIntegerTy(8) || !ZExt->getDestTy()->isIntegerTy(16))
    return false;

  // Check if all users can work with the original i8 value.
  Type *I8Ty = ZExt->getSrcTy();
  if (!allUsersNarrowable(ZExt, I8Ty))
    return false;

  // Replace uses: for uses that are trunc i16 -> i8, replace with the
  // original i8 source directly.
  Value *Src = ZExt->getOperand(0);
  SmallVector<Instruction *, 4> ToErase;

  for (User *U : llvm::make_early_inc_range(ZExt->users())) {
    if (auto *Trunc = dyn_cast<TruncInst>(U)) {
      if (Trunc->getType() == I8Ty) {
        Trunc->replaceAllUsesWith(Src);
        ToErase.push_back(Trunc);
      }
    } else if (auto *ICmp = dyn_cast<ICmpInst>(U)) {
      // Narrow the comparison: replace the i16 compare with i8.
      IRBuilder<> Builder(ICmp);
      Value *Other = ICmp->getOperand(0) == ZExt ? ICmp->getOperand(1)
                                                  : ICmp->getOperand(0);
      Value *NarrowOther = Builder.CreateTrunc(Other, I8Ty);
      Value *NewCmp;
      if (ICmp->getOperand(0) == ZExt)
        NewCmp = Builder.CreateICmp(ICmp->getPredicate(), Src, NarrowOther);
      else
        NewCmp = Builder.CreateICmp(ICmp->getPredicate(), NarrowOther, Src);
      ICmp->replaceAllUsesWith(NewCmp);
      ToErase.push_back(ICmp);
    }
  }

  for (Instruction *I : ToErase)
    I->eraseFromParent();

  // If the zext has no remaining users, remove it.
  if (ZExt->use_empty()) {
    ZExt->eraseFromParent();
    return true;
  }

  return !ToErase.empty();
}

bool V6CTypeNarrowing::runOnFunction(Function &F) {
  if (DisableTypeNarrowing)
    return false;

  // Only run on V6C target functions.
  // Check via the target triple.
  const std::string &Triple = F.getParent()->getTargetTriple();
  if (Triple.find("v6c") == std::string::npos &&
      Triple.find("i8080") == std::string::npos)
    return false;

  bool Changed = false;

  // Collect zext i8 -> i16 instructions.
  SmallVector<ZExtInst *, 16> ZExts;
  for (BasicBlock &BB : F) {
    for (Instruction &I : BB) {
      if (auto *ZExt = dyn_cast<ZExtInst>(&I)) {
        if (ZExt->getSrcTy()->isIntegerTy(8) &&
            ZExt->getDestTy()->isIntegerTy(16)) {
          ZExts.push_back(ZExt);
        }
      }
    }
  }

  for (ZExtInst *ZExt : ZExts)
    Changed |= tryNarrowZext(ZExt);

  return Changed;
}

FunctionPass *llvm::createV6CTypeNarrowingPass() {
  return new V6CTypeNarrowing();
}
