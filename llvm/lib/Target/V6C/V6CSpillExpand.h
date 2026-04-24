//===-- V6CSpillExpand.h - Shared i8 spill/reload expander ----*- C++ -*-===//
//
// Part of the V6C backend for LLVM.
//
// Shared decision-ladder expander for V6C_SPILL8 / V6C_RELOAD8 when the
// slot address resolves to a static storage site (either a static-stack
// GlobalAddress from V6CStaticStackAlloc, or a patch-point MCSymbol from
// O61 / V6CSpillPatchedReload). Callers supply the final address operand
// via AppendAddrFn so the same ladder handles both address kinds.
//
// O64 (Liveness-Aware i8 Spill/Reload Lowering, Shapes B & C).
//
//===----------------------------------------------------------------------===//

#ifndef LLVM_LIB_TARGET_V6C_V6CSPILLEXPAND_H
#define LLVM_LIB_TARGET_V6C_V6CSPILLEXPAND_H

#include "llvm/ADT/STLFunctionalExtras.h"
#include "llvm/CodeGen/MachineBasicBlock.h"
#include "llvm/CodeGen/MachineInstrBuilder.h"
#include "llvm/CodeGen/Register.h"

namespace llvm {

class MachineInstr;
class TargetInstrInfo;
class TargetRegisterInfo;

/// Check if a physical register is dead after MI. Scans forward from
/// MI (exclusive) to end of MBB, then checks successor live-ins.
bool isRegDeadAfterMI(unsigned Reg, const MachineInstr &MI,
                      MachineBasicBlock &MBB,
                      const TargetRegisterInfo *TRI);

/// Return the first register in {B, C, D, E}, excluding any register
/// whose aliases overlap `Excluded`, that is dead after MI. Returns a
/// default-constructed Register() if none qualifies.
Register findDeadSpareGPR8(Register Excluded, const MachineInstr &MI,
                           MachineBasicBlock &MBB,
                           const TargetRegisterInfo *TRI);

/// Callback: append the final address operand to an LXI/STA/LDA builder.
/// The same ladder body is used for both static-stack (GlobalAddress +
/// offset) and O61 patch-point (MCSymbol + MO_PATCH_IMM) address kinds.
using AppendAddrFn = llvm::function_ref<void(MachineInstrBuilder &)>;

/// Emit the O64 decision ladder for a V6C_SPILL8 at `InsertBefore`.
///
/// The caller is expected to handle Shape A (SrcReg == A) inline with a
/// single STA. This helper covers Shape B (SrcReg in {B,C,D,E}) and
/// Shape C (SrcReg in {H, L}). Does NOT erase `MI` — caller owns it.
void expandSpill8Static(MachineInstr &MI,
                        MachineBasicBlock::iterator InsertBefore,
                        Register SrcReg, bool SrcIsKill,
                        const TargetInstrInfo &TII,
                        const TargetRegisterInfo *TRI,
                        AppendAddrFn AppendAddr);

/// Emit the O64 decision ladder for a V6C_RELOAD8 at `InsertBefore`.
///
/// The caller is expected to handle Shape A (DstReg == A) inline with a
/// single LDA. This helper covers Shape B (DstReg in {B,C,D,E}) and
/// Shape C (DstReg in {H, L}). Does NOT erase `MI` — caller owns it.
void expandReload8Static(MachineInstr &MI,
                         MachineBasicBlock::iterator InsertBefore,
                         Register DstReg,
                         const TargetInstrInfo &TII,
                         const TargetRegisterInfo *TRI,
                         AppendAddrFn AppendAddr);

} // end namespace llvm

#endif // LLVM_LIB_TARGET_V6C_V6CSPILLEXPAND_H
