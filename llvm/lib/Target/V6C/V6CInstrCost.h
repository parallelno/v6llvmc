//===-- V6CInstrCost.h - V6C Dual Cost Model --------------------*- C++ -*-===//
//
// Part of the V6C backend for LLVM.
//
//===----------------------------------------------------------------------===//
//
// Dual cost model (Bytes + Cycles) for V6C optimization decisions.
// Inspired by llvm-mos MOSInstrCost.
//
// Usage:
//   V6COptMode Mode = getV6COptMode(MF);
//   V6CInstrCost SeqA = V6CCost::INX * 3;
//   V6CInstrCost SeqB = V6CCost::LXI + V6CCost::DAD;
//   if (SeqA.isCheaperThan(SeqB, Mode)) { /* use INX chain */ }
//
//===----------------------------------------------------------------------===//

#ifndef LLVM_LIB_TARGET_V6C_V6CINSTRCOST_H
#define LLVM_LIB_TARGET_V6C_V6CINSTRCOST_H

#include "llvm/CodeGen/MachineFunction.h"
#include <cstdint>

namespace llvm {

/// Optimization mode derived from function attributes.
enum class V6COptMode {
  Speed,    // -O2/-O3: cycles dominate, bytes break ties
  Size,     // -Os/-Oz: bytes dominate, cycles break ties
  Balanced  // -O1 or default: sum of bytes + cycles
};

/// Derive the optimization mode from a MachineFunction's attributes.
inline V6COptMode getV6COptMode(const MachineFunction &MF) {
  const Function &F = MF.getFunction();
  if (F.hasMinSize() || F.hasOptSize())
    return V6COptMode::Size;
  if (MF.getTarget().getOptLevel() >= CodeGenOptLevel::Default)
    return V6COptMode::Speed;
  return V6COptMode::Balanced;
}

/// Dual cost: bytes and cycles for an instruction or sequence.
struct V6CInstrCost {
  int32_t Bytes = 0;
  int32_t Cycles = 0;

  constexpr V6CInstrCost() = default;
  constexpr V6CInstrCost(int32_t B, int32_t C) : Bytes(B), Cycles(C) {}

  /// Compose into a single comparable value based on optimization mode.
  /// - Speed: (Cycles << 16) + Bytes — cycles dominate
  /// - Size:  (Bytes << 16) + Cycles — bytes dominate
  /// - Balanced: Bytes + Cycles
  int64_t value(V6COptMode Mode) const {
    switch (Mode) {
    case V6COptMode::Speed:
      return (static_cast<int64_t>(Cycles) << 16) + Bytes;
    case V6COptMode::Size:
      return (static_cast<int64_t>(Bytes) << 16) + Cycles;
    case V6COptMode::Balanced:
      return static_cast<int64_t>(Bytes) + Cycles;
    }
    llvm_unreachable("invalid V6COptMode");
  }

  bool isCheaperThan(const V6CInstrCost &RHS, V6COptMode Mode) const {
    return value(Mode) < RHS.value(Mode);
  }

  bool isCheaperOrEqual(const V6CInstrCost &RHS, V6COptMode Mode) const {
    return value(Mode) <= RHS.value(Mode);
  }

  V6CInstrCost operator+(const V6CInstrCost &RHS) const {
    return {Bytes + RHS.Bytes, Cycles + RHS.Cycles};
  }

  V6CInstrCost operator*(int N) const {
    return {Bytes * N, Cycles * N};
  }
};

/// Pre-defined costs for common V6C (8080) instructions.
/// Values from V6CSchedule.td and V6CInstructionTimings.md.
namespace V6CCost {
  constexpr V6CInstrCost INX{1, 8};       // INX/DCX rp
  constexpr V6CInstrCost LXI{3, 12};      // LXI rp, d16
  constexpr V6CInstrCost DAD{1, 12};      // DAD rp
  constexpr V6CInstrCost MOVrr{1, 4};     // MOV r, r
  constexpr V6CInstrCost MOVrM{1, 8};     // MOV r, M
  constexpr V6CInstrCost MOVMr{1, 8};     // MOV M, r
  constexpr V6CInstrCost MVI{2, 8};       // MVI r, d8
  constexpr V6CInstrCost ALUreg{1, 4};    // ADD/SUB/ANA/ORA/XRA/CMP r
  constexpr V6CInstrCost ALUimm{2, 8};    // ADI/SUI/ANI/ORI/XRI/CPI d8
  constexpr V6CInstrCost ALUmem{1, 8};    // ADD/SUB/ANA/ORA/XRA/CMP M
  constexpr V6CInstrCost INR{1, 8};       // INR/DCR r
  constexpr V6CInstrCost PUSH{1, 16};     // PUSH rp
  constexpr V6CInstrCost POP{1, 12};      // POP rp
  constexpr V6CInstrCost Jcc{3, 12};      // Jcc addr / JMP addr
  constexpr V6CInstrCost CALL{3, 24};     // CALL addr
  constexpr V6CInstrCost RET{1, 12};      // RET
  constexpr V6CInstrCost LDA{3, 16};      // LDA addr
  constexpr V6CInstrCost STA{3, 16};      // STA addr
  constexpr V6CInstrCost LHLD{3, 20};     // LHLD addr
  constexpr V6CInstrCost SHLD{3, 20};     // SHLD addr
  constexpr V6CInstrCost XCHG{1, 4};      // XCHG
} // namespace V6CCost

} // namespace llvm

#endif // LLVM_LIB_TARGET_V6C_V6CINSTRCOST_H
