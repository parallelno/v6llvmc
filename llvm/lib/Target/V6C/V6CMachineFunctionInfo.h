//===-- V6CMachineFunctionInfo.h - V6C Machine Function Info -----*- C++ -*-===//
//
// Part of the V6C backend for LLVM.
//
// Per-function metadata for the static stack allocation pass (O10).
// Stores the mapping from frame indices to static global offsets.
//
//===----------------------------------------------------------------------===//

#ifndef LLVM_LIB_TARGET_V6C_V6CMACHINEFUNCTIONINFO_H
#define LLVM_LIB_TARGET_V6C_V6CMACHINEFUNCTIONINFO_H

#include "llvm/ADT/DenseMap.h"
#include "llvm/CodeGen/MachineFunction.h"
#include "llvm/IR/GlobalVariable.h"

namespace llvm {

class V6CMachineFunctionInfo : public MachineFunctionInfo {
  /// Whether this function uses static stack allocation.
  bool UseStaticStack = false;

  /// The global variable backing the static stack region.
  GlobalVariable *StaticStackGV = nullptr;

  /// Map from frame index to byte offset within the static stack global.
  DenseMap<int, int64_t> StaticSlots;

public:
  V6CMachineFunctionInfo() = default;
  V6CMachineFunctionInfo(const Function &F, const TargetSubtargetInfo *STI) {}

  MachineFunctionInfo *
  clone(BumpPtrAllocator &Allocator, MachineFunction &DestMF,
        const DenseMap<MachineBasicBlock *, MachineBasicBlock *> &Src2DstMBB)
      const override {
    return DestMF.cloneInfo<V6CMachineFunctionInfo>(*this);
  }

  bool hasStaticStack() const { return UseStaticStack; }

  void setStaticStack(GlobalVariable *GV) {
    UseStaticStack = true;
    StaticStackGV = GV;
  }

  GlobalVariable *getStaticStackGV() const { return StaticStackGV; }

  void addStaticSlot(int FI, int64_t Offset) { StaticSlots[FI] = Offset; }

  bool hasStaticSlot(int FI) const { return StaticSlots.count(FI); }

  int64_t getStaticOffset(int FI) const {
    auto It = StaticSlots.find(FI);
    assert(It != StaticSlots.end() && "Frame index not in static map");
    return It->second;
  }
};

} // namespace llvm

#endif // LLVM_LIB_TARGET_V6C_V6CMACHINEFUNCTIONINFO_H
