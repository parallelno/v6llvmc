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

  /// Try to narrow an i16 loop induction PHI to i8 when its range provably
  /// fits in 8 bits (constant start in [0,255], step ±1, exit on equality
  /// with a constant that fits in i8, including via inttoptr+icmp-null).
  bool tryNarrowLoopIV(PHINode *PN);
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

  // Collect i16 PHI nodes that look like loop induction variables and try
  // to narrow them to i8. LSR commonly emits a `phi i16 [..., C]` down-counter
  // even when C fits in a byte, which costs ~14cc per iter on the 8080
  // (DCX BC + MOV A,B + ORA C + JNZ) vs ~4cc for an i8 counter (DCR r + JNZ).
  SmallVector<PHINode *, 8> I16Phis;
  for (BasicBlock &BB : F) {
    for (PHINode &PN : BB.phis()) {
      if (PN.getType()->isIntegerTy(16))
        I16Phis.push_back(&PN);
    }
  }
  for (PHINode *PN : I16Phis)
    Changed |= tryNarrowLoopIV(PN);

  return Changed;
}

bool V6CTypeNarrowing::tryNarrowLoopIV(PHINode *PN) {
  if (PN->getNumIncomingValues() != 2)
    return false;

  // Find constant init and recurrence step.
  ConstantInt *InitC = nullptr;
  Instruction *StepI = nullptr;
  BasicBlock *PreBB = nullptr;
  BasicBlock *LatchBB = nullptr;
  for (unsigned i = 0; i < 2; ++i) {
    Value *V = PN->getIncomingValue(i);
    BasicBlock *BB = PN->getIncomingBlock(i);
    if (auto *CI = dyn_cast<ConstantInt>(V)) {
      if (InitC)
        return false; // two constant operands -> not a typical IV
      InitC = CI;
      PreBB = BB;
    } else if (auto *I = dyn_cast<Instruction>(V)) {
      if (StepI)
        return false;
      StepI = I;
      LatchBB = BB;
    } else {
      return false;
    }
  }
  if (!InitC || !StepI || !PreBB || !LatchBB)
    return false;
  if (InitC->getValue().getActiveBits() > 8)
    return false;

  // Recurrence must be `add i16 %PN, K` with K = -1 (down-counter) or
  // K = +1 (up-counter). Both keep the IV inside [0, 255] when the init
  // and exit bound both fit in i8 and the sequence walks from one to the
  // other without crossing 256 (verified per-comparison below).
  auto *AddOp = dyn_cast<BinaryOperator>(StepI);
  if (!AddOp || AddOp->getOpcode() != Instruction::Add)
    return false;
  if (AddOp->getParent() != LatchBB)
    return false;
  Value *AddLHS = AddOp->getOperand(0);
  Value *AddRHS = AddOp->getOperand(1);
  ConstantInt *StepC = nullptr;
  if (AddLHS == PN)
    StepC = dyn_cast<ConstantInt>(AddRHS);
  else if (AddRHS == PN)
    StepC = dyn_cast<ConstantInt>(AddLHS);
  else
    return false;
  if (!StepC)
    return false;
  int64_t Step = StepC->getSExtValue();
  if (Step != -1 && Step != 1)
    return false;

  // PN's only user (besides the backedge from AddOp) must be... well, AddOp.
  for (User *U : PN->users()) {
    if (U != AddOp)
      return false;
  }

  // AddOp's users (apart from feeding back into PN) must be one of:
  //   * icmp eq/ne i16 %add, <constant fitting in i8>
  //   * inttoptr i16 %add to ptr, followed only by icmp eq/ne ptr %., null
  //
  // For step +1 the comparison constant must additionally be >= init (in
  // i16) so that the visited values [init, bound] all fit in i8. For step
  // -1 they fit by construction (init ≤ 255, decrement keeps us in
  // [bound, init] ⊆ [0, 255] as long as bound ≤ init; the canonical
  // shape produced by LSR uses bound = 0). For step +1 we reject the
  // inttoptr+icmp-null shape entirely since bound = 0 would force a
  // zero-iteration loop.
  uint64_t Init = InitC->getZExtValue();
  SmallVector<ICmpInst *, 2> CmpsDirect;
  SmallVector<ICmpInst *, 2> CmpsViaPtr;
  SmallVector<IntToPtrInst *, 2> IntToPtrs;
  for (User *U : AddOp->users()) {
    if (U == PN)
      continue;
    if (auto *Cmp = dyn_cast<ICmpInst>(U)) {
      if (!Cmp->isEquality())
        return false;
      Value *Other = Cmp->getOperand(0) == AddOp ? Cmp->getOperand(1)
                                                  : Cmp->getOperand(0);
      auto *OtherC = dyn_cast<ConstantInt>(Other);
      if (!OtherC || OtherC->getValue().getActiveBits() > 8)
        return false;
      uint64_t Bound = OtherC->getZExtValue();
      if (Step == 1 && Bound < Init)
        return false; // wrapping up-counter — not safe to narrow.
      if (Step == -1 && Bound > Init)
        return false; // wrapping down-counter — not safe to narrow.
      CmpsDirect.push_back(Cmp);
      continue;
    }
    if (auto *I2P = dyn_cast<IntToPtrInst>(U)) {
      if (Step != -1)
        return false; // ptr-null exit only meaningful for down-to-zero.
      for (User *UU : I2P->users()) {
        auto *Cmp = dyn_cast<ICmpInst>(UU);
        if (!Cmp || !Cmp->isEquality())
          return false;
        Value *Other = Cmp->getOperand(0) == I2P ? Cmp->getOperand(1)
                                                  : Cmp->getOperand(0);
        if (!isa<ConstantPointerNull>(Other))
          return false;
        CmpsViaPtr.push_back(Cmp);
      }
      IntToPtrs.push_back(I2P);
      continue;
    }
    return false;
  }

  // All clear — rewrite.
  Type *I8Ty = Type::getInt8Ty(PN->getContext());

  // New i8 PHI in the same header, inserted before the old PN.
  IRBuilder<> PHBuilder(PN);
  PHINode *NewPN = PHBuilder.CreatePHI(I8Ty, 2, PN->getName() + ".narrow");
  NewPN->addIncoming(
      ConstantInt::get(I8Ty, InitC->getZExtValue() & 0xff), PreBB);

  // New i8 increment/decrement at the same point as the old AddOp.
  IRBuilder<> AddBuilder(AddOp);
  Value *NewAdd = AddBuilder.CreateAdd(
      NewPN, ConstantInt::getSigned(I8Ty, Step),
      AddOp->getName() + ".narrow");
  NewPN->addIncoming(NewAdd, LatchBB);

  // Rewrite direct icmp users.
  for (ICmpInst *Cmp : CmpsDirect) {
    IRBuilder<> B(Cmp);
    Value *Other = Cmp->getOperand(0) == AddOp ? Cmp->getOperand(1)
                                                : Cmp->getOperand(0);
    auto *OtherC = cast<ConstantInt>(Other);
    Value *NewOther =
        ConstantInt::get(I8Ty, OtherC->getZExtValue() & 0xff);
    Value *NewCmp = (Cmp->getOperand(0) == AddOp)
                        ? B.CreateICmp(Cmp->getPredicate(), NewAdd, NewOther)
                        : B.CreateICmp(Cmp->getPredicate(), NewOther, NewAdd);
    Cmp->replaceAllUsesWith(NewCmp);
    Cmp->eraseFromParent();
  }

  // Rewrite inttoptr+icmp-null chains to i8 compare against 0.
  for (ICmpInst *Cmp : CmpsViaPtr) {
    IRBuilder<> B(Cmp);
    Value *Zero = ConstantInt::get(I8Ty, 0);
    Value *NewCmp = B.CreateICmp(Cmp->getPredicate(), NewAdd, Zero);
    Cmp->replaceAllUsesWith(NewCmp);
    Cmp->eraseFromParent();
  }
  for (IntToPtrInst *I2P : IntToPtrs) {
    if (I2P->use_empty())
      I2P->eraseFromParent();
  }

  // Old AddOp/PN must be dead now — erase.
  if (!AddOp->use_empty())
    return true; // shouldn't happen with the checks above, but stay safe.
  AddOp->eraseFromParent();
  if (PN->use_empty())
    PN->eraseFromParent();
  return true;
}

FunctionPass *llvm::createV6CTypeNarrowingPass() {
  return new V6CTypeNarrowing();
}
