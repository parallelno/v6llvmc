//===-- V6CISelDAGToDAG.cpp - V6C DAG->DAG instruction selection -----------===//
//
// Part of the V6C backend for LLVM.
//
// M5: Frame Lowering & Calling Convention.
//
//===----------------------------------------------------------------------===//

#include "V6C.h"
#include "V6CISelLowering.h"
#include "V6CSubtarget.h"
#include "V6CTargetMachine.h"
#include "MCTargetDesc/V6CMCTargetDesc.h"
#include "llvm/CodeGen/SelectionDAGISel.h"
#include "llvm/Support/CommandLine.h"

using namespace llvm;

#define DEBUG_TYPE "v6c-isel"

namespace {

class V6CDAGToDAGISel : public SelectionDAGISel {
  static char ID;

public:
  V6CDAGToDAGISel(V6CTargetMachine &TM, CodeGenOptLevel OptLevel)
      : SelectionDAGISel(ID, TM, OptLevel) {}

  StringRef getPassName() const override {
    return "V6C DAG->DAG Instruction Selection";
  }

  void Select(SDNode *N) override;

  // TableGen-generated code.
  #include "V6CGenDAGISel.inc"
};

char V6CDAGToDAGISel::ID = 0;

void V6CDAGToDAGISel::Select(SDNode *N) {
  // If already selected, do nothing.
  if (N->isMachineOpcode()) {
    N->setNodeId(-1);
    return;
  }

  SDLoc DL(N);
  unsigned Opc = N->getOpcode();

  switch (Opc) {
  default:
    break;

  case ISD::FrameIndex: {
    int FI = cast<FrameIndexSDNode>(N)->getIndex();
    SDValue TFI = CurDAG->getTargetFrameIndex(FI, MVT::i16);
    ReplaceNode(N, CurDAG->getMachineNode(V6C::V6C_LEA_FI, DL,
                                           MVT::i16, TFI));
    return;
  }

  case ISD::CALLSEQ_START: {
    SDValue Amt  = N->getOperand(1);
    SDValue Amt2 = N->getOperand(2);
    SDValue Chain = N->getOperand(0);
    SmallVector<SDValue, 4> Ops = {Amt, Amt2, Chain};
    ReplaceNode(N, CurDAG->getMachineNode(V6C::ADJCALLSTACKDOWN, DL,
                                           MVT::Other, MVT::Glue, Ops));
    return;
  }

  case ISD::CALLSEQ_END: {
    SmallVector<SDValue, 4> Ops;
    Ops.push_back(N->getOperand(1)); // Amt
    Ops.push_back(N->getOperand(2)); // Amt2
    Ops.push_back(N->getOperand(0)); // Chain
    // Optional incoming glue.
    if (N->getNumOperands() > 3 &&
        N->getOperand(N->getNumOperands() - 1).getValueType() == MVT::Glue)
      Ops.push_back(N->getOperand(N->getNumOperands() - 1));
    ReplaceNode(N, CurDAG->getMachineNode(V6C::ADJCALLSTACKUP, DL,
                                           MVT::Other, MVT::Glue, Ops));
    return;
  }

  case V6CISD::CALL: {
    // CALL node operands: chain, callee, [implicit reg uses...], RegisterMask, [glue]
    SDValue Chain  = N->getOperand(0);
    SDValue Callee = N->getOperand(1);

    SmallVector<SDValue, 8> Ops;
    Ops.push_back(Callee);

    // Copy implicit register uses and RegisterMask (skip chain and callee,
    // and skip trailing glue if present).
    unsigned NumOps = N->getNumOperands();
    bool HasGlue = N->getOperand(NumOps - 1).getValueType() == MVT::Glue;
    unsigned End = HasGlue ? NumOps - 1 : NumOps;
    for (unsigned i = 2; i < End; ++i)
      Ops.push_back(N->getOperand(i));

    // Chain, then optional glue.
    Ops.push_back(Chain);
    if (HasGlue)
      Ops.push_back(N->getOperand(NumOps - 1));

    SDNode *Call = CurDAG->getMachineNode(
        V6C::CALL, DL, MVT::Other, MVT::Glue, Ops);
    ReplaceNode(N, Call);
    return;
  }

  case V6CISD::BR_CC16: {
    // Fused 16-bit compare + branch.
    // Operands: chain, lhs(i16), rhs(i16), cc(i8), dest(bb)
    SDValue Chain = N->getOperand(0);
    SDValue LHS   = N->getOperand(1);
    SDValue RHS   = N->getOperand(2);
    SDValue CC    = N->getOperand(3);
    SDValue Dest  = N->getOperand(4);

    // Check if RHS (or LHS) is a constant or wrapped global address.
    // If so, use V6C_BR_CC16_IMM to avoid allocating a register pair.
    unsigned Opc = V6C::V6C_BR_CC16;
    SDValue RhsOp = RHS;

    auto CCVal = cast<ConstantSDNode>(CC)->getZExtValue();

    // EQ/NE: constant on RHS → use IMM variant directly.
    if (CCVal == V6CCC::COND_Z || CCVal == V6CCC::COND_NZ) {
      if (RHS.getOpcode() == V6CISD::Wrapper &&
          (isa<GlobalAddressSDNode>(RHS.getOperand(0)) ||
           isa<ExternalSymbolSDNode>(RHS.getOperand(0)))) {
        Opc = V6C::V6C_BR_CC16_IMM;
        RhsOp = RHS.getOperand(0);
      } else if (auto *C = dyn_cast<ConstantSDNode>(RHS)) {
        Opc = V6C::V6C_BR_CC16_IMM;
        RhsOp = CurDAG->getTargetConstant(C->getSExtValue(), DL, MVT::i16);
      }
    }

    // O24: Ordering conditions (C/NC/M/P) with immediate operand.
    // MVI+SUB/SBB doesn't need a register pair for the constant.
    if (CCVal == V6CCC::COND_C || CCVal == V6CCC::COND_NC ||
        CCVal == V6CCC::COND_M || CCVal == V6CCC::COND_P) {
      // Case A: Constant on LHS (from GT/LE swap in LowerBR_CC).
      // MVI+SUB computes const-reg, which matches the register path's
      // direction after the swap. Keep CC unchanged.
      if (auto *CL = dyn_cast<ConstantSDNode>(LHS)) {
        Opc = V6C::V6C_BR_CC16_IMM;
        RhsOp = CurDAG->getTargetConstant(CL->getSExtValue(), DL, MVT::i16);
        LHS = RHS; // register becomes $lhs
      } else if (LHS.getOpcode() == V6CISD::Wrapper &&
                 (isa<GlobalAddressSDNode>(LHS.getOperand(0)) ||
                  isa<ExternalSymbolSDNode>(LHS.getOperand(0)))) {
        Opc = V6C::V6C_BR_CC16_IMM;
        RhsOp = LHS.getOperand(0);
        LHS = RHS;
      }
      // Case B: Constant on RHS (natural ULT/UGE/SLT/SGE).
      // MVI+SUB computes const-reg but register path computes reg-const.
      // Adjust: K → K-1, invert CC (C↔NC, M↔P).
      else if (auto *CR = dyn_cast<ConstantSDNode>(RHS)) {
        int64_t K = CR->getSExtValue();
        bool IsUnsigned = (CCVal == V6CCC::COND_C || CCVal == V6CCC::COND_NC);
        // Guard: K=0 (unsigned) or K=0x8000 (signed) would underflow.
        bool CanAdjust = IsUnsigned ? ((K & 0xFFFF) != 0)
                                    : ((K & 0xFFFF) != 0x8000);
        if (CanAdjust) {
          Opc = V6C::V6C_BR_CC16_IMM;
          int64_t Km1 = (K - 1) & 0xFFFF;
          RhsOp = CurDAG->getTargetConstant(Km1, DL, MVT::i16);
          // Invert CC: C↔NC, M↔P
          unsigned NewCC;
          switch (CCVal) {
          case V6CCC::COND_C:  NewCC = V6CCC::COND_NC; break;
          case V6CCC::COND_NC: NewCC = V6CCC::COND_C;  break;
          case V6CCC::COND_M:  NewCC = V6CCC::COND_P;  break;
          case V6CCC::COND_P:  NewCC = V6CCC::COND_M;  break;
          default: llvm_unreachable("unexpected CC");
          }
          CC = CurDAG->getTargetConstant(NewCC, DL, MVT::i8);
        }
      } else if (RHS.getOpcode() == V6CISD::Wrapper &&
                 isa<GlobalAddressSDNode>(RHS.getOperand(0))) {
        // Global address on RHS: adjust offset by -1.
        auto *GA = cast<GlobalAddressSDNode>(RHS.getOperand(0));
        int64_t Offset = GA->getOffset();
        if (Offset != 0 || true) { // Always valid for globals (address > 0)
          Opc = V6C::V6C_BR_CC16_IMM;
          RhsOp = CurDAG->getTargetGlobalAddress(
              GA->getGlobal(), DL, MVT::i16, Offset - 1);
          unsigned NewCC;
          switch (CCVal) {
          case V6CCC::COND_C:  NewCC = V6CCC::COND_NC; break;
          case V6CCC::COND_NC: NewCC = V6CCC::COND_C;  break;
          case V6CCC::COND_M:  NewCC = V6CCC::COND_P;  break;
          case V6CCC::COND_P:  NewCC = V6CCC::COND_M;  break;
          default: llvm_unreachable("unexpected CC");
          }
          CC = CurDAG->getTargetConstant(NewCC, DL, MVT::i8);
        }
      }
    }

    SmallVector<SDValue, 5> Ops;
    Ops.push_back(LHS);
    Ops.push_back(RhsOp);
    Ops.push_back(CC);
    Ops.push_back(Dest);
    Ops.push_back(Chain);

    SDVTList VTs = CurDAG->getVTList(MVT::Other);
    SDNode *BrCC = CurDAG->getMachineNode(Opc, DL, VTs, Ops);
    ReplaceNode(N, BrCC);
    return;
  }

  case ISD::BUILD_PAIR: {
    // Combine two i8 values into an i16 register pair.
    SDValue Lo = N->getOperand(0);
    SDValue Hi = N->getOperand(1);
    SDNode *Pair = CurDAG->getMachineNode(V6C::V6C_BUILD_PAIR, DL,
                                           MVT::i16, Lo, Hi);
    ReplaceNode(N, Pair);
    return;
  }

  case V6CISD::CMP: {
    // O24: For i16 comparisons with constant/global RHS, use V6C_CMP16_IMM
    // to avoid allocating a register pair. The K→K-1 + CC inversion was
    // already done in LowerSELECT_CC.
    SDValue LHS = N->getOperand(0);
    SDValue RHS = N->getOperand(1);

    if (LHS.getValueType() == MVT::i16) {
      if (auto *C = dyn_cast<ConstantSDNode>(RHS)) {
        SDValue ImmOp = CurDAG->getTargetConstant(C->getSExtValue(), DL,
                                                    MVT::i16);
        SDNode *CmpImm = CurDAG->getMachineNode(V6C::V6C_CMP16_IMM, DL,
                                                  MVT::Glue, LHS, ImmOp);
        ReplaceNode(N, CmpImm);
        return;
      }
      if (RHS.getOpcode() == V6CISD::Wrapper &&
          (isa<GlobalAddressSDNode>(RHS.getOperand(0)) ||
           isa<ExternalSymbolSDNode>(RHS.getOperand(0)))) {
        SDValue Unwrapped = RHS.getOperand(0);
        SDNode *CmpImm = CurDAG->getMachineNode(V6C::V6C_CMP16_IMM, DL,
                                                  MVT::Glue, LHS, Unwrapped);
        ReplaceNode(N, CmpImm);
        return;
      }
    }
    break;
  }
  }

  // Try TableGen patterns.
  SelectCode(N);
}

} // namespace

namespace llvm {

FunctionPass *createV6CISelDag(V6CTargetMachine &TM,
                                CodeGenOptLevel OptLevel) {
  return new V6CDAGToDAGISel(TM, OptLevel);
}

} // namespace llvm
