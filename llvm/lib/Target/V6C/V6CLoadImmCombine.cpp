//===-- V6CLoadImmCombine.cpp - Combine redundant MVI instructions --------===//
//
// Part of the V6C backend for LLVM.
//
// Post-RA peephole: Replace redundant MVI r, imm instructions when the
// value is already available in another register (→ MOV r, r') or the
// target register holds imm±1 (→ INR r / DCR r).
//
// Algorithm (per basic block, no inter-BB analysis):
//   KnownVal[r] = nullopt for all r
//   for each MI:
//     if MI is MVI r, imm:
//       if ∃ r' ≠ r with KnownVal[r'] == imm: replace with MOV r, r'
//       else if KnownVal[r] == imm - 1: replace with INR r
//       else if KnownVal[r] == imm + 1: replace with DCR r
//       KnownVal[r] = imm
//     else: update tracking (invalidate when register modified)
//
// Savings: 1 byte per MVI→MOV, 1 byte per MVI→INR/DCR (same cycle cost).
//
//===----------------------------------------------------------------------===//

#include "V6C.h"
#include "MCTargetDesc/V6CMCTargetDesc.h"
#include "llvm/CodeGen/MachineFunctionPass.h"
#include "llvm/CodeGen/MachineInstrBuilder.h"
#include "llvm/CodeGen/MachineRegisterInfo.h"
#include "llvm/CodeGen/TargetInstrInfo.h"
#include "llvm/CodeGen/TargetSubtargetInfo.h"
#include "llvm/Support/CommandLine.h"

#include <optional>

using namespace llvm;

#define DEBUG_TYPE "v6c-load-imm-combine"

static cl::opt<bool> DisableLoadImmCombine(
    "v6c-disable-load-imm-combine",
    cl::desc("Disable V6C load-immediate combining"),
    cl::init(false), cl::Hidden);

namespace {

class V6CLoadImmCombine : public MachineFunctionPass {
public:
  static char ID;
  V6CLoadImmCombine() : MachineFunctionPass(ID) {}

  StringRef getPassName() const override {
    return "V6C Load-Immediate Combining";
  }

  bool runOnMachineFunction(MachineFunction &MF) override;

private:
  // Tracked registers: A, B, C, D, E, H, L (indices 0-6).
  static constexpr unsigned NumTracked = 7;
  static constexpr MCRegister TrackedRegs[NumTracked] = {
      V6C::A, V6C::B, V6C::C, V6C::D, V6C::E, V6C::H, V6C::L};

  std::optional<int64_t> KnownVal[NumTracked];

  /// Map physical register to tracking index, or -1 if not tracked.
  static int regIndex(MCRegister Reg) {
    for (unsigned I = 0; I < NumTracked; ++I)
      if (TrackedRegs[I] == Reg)
        return I;
    return -1;
  }

  /// Invalidate a single register.
  void invalidate(MCRegister Reg) {
    int Idx = regIndex(Reg);
    if (Idx >= 0)
      KnownVal[Idx] = std::nullopt;
  }

  /// Invalidate all tracked registers.
  void invalidateAll() {
    for (unsigned I = 0; I < NumTracked; ++I)
      KnownVal[I] = std::nullopt;
  }

  /// Invalidate register and its sub/super-registers relevant to tracking.
  void invalidateWithSubSuper(MCRegister Reg) {
    invalidate(Reg);
    // If a 16-bit pair is written, invalidate both halves.
    if (Reg == V6C::BC) { invalidate(V6C::B); invalidate(V6C::C); }
    if (Reg == V6C::DE) { invalidate(V6C::D); invalidate(V6C::E); }
    if (Reg == V6C::HL) { invalidate(V6C::H); invalidate(V6C::L); }
    // If an 8-bit register is written, no pair invalidation needed
    // (the pair "value" is just both halves).
  }

  /// Find a tracked register (other than Exclude) that holds Val.
  /// Prefer non-A registers to avoid accumulator contention.
  MCRegister findRegWithValue(int64_t Val, MCRegister Exclude) const {
    // First pass: non-A registers.
    for (unsigned I = 1; I < NumTracked; ++I) {
      if (TrackedRegs[I] == Exclude)
        continue;
      if (KnownVal[I] && *KnownVal[I] == Val)
        return TrackedRegs[I];
    }
    // Second pass: A register.
    if (TrackedRegs[0] != Exclude && KnownVal[0] && *KnownVal[0] == Val)
      return TrackedRegs[0];
    return MCRegister();
  }

  bool processBlock(MachineBasicBlock &MBB);
};

} // end anonymous namespace

char V6CLoadImmCombine::ID = 0;

bool V6CLoadImmCombine::processBlock(MachineBasicBlock &MBB) {
  bool Changed = false;
  const TargetInstrInfo &TII = *MBB.getParent()->getSubtarget().getInstrInfo();

  invalidateAll();

  for (MachineInstr &MI : llvm::make_early_inc_range(MBB)) {
    unsigned Opc = MI.getOpcode();

    // --- MVI r, imm: main optimization target ---
    if (Opc == V6C::MVIr) {
      MCRegister DstReg = MI.getOperand(0).getReg();
      // MVI can have non-immediate operands (e.g., global lo8/hi8 exprs).
      if (!MI.getOperand(1).isImm()) {
        invalidate(DstReg);
        continue;
      }
      int64_t Imm = MI.getOperand(1).getImm() & 0xFF;
      int DstIdx = regIndex(DstReg);

      // Try 1: Another register holds the same value → MOV r, r'
      MCRegister SrcReg = findRegWithValue(Imm, DstReg);
      if (SrcReg.isValid()) {
        BuildMI(MBB, MI, MI.getDebugLoc(), TII.get(V6C::MOVrr), DstReg)
            .addReg(SrcReg);
        MI.eraseFromParent();
        if (DstIdx >= 0)
          KnownVal[DstIdx] = Imm;
        Changed = true;
        continue;
      }

      // Try 2: Same register holds imm-1 → INR r
      if (DstIdx >= 0 && KnownVal[DstIdx] &&
          ((*KnownVal[DstIdx]) & 0xFF) == ((Imm - 1) & 0xFF)) {
        BuildMI(MBB, MI, MI.getDebugLoc(), TII.get(V6C::INRr), DstReg)
            .addReg(DstReg);
        MI.eraseFromParent();
        KnownVal[DstIdx] = Imm;
        Changed = true;
        continue;
      }

      // Try 3: Same register holds imm+1 → DCR r
      if (DstIdx >= 0 && KnownVal[DstIdx] &&
          ((*KnownVal[DstIdx]) & 0xFF) == ((Imm + 1) & 0xFF)) {
        BuildMI(MBB, MI, MI.getDebugLoc(), TII.get(V6C::DCRr), DstReg)
            .addReg(DstReg);
        MI.eraseFromParent();
        KnownVal[DstIdx] = Imm;
        Changed = true;
        continue;
      }

      // No optimization — keep MVI and record value.
      if (DstIdx >= 0)
        KnownVal[DstIdx] = Imm;
      continue;
    }

    // --- MOV r, r': propagate known value ---
    if (Opc == V6C::MOVrr) {
      MCRegister DstReg = MI.getOperand(0).getReg();
      MCRegister SrcReg = MI.getOperand(1).getReg();
      int DstIdx = regIndex(DstReg);
      int SrcIdx = regIndex(SrcReg);
      if (DstIdx >= 0) {
        if (SrcIdx >= 0 && KnownVal[SrcIdx])
          KnownVal[DstIdx] = *KnownVal[SrcIdx];
        else
          KnownVal[DstIdx] = std::nullopt;
      }
      continue;
    }

    // --- MOV r, M: load from memory invalidates dst ---
    if (Opc == V6C::MOVrM) {
      MCRegister DstReg = MI.getOperand(0).getReg();
      invalidate(DstReg);
      continue;
    }

    // --- LXI rp, imm16: set both sub-registers ---
    if (Opc == V6C::LXI) {
      MCRegister PairReg = MI.getOperand(0).getReg();
      if (MI.getOperand(1).isImm()) {
        int64_t Imm16 = MI.getOperand(1).getImm() & 0xFFFF;
        int64_t Lo = Imm16 & 0xFF;
        int64_t Hi = (Imm16 >> 8) & 0xFF;
        if (PairReg == V6C::BC) {
          KnownVal[regIndex(V6C::B)] = Hi;
          KnownVal[regIndex(V6C::C)] = Lo;
        } else if (PairReg == V6C::DE) {
          KnownVal[regIndex(V6C::D)] = Hi;
          KnownVal[regIndex(V6C::E)] = Lo;
        } else if (PairReg == V6C::HL) {
          KnownVal[regIndex(V6C::H)] = Hi;
          KnownVal[regIndex(V6C::L)] = Lo;
        }
        // SP: not tracked.
      } else {
        // Non-immediate LXI (global address) — invalidate pair.
        invalidateWithSubSuper(PairReg);
      }
      continue;
    }

    // --- INR/DCR r: update tracked value if known ---
    if (Opc == V6C::INRr) {
      MCRegister Reg = MI.getOperand(0).getReg();
      int Idx = regIndex(Reg);
      if (Idx >= 0 && KnownVal[Idx])
        KnownVal[Idx] = ((*KnownVal[Idx]) + 1) & 0xFF;
      else if (Idx >= 0)
        KnownVal[Idx] = std::nullopt;
      continue;
    }
    if (Opc == V6C::DCRr) {
      MCRegister Reg = MI.getOperand(0).getReg();
      int Idx = regIndex(Reg);
      if (Idx >= 0 && KnownVal[Idx])
        KnownVal[Idx] = ((*KnownVal[Idx]) - 1) & 0xFF;
      else if (Idx >= 0)
        KnownVal[Idx] = std::nullopt;
      continue;
    }

    // --- ALU ops that write A: invalidate A ---
    switch (Opc) {
    case V6C::ADDr: case V6C::ADCr: case V6C::SUBr: case V6C::SBBr:
    case V6C::ANAr: case V6C::XRAr: case V6C::ORAr:
    case V6C::ADDM: case V6C::ADCM: case V6C::SUBM: case V6C::SBBM:
    case V6C::ANAM: case V6C::XRAM: case V6C::ORAM:
    case V6C::ADI: case V6C::ACI: case V6C::SUI: case V6C::SBI:
    case V6C::ANI: case V6C::XRI: case V6C::ORI:
    case V6C::RLC: case V6C::RRC: case V6C::RAL: case V6C::RAR:
    case V6C::CMA: case V6C::DAA:
      invalidate(V6C::A);
      continue;
    default:
      break;
    }

    // --- LDA / LDAX: write A ---
    if (Opc == V6C::LDA || Opc == V6C::LDAX) {
      invalidate(V6C::A);
      continue;
    }

    // --- POP: invalidate the pair's sub-registers ---
    if (Opc == V6C::POP) {
      MCRegister Reg = MI.getOperand(0).getReg();
      invalidateWithSubSuper(Reg);
      // PSW writes A too.
      if (Reg == V6C::PSW)
        invalidate(V6C::A);
      continue;
    }

    // --- INX/DCX: invalidate pair sub-registers (no simple ±1 on halves) ---
    if (Opc == V6C::INX || Opc == V6C::DCX) {
      MCRegister Reg = MI.getOperand(0).getReg();
      invalidateWithSubSuper(Reg);
      continue;
    }

    // --- XCHG: swap DE and HL known values ---
    if (Opc == V6C::XCHG) {
      int DIdx = regIndex(V6C::D), EIdx = regIndex(V6C::E);
      int HIdx = regIndex(V6C::H), LIdx = regIndex(V6C::L);
      std::swap(KnownVal[DIdx], KnownVal[HIdx]);
      std::swap(KnownVal[EIdx], KnownVal[LIdx]);
      continue;
    }

    // --- CALL: invalidate all (callee may clobber everything) ---
    if (MI.isCall()) {
      invalidateAll();
      continue;
    }

    // --- Any other instruction that defines a tracked register ---
    for (const MachineOperand &MO : MI.operands()) {
      if (MO.isReg() && MO.isDef() && MO.getReg().isPhysical())
        invalidateWithSubSuper(MO.getReg());
    }
    // Implicit defs.
    if (const MCInstrDesc &Desc = MI.getDesc();
        Desc.hasImplicitDefOfPhysReg(V6C::A))
      invalidate(V6C::A);
  }

  return Changed;
}

bool V6CLoadImmCombine::runOnMachineFunction(MachineFunction &MF) {
  if (DisableLoadImmCombine)
    return false;

  bool Changed = false;
  for (MachineBasicBlock &MBB : MF)
    Changed |= processBlock(MBB);
  return Changed;
}

FunctionPass *llvm::createV6CLoadImmCombinePass() {
  return new V6CLoadImmCombine();
}
