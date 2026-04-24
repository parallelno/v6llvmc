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

  /// Map from frame index to byte size.  Populated alongside StaticSlots
  /// so the backing global can be recomputed after passes (e.g., O61)
  /// rewrite some slots away.
  DenseMap<int, int64_t> StaticSizes;

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

  /// Replace the backing global (e.g., after repacking).  Passing
  /// nullptr clears the static-stack flag so subsequent consumers
  /// (eliminateFrameIndex, AsmPrinter) treat the function as having
  /// no static stack.
  void replaceStaticStackGV(GlobalVariable *GV) {
    StaticStackGV = GV;
    if (!GV) {
      UseStaticStack = false;
      StaticSlots.clear();
      StaticSizes.clear();
    }
  }

  GlobalVariable *getStaticStackGV() const { return StaticStackGV; }

  void addStaticSlot(int FI, int64_t Offset, int64_t Size) {
    StaticSlots[FI] = Offset;
    StaticSizes[FI] = Size;
  }

  bool hasStaticSlot(int FI) const { return StaticSlots.count(FI); }

  int64_t getStaticOffset(int FI) const {
    auto It = StaticSlots.find(FI);
    assert(It != StaticSlots.end() && "Frame index not in static map");
    return It->second;
  }

  int64_t getStaticSize(int FI) const {
    auto It = StaticSizes.find(FI);
    assert(It != StaticSizes.end() && "Frame index not in static map");
    return It->second;
  }

  /// Iterate (FI, offset) entries for live static slots.
  const DenseMap<int, int64_t> &getStaticSlotMap() const { return StaticSlots; }

  /// Remove a single FI from the static map without re-layout.  Offsets
  /// of surviving slots are left unchanged; the caller is expected to
  /// follow up with a repack if desired.
  void eraseStaticSlot(int FI) {
    StaticSlots.erase(FI);
    StaticSizes.erase(FI);
  }

  /// Reassign the offset of an existing FI (used during repack).
  void setStaticOffset(int FI, int64_t Offset) {
    assert(StaticSlots.count(FI) && "Frame index not in static map");
    StaticSlots[FI] = Offset;
  }
};

} // namespace llvm

#endif // LLVM_LIB_TARGET_V6C_V6CMACHINEFUNCTIONINFO_H
