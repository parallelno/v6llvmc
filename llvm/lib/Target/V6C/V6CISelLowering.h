//===-- V6CISelLowering.h - V6C DAG Lowering Interface ----------*- C++ -*-===//
//
// Part of the V6C backend for LLVM.
//
// M4: i8 Operations & Basic Lowering.
//
//===----------------------------------------------------------------------===//

#ifndef LLVM_LIB_TARGET_V6C_V6CISELLOWERING_H
#define LLVM_LIB_TARGET_V6C_V6CISELLOWERING_H

#include "llvm/CodeGen/SelectionDAG.h"
#include "llvm/CodeGen/TargetLowering.h"

namespace llvm {

namespace V6CISD {
enum NodeType : unsigned {
  FIRST_NUMBER = ISD::BUILTIN_OP_END,
  RET,        // Return from function (with optional glue).
  CALL,       // Function call.
  CMP,        // Compare two values, produces glue (FLAGS).
  BRCOND,     // Conditional branch on FLAGS.
  SELECT_CC,  // Conditional select on FLAGS.
  Wrapper,    // GlobalAddress / ExternalSymbol wrapper.
  BR_CC16,    // Fused 16-bit compare + conditional branch.
  SEXT,       // Sign-extend i8 to i16 (pseudo, expands to RLC+SBB).
  SRL16,      // Logical right shift i16 by constant amount.
  SRA16,      // Arithmetic right shift i16 by constant amount.
};
} // namespace V6CISD

// V6C condition codes matching 8080 Jcc/Ccc/Rcc 3-bit encoding.
namespace V6CCC {
enum CondCode : unsigned {
  COND_NZ = 0, // Not zero
  COND_Z  = 1, // Zero
  COND_NC = 2, // No carry
  COND_C  = 3, // Carry
  COND_PO = 4, // Parity odd
  COND_PE = 5, // Parity even
  COND_P  = 6, // Plus (positive)
  COND_M  = 7, // Minus (negative)
};
} // namespace V6CCC

class V6CSubtarget;
class V6CTargetMachine;

class V6CTargetLowering : public TargetLowering {
public:
  explicit V6CTargetLowering(const V6CTargetMachine &TM,
                              const V6CSubtarget &STI);

  const char *getTargetNodeName(unsigned Opcode) const override;

  SDValue LowerOperation(SDValue Op, SelectionDAG &DAG) const override;

  MachineBasicBlock *
  EmitInstrWithCustomInserter(MachineInstr &MI,
                              MachineBasicBlock *BB) const override;

private:
  SDValue LowerFormalArguments(SDValue Chain, CallingConv::ID CallConv,
                               bool isVarArg,
                               const SmallVectorImpl<ISD::InputArg> &Ins,
                               const SDLoc &DL, SelectionDAG &DAG,
                               SmallVectorImpl<SDValue> &InVals) const override;

  SDValue LowerReturn(SDValue Chain, CallingConv::ID CallConv, bool isVarArg,
                      const SmallVectorImpl<ISD::OutputArg> &Outs,
                      const SmallVectorImpl<SDValue> &OutVals, const SDLoc &DL,
                      SelectionDAG &DAG) const override;

  SDValue LowerCall(TargetLowering::CallLoweringInfo &CLI,
                    SmallVectorImpl<SDValue> &InVals) const override;

  SDValue LowerGlobalAddress(SDValue Op, SelectionDAG &DAG) const;
  SDValue LowerExternalSymbol(SDValue Op, SelectionDAG &DAG) const;
  SDValue LowerBR_CC(SDValue Op, SelectionDAG &DAG) const;
  SDValue LowerSELECT_CC(SDValue Op, SelectionDAG &DAG) const;
  SDValue LowerSHL(SDValue Op, SelectionDAG &DAG) const;
  SDValue LowerSRL(SDValue Op, SelectionDAG &DAG) const;
  SDValue LowerSRA(SDValue Op, SelectionDAG &DAG) const;
  SDValue LowerSHL_i16(SDValue Op, SelectionDAG &DAG) const;
  SDValue LowerSRL_i16(SDValue Op, SelectionDAG &DAG) const;
  SDValue LowerSRA_i16(SDValue Op, SelectionDAG &DAG) const;
  SDValue LowerZERO_EXTEND(SDValue Op, SelectionDAG &DAG) const;
  SDValue LowerSIGN_EXTEND(SDValue Op, SelectionDAG &DAG) const;
  SDValue LowerANY_EXTEND(SDValue Op, SelectionDAG &DAG) const;

  // Inline assembly support.
  ConstraintType getConstraintType(StringRef Constraint) const override;
  std::pair<unsigned, const TargetRegisterClass *>
  getRegForInlineAsmConstraint(const TargetRegisterInfo *TRI,
                               StringRef Constraint, MVT VT) const override;
};

} // namespace llvm

#endif // LLVM_LIB_TARGET_V6C_V6CISELLOWERING_H
