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
    // No register output — only the chain.
    SDValue Chain = N->getOperand(0);
    SDValue LHS   = N->getOperand(1);
    SDValue RHS   = N->getOperand(2);
    SDValue CC    = N->getOperand(3);
    SDValue Dest  = N->getOperand(4);

    SmallVector<SDValue, 5> Ops;
    Ops.push_back(LHS);
    Ops.push_back(RHS);
    Ops.push_back(CC);
    Ops.push_back(Dest);
    Ops.push_back(Chain);

    SDVTList VTs = CurDAG->getVTList(MVT::Other);
    SDNode *BrCC = CurDAG->getMachineNode(V6C::V6C_BR_CC16, DL,
                                           VTs, Ops);
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
