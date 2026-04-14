//===-- V6CISelLowering.cpp - V6C DAG Lowering Implementation -------------===//
//
// Part of the V6C backend for LLVM.
//
// M5: Frame Lowering & Calling Convention.
//
//===----------------------------------------------------------------------===//

#include "V6CISelLowering.h"
#include "V6CSubtarget.h"
#include "V6CTargetMachine.h"
#include "MCTargetDesc/V6CMCTargetDesc.h"
#include "llvm/CodeGen/CallingConvLower.h"
#include "llvm/CodeGen/MachineFrameInfo.h"
#include "llvm/CodeGen/MachineFunction.h"
#include "llvm/CodeGen/MachineInstrBuilder.h"
#include "llvm/CodeGen/MachineRegisterInfo.h"
#include "llvm/CodeGen/SelectionDAG.h"
#include "llvm/CodeGen/TargetLoweringObjectFileImpl.h"
#include "llvm/IR/Function.h"

using namespace llvm;

#define DEBUG_TYPE "v6c-lower"

//===----------------------------------------------------------------------===//
// V6CTargetLowering constructor — type legalization, operation actions
//===----------------------------------------------------------------------===//

V6CTargetLowering::V6CTargetLowering(const V6CTargetMachine &TM,
                                       const V6CSubtarget &STI)
    : TargetLowering(TM) {
  // Register classes.
  addRegisterClass(MVT::i8, &V6C::GR8RegClass);
  addRegisterClass(MVT::i16, &V6C::GR16RegClass);

  computeRegisterProperties(STI.getRegisterInfo());

  setStackPointerRegisterToSaveRestore(V6C::SP);

  // --- Type legalization ---

  // i8: Legal via TableGen patterns.

  // i16: Legal for loads/stores/copies, Expand or Custom for arithmetic.
  // Full i16 ALU is deferred to M7. For M5 we need i16 for pointers and
  // calling convention (arguments, return values).

  // i32: Expand to pairs of i16.
  // i64: not supported at all.

  // --- Operation actions for i8 ---

  // Multiply, divide: no hardware support → Promote to i16 (which uses libcall).
  setOperationAction(ISD::MUL,   MVT::i8, Promote);
  setOperationAction(ISD::SDIV,  MVT::i8, Promote);
  setOperationAction(ISD::UDIV,  MVT::i8, Promote);
  setOperationAction(ISD::SREM,  MVT::i8, Promote);
  setOperationAction(ISD::UREM,  MVT::i8, Promote);
  setOperationAction(ISD::SDIVREM, MVT::i8, Expand);
  setOperationAction(ISD::UDIVREM, MVT::i8, Expand);
  setOperationAction(ISD::MULHS, MVT::i8, Expand);
  setOperationAction(ISD::MULHU, MVT::i8, Expand);
  setOperationAction(ISD::SMUL_LOHI, MVT::i8, Expand);
  setOperationAction(ISD::UMUL_LOHI, MVT::i8, Expand);

  // Shifts: Custom lowering (expand to rotates/loops).
  setOperationAction(ISD::SHL,  MVT::i8, Custom);
  setOperationAction(ISD::SRL,  MVT::i8, Custom);
  setOperationAction(ISD::SRA,  MVT::i8, Custom);

  // Rotates: not directly matchable by generic rotl/rotr.
  setOperationAction(ISD::ROTL, MVT::i8, Expand);
  setOperationAction(ISD::ROTR, MVT::i8, Expand);

  // No hardware support for byte swap, ctlz, cttz, ctpop.
  setOperationAction(ISD::BSWAP,    MVT::i8, Expand);
  setOperationAction(ISD::CTLZ,     MVT::i8, Expand);
  setOperationAction(ISD::CTTZ,     MVT::i8, Expand);
  setOperationAction(ISD::CTPOP,    MVT::i8, Expand);

  // Compare-and-branch: Custom (fuse icmp + br into CMP + Jcc).
  setOperationAction(ISD::BR_CC,     MVT::i8, Custom);
  setOperationAction(ISD::SELECT_CC, MVT::i8, Custom);

  // SELECT: expand to SELECT_CC.
  setOperationAction(ISD::SELECT, MVT::i8, Expand);

  // Extending loads / truncating stores.
  setOperationAction(ISD::SIGN_EXTEND_INREG, MVT::i1, Expand);

  // Extending loads: expand to load + extend (no native extending load).
  setLoadExtAction(ISD::SEXTLOAD, MVT::i16, MVT::i8, Expand);
  setLoadExtAction(ISD::ZEXTLOAD, MVT::i16, MVT::i8, Expand);
  setLoadExtAction(ISD::EXTLOAD,  MVT::i16, MVT::i8, Expand);

  // GlobalAddress, ExternalSymbol: Custom (wrap for LXI).
  setOperationAction(ISD::GlobalAddress,  MVT::i16, Custom);
  setOperationAction(ISD::ExternalSymbol, MVT::i16, Custom);

  // Varargs: not supported.
  setOperationAction(ISD::VASTART, MVT::Other, Expand);
  setOperationAction(ISD::VAARG,   MVT::Other, Expand);
  setOperationAction(ISD::VACOPY,  MVT::Other, Expand);
  setOperationAction(ISD::VAEND,   MVT::Other, Expand);

  // Dynamic stack allocation: not yet supported.
  setOperationAction(ISD::DYNAMIC_STACKALLOC, MVT::i16, Expand);

  // Setcc: expand to select_cc-based sequences.
  setOperationAction(ISD::SETCC, MVT::i8, Expand);

  // Zero/sign/any extend i8→i16: Custom lowering to BUILD_PAIR.
  setOperationAction(ISD::SIGN_EXTEND, MVT::i16, Custom);
  setOperationAction(ISD::ZERO_EXTEND, MVT::i16, Custom);
  setOperationAction(ISD::ANY_EXTEND,  MVT::i16, Custom);
  setOperationAction(ISD::TRUNCATE,    MVT::i8,  Legal);

  // --- Operation actions for i16 ---
  // M7: i16 ALU ops matched to pseudo-instructions via TableGen patterns.

  // ADD, SUB, AND, OR, XOR: Legal — matched by V6C_ADD16, etc. pseudos.
  setOperationAction(ISD::ADD,   MVT::i16, Legal);
  setOperationAction(ISD::SUB,   MVT::i16, Legal);
  setOperationAction(ISD::AND,   MVT::i16, Legal);
  setOperationAction(ISD::OR,    MVT::i16, Legal);
  setOperationAction(ISD::XOR,   MVT::i16, Legal);

  // Multiply, divide: no hardware support → Expand (LibCall).
  setOperationAction(ISD::MUL,   MVT::i16, Expand);
  setOperationAction(ISD::SDIV,  MVT::i16, Expand);
  setOperationAction(ISD::UDIV,  MVT::i16, Expand);
  setOperationAction(ISD::SREM,  MVT::i16, Expand);
  setOperationAction(ISD::UREM,  MVT::i16, Expand);
  setOperationAction(ISD::SDIVREM, MVT::i16, Expand);
  setOperationAction(ISD::UDIVREM, MVT::i16, Expand);

  // Shifts: Custom (unrolled for constant, libcall for variable).
  setOperationAction(ISD::SHL,   MVT::i16, Custom);
  setOperationAction(ISD::SRL,   MVT::i16, Custom);
  setOperationAction(ISD::SRA,   MVT::i16, Custom);
  setOperationAction(ISD::ROTL,  MVT::i16, Expand);
  setOperationAction(ISD::ROTR,  MVT::i16, Expand);

  // Compare-and-branch, select: Custom (fuse into 8-bit compare sequences).
  setOperationAction(ISD::BR_CC,     MVT::i16, Custom);
  setOperationAction(ISD::SELECT_CC, MVT::i16, Custom);
  setOperationAction(ISD::SELECT,    MVT::i16, Expand);
  setOperationAction(ISD::SETCC,     MVT::i16, Expand);

  setOperationAction(ISD::CTLZ,  MVT::i16, Expand);
  setOperationAction(ISD::CTTZ,  MVT::i16, Expand);
  setOperationAction(ISD::CTPOP, MVT::i16, Expand);
  setOperationAction(ISD::BSWAP, MVT::i16, Expand);

  setOperationAction(ISD::MULHS,     MVT::i16, Expand);
  setOperationAction(ISD::MULHU,     MVT::i16, Expand);
  setOperationAction(ISD::SMUL_LOHI, MVT::i16, Expand);
  setOperationAction(ISD::UMUL_LOHI, MVT::i16, Expand);

  // --- Runtime library call names ---
  // LLVM defaults match GCC convention (__mulhi3, __divhi3, etc.) but set
  // explicitly for clarity.  These are implemented in compiler-rt/lib/builtins/v6c/.
  setLibcallName(RTLIB::MUL_I16,  "__mulhi3");
  setLibcallName(RTLIB::SDIV_I16, "__divhi3");
  setLibcallName(RTLIB::UDIV_I16, "__udivhi3");
  setLibcallName(RTLIB::SREM_I16, "__modhi3");
  setLibcallName(RTLIB::UREM_I16, "__umodhi3");
  setLibcallName(RTLIB::SHL_I16,  "__ashlhi3");
  setLibcallName(RTLIB::SRL_I16,  "__lshrhi3");
  setLibcallName(RTLIB::SRA_I16,  "__ashrhi3");

  // Minimum function alignment (8080 has no alignment requirements).
  setMinFunctionAlignment(Align(1));

  // Enable DAG combine for i16 ADD → DAD optimization.
  setTargetDAGCombine(ISD::ADD);
}

//===----------------------------------------------------------------------===//
// getTargetNodeName
//===----------------------------------------------------------------------===//

const char *V6CTargetLowering::getTargetNodeName(unsigned Opcode) const {
  switch (static_cast<V6CISD::NodeType>(Opcode)) {
  case V6CISD::FIRST_NUMBER: break;
  case V6CISD::RET:       return "V6CISD::RET";
  case V6CISD::CALL:      return "V6CISD::CALL";
  case V6CISD::CMP:       return "V6CISD::CMP";
  case V6CISD::CMP_ZERO:  return "V6CISD::CMP_ZERO";
  case V6CISD::BRCOND:    return "V6CISD::BRCOND";
  case V6CISD::SELECT_CC: return "V6CISD::SELECT_CC";
  case V6CISD::Wrapper:   return "V6CISD::Wrapper";
  case V6CISD::BR_CC16:   return "V6CISD::BR_CC16";
  case V6CISD::SEXT:      return "V6CISD::SEXT";
  case V6CISD::SRL16:     return "V6CISD::SRL16";
  case V6CISD::SRA16:     return "V6CISD::SRA16";
  case V6CISD::DAD:       return "V6CISD::DAD";
  }
  return nullptr;
}

//===----------------------------------------------------------------------===//
// PerformDAGCombine — target-specific DAG optimizations
//===----------------------------------------------------------------------===//

SDValue V6CTargetLowering::PerformDAGCombine(SDNode *N,
                                              DAGCombinerInfo &DCI) const {
  SelectionDAG &DAG = DCI.DAG;

  switch (N->getOpcode()) {
  default:
    break;

  case ISD::ADD:
    // Convert i16 add to V6CISD::DAD when the result is used as a pointer
    // for a memory operation. DAD uses the HL register pair (12cc, does not
    // clobber A), which is exactly what loads/stores need for addressing.
    if (N->getValueType(0) == MVT::i16) {
      bool UsedAsPointer = false;
      for (SDNode::use_iterator UI = N->use_begin(), UE = N->use_end();
           UI != UE; ++UI) {
        unsigned UseOpc = UI->getOpcode();
        // Load: operands are (chain, ptr). We're the pointer if operand 1.
        if (UseOpc == ISD::LOAD && UI.getOperandNo() == 1)
          UsedAsPointer = true;
        // Store: operands are (chain, val, ptr). We're the pointer if operand 2.
        if (UseOpc == ISD::STORE && UI.getOperandNo() == 2)
          UsedAsPointer = true;
      }
      if (UsedAsPointer) {
        SDLoc DL(N);
        return DAG.getNode(V6CISD::DAD, DL, MVT::i16, N->getOperand(0),
                           N->getOperand(1));
      }
    }
    break;
  }

  return SDValue();
}

//===----------------------------------------------------------------------===//
// LowerOperation — dispatch custom-lowered operations
//===----------------------------------------------------------------------===//

SDValue V6CTargetLowering::LowerOperation(SDValue Op,
                                            SelectionDAG &DAG) const {
  switch (Op.getOpcode()) {
  default:
    report_fatal_error("V6C: unimplemented operation: " +
                       Twine(Op.getOpcode()));
  case ISD::GlobalAddress:  return LowerGlobalAddress(Op, DAG);
  case ISD::ExternalSymbol: return LowerExternalSymbol(Op, DAG);
  case ISD::BR_CC:          return LowerBR_CC(Op, DAG);
  case ISD::SELECT_CC:      return LowerSELECT_CC(Op, DAG);
  case ISD::SHL:            return LowerSHL(Op, DAG);
  case ISD::SRL:            return LowerSRL(Op, DAG);
  case ISD::SRA:            return LowerSRA(Op, DAG);
  case ISD::ZERO_EXTEND:    return LowerZERO_EXTEND(Op, DAG);
  case ISD::SIGN_EXTEND:    return LowerSIGN_EXTEND(Op, DAG);
  case ISD::ANY_EXTEND:     return LowerANY_EXTEND(Op, DAG);
  }
}

//===----------------------------------------------------------------------===//
// GlobalAddress / ExternalSymbol lowering → V6CISD::Wrapper
//===----------------------------------------------------------------------===//

SDValue V6CTargetLowering::LowerGlobalAddress(SDValue Op,
                                                SelectionDAG &DAG) const {
  SDLoc DL(Op);
  const GlobalAddressSDNode *GA = cast<GlobalAddressSDNode>(Op);
  SDValue Addr = DAG.getTargetGlobalAddress(GA->getGlobal(), DL, MVT::i16,
                                            GA->getOffset());
  return DAG.getNode(V6CISD::Wrapper, DL, MVT::i16, Addr);
}

SDValue V6CTargetLowering::LowerExternalSymbol(SDValue Op,
                                                 SelectionDAG &DAG) const {
  SDLoc DL(Op);
  const ExternalSymbolSDNode *ES = cast<ExternalSymbolSDNode>(Op);
  SDValue Addr = DAG.getTargetExternalSymbol(ES->getSymbol(), MVT::i16);
  return DAG.getNode(V6CISD::Wrapper, DL, MVT::i16, Addr);
}

//===----------------------------------------------------------------------===//
// BR_CC lowering → V6CISD::CMP + V6CISD::BRCOND
//===----------------------------------------------------------------------===//

// Convert LLVM ISD condition code to V6C condition code.
static V6CCC::CondCode getV6CCC(ISD::CondCode CC) {
  switch (CC) {
  default: llvm_unreachable("unsupported condition code");
  case ISD::SETEQ:  return V6CCC::COND_Z;
  case ISD::SETNE:  return V6CCC::COND_NZ;
  case ISD::SETLT:  return V6CCC::COND_M;   // Signed: negative flag
  case ISD::SETGE:  return V6CCC::COND_P;   // Signed: positive flag
  case ISD::SETULT: return V6CCC::COND_C;   // Unsigned: carry
  case ISD::SETUGE: return V6CCC::COND_NC;  // Unsigned: no carry
  // For GT/LE, the caller must swap operands or use two conditions.
  // Expand handles that for us via BR_CC custom lowering.
  }
}

SDValue V6CTargetLowering::LowerBR_CC(SDValue Op, SelectionDAG &DAG) const {
  SDLoc DL(Op);
  SDValue Chain  = Op.getOperand(0);
  ISD::CondCode CC = cast<CondCodeSDNode>(Op.getOperand(1))->get();
  SDValue LHS    = Op.getOperand(2);
  SDValue RHS    = Op.getOperand(3);
  SDValue Dest   = Op.getOperand(4);

  // Handle GT/LE by swapping operands.
  switch (CC) {
  case ISD::SETGT:
    std::swap(LHS, RHS);
    CC = ISD::SETLT;
    break;
  case ISD::SETLE:
    std::swap(LHS, RHS);
    CC = ISD::SETGE;
    break;
  case ISD::SETUGT:
    std::swap(LHS, RHS);
    CC = ISD::SETULT;
    break;
  case ISD::SETULE:
    std::swap(LHS, RHS);
    CC = ISD::SETUGE;
    break;
  default:
    break;
  }

  V6CCC::CondCode V6CC = getV6CCC(CC);

  // For i16: use fused compare+branch pseudo (V6C_BR_CC16) because
  // 16-bit comparisons require different flag sequences for EQ/NE vs LT/GE.
  if (LHS.getValueType() == MVT::i16) {
    SDValue CCVal = DAG.getTargetConstant(V6CC, DL, MVT::i8);
    SDValue Ops[] = {Chain, LHS, RHS, CCVal, Dest};
    return DAG.getNode(V6CISD::BR_CC16, DL, MVT::Other, Ops);
  }

  // For i8: emit CMP (produces glue with FLAGS) then BRCOND.
  SDValue Glue = DAG.getNode(V6CISD::CMP, DL, MVT::Glue, LHS, RHS);
  SDValue CCVal = DAG.getConstant(V6CC, DL, MVT::i8);
  return DAG.getNode(V6CISD::BRCOND, DL, MVT::Other, Chain, Dest, CCVal,
                     Glue);
}

//===----------------------------------------------------------------------===//
// SELECT_CC lowering → V6CISD::CMP + V6CISD::SELECT_CC
//===----------------------------------------------------------------------===//

SDValue V6CTargetLowering::LowerSELECT_CC(SDValue Op,
                                            SelectionDAG &DAG) const {
  SDLoc DL(Op);
  SDValue LHS      = Op.getOperand(0);
  SDValue RHS      = Op.getOperand(1);
  SDValue TrueVal  = Op.getOperand(2);
  SDValue FalseVal = Op.getOperand(3);
  ISD::CondCode CC = cast<CondCodeSDNode>(Op.getOperand(4))->get();

  // Handle GT/LE by swapping.
  switch (CC) {
  case ISD::SETGT:
    std::swap(LHS, RHS);
    CC = ISD::SETLT;
    break;
  case ISD::SETLE:
    std::swap(LHS, RHS);
    CC = ISD::SETGE;
    break;
  case ISD::SETUGT:
    std::swap(LHS, RHS);
    CC = ISD::SETULT;
    break;
  case ISD::SETULE:
    std::swap(LHS, RHS);
    CC = ISD::SETUGE;
    break;
  default:
    break;
  }

  V6CCC::CondCode V6CC = getV6CCC(CC);
  SDValue CCVal = DAG.getConstant(V6CC, DL, MVT::i8);

  // O34: For i16 EQ/NE against zero, use zero-test (MOV A, Hi; ORA Lo)
  // instead of materializing 0 into a register pair for SUB/SBB.
  if (LHS.getValueType() == MVT::i16 && isNullConstant(RHS) &&
      (CC == ISD::SETEQ || CC == ISD::SETNE)) {
    SDValue Glue = DAG.getNode(V6CISD::CMP_ZERO, DL, MVT::Glue, LHS);
    SDVTList VTs = DAG.getVTList(Op.getValueType());
    return DAG.getNode(V6CISD::SELECT_CC, DL, VTs,
                       TrueVal, FalseVal, CCVal, Glue);
  }

  // For i16 comparison operands, emit CMP16 then SELECT_CC (uses FLAGS).
  // For i8, emit CMP then SELECT_CC.
  SDValue Glue = DAG.getNode(V6CISD::CMP, DL, MVT::Glue, LHS, RHS);
  SDVTList VTs = DAG.getVTList(Op.getValueType());
  return DAG.getNode(V6CISD::SELECT_CC, DL, VTs,
                     TrueVal, FalseVal, CCVal, Glue);
}

//===----------------------------------------------------------------------===//
// Shift lowering — expand to rotates for shift-by-1, library call otherwise
//===----------------------------------------------------------------------===//

// For M4 we support shift-by-constant only.  For shift-by-1, emit the
// appropriate rotate instruction.  For larger constants, emit a sequence.
// Variable shifts are expanded to a loop (deferred to M7/M11 library call).

static SDValue expandShiftByOne(unsigned Opc, SDValue Op, SelectionDAG &DAG) {
  // This will be matched by the RLC/RAL/RRC/RAR TableGen patterns
  // in a later milestone.  For M4, return SDValue() and let the
  // expander handle it via repeated shift-by-1.
  return SDValue();
}

SDValue V6CTargetLowering::LowerSHL(SDValue Op, SelectionDAG &DAG) const {
  if (Op.getValueType() == MVT::i16)
    return LowerSHL_i16(Op, DAG);

  SDLoc DL(Op);
  SDValue Val = Op.getOperand(0);
  SDValue Amt = Op.getOperand(1);

  // Only i8 supported here.
  if (Op.getValueType() != MVT::i8)
    return SDValue();

  // Constant shift amounts: unroll to add-to-self (shl 1 = ADD A,A).
  if (auto *CA = dyn_cast<ConstantSDNode>(Amt)) {
    unsigned ShAmt = CA->getZExtValue() & 7;
    if (ShAmt == 0)
      return Val;
    SDValue Result = Val;
    for (unsigned i = 0; i < ShAmt; ++i)
      Result = DAG.getNode(ISD::ADD, DL, MVT::i8, Result, Result);
    return Result;
  }

  // Variable i8 shift: promote to i16 (which uses libcall for variable amount).
  SDValue ExtVal = DAG.getNode(ISD::ZERO_EXTEND, DL, MVT::i16, Val);
  SDValue ExtAmt = DAG.getNode(ISD::ZERO_EXTEND, DL, MVT::i16, Amt);
  SDValue Shifted = DAG.getNode(ISD::SHL, DL, MVT::i16, ExtVal, ExtAmt);
  return DAG.getNode(ISD::TRUNCATE, DL, MVT::i8, Shifted);
}

SDValue V6CTargetLowering::LowerSRL(SDValue Op, SelectionDAG &DAG) const {
  if (Op.getValueType() == MVT::i16)
    return LowerSRL_i16(Op, DAG);

  SDLoc DL(Op);
  SDValue Val = Op.getOperand(0);
  SDValue Amt = Op.getOperand(1);

  if (Op.getValueType() != MVT::i8)
    return SDValue();

  // Constant shift: unroll.
  if (auto *CA = dyn_cast<ConstantSDNode>(Amt)) {
    unsigned ShAmt = CA->getZExtValue() & 7;
    if (ShAmt == 0)
      return Val;
    // For i8 logical right shift by constant, promote to i16 and shift.
    SDValue Ext = DAG.getNode(ISD::ZERO_EXTEND, DL, MVT::i16, Val);
    SDValue ShiftedWide = DAG.getNode(V6CISD::SRL16, DL, MVT::i16, Ext,
                                      DAG.getTargetConstant(ShAmt, DL, MVT::i8));
    return DAG.getNode(ISD::TRUNCATE, DL, MVT::i8, ShiftedWide);
  }

  // Variable i8 logical right shift: promote to i16.
  SDValue ExtVal = DAG.getNode(ISD::ZERO_EXTEND, DL, MVT::i16, Val);
  SDValue ExtAmt = DAG.getNode(ISD::ZERO_EXTEND, DL, MVT::i16, Amt);
  SDValue Shifted = DAG.getNode(ISD::SRL, DL, MVT::i16, ExtVal, ExtAmt);
  return DAG.getNode(ISD::TRUNCATE, DL, MVT::i8, Shifted);
}

SDValue V6CTargetLowering::LowerSRA(SDValue Op, SelectionDAG &DAG) const {
  if (Op.getValueType() == MVT::i16)
    return LowerSRA_i16(Op, DAG);

  SDLoc DL(Op);
  SDValue Val = Op.getOperand(0);
  SDValue Amt = Op.getOperand(1);

  if (Op.getValueType() != MVT::i8)
    return SDValue();

  // Constant shift: unroll.
  if (auto *CA = dyn_cast<ConstantSDNode>(Amt)) {
    unsigned ShAmt = CA->getZExtValue() & 7;
    if (ShAmt == 0)
      return Val;
    // For i8 arithmetic right shift by constant, promote to i16 and shift.
    SDValue Ext = DAG.getNode(ISD::SIGN_EXTEND, DL, MVT::i16, Val);
    SDValue ShiftedWide = DAG.getNode(V6CISD::SRA16, DL, MVT::i16, Ext,
                                      DAG.getTargetConstant(ShAmt, DL, MVT::i8));
    return DAG.getNode(ISD::TRUNCATE, DL, MVT::i8, ShiftedWide);
  }

  // Variable i8 arithmetic right shift: sign-extend to i16, shift.
  SDValue ExtVal = DAG.getNode(ISD::SIGN_EXTEND, DL, MVT::i16, Val);
  SDValue ExtAmt = DAG.getNode(ISD::ZERO_EXTEND, DL, MVT::i16, Amt);
  SDValue Shifted = DAG.getNode(ISD::SRA, DL, MVT::i16, ExtVal, ExtAmt);
  return DAG.getNode(ISD::TRUNCATE, DL, MVT::i8, Shifted);
}

//===----------------------------------------------------------------------===//
// i16 Shift lowering — emit V6C_SHL16/SRL16/SRA16 pseudos for constant amounts
//===----------------------------------------------------------------------===//

SDValue V6CTargetLowering::LowerSHL_i16(SDValue Op, SelectionDAG &DAG) const {
  SDLoc DL(Op);
  SDValue Val = Op.getOperand(0);
  SDValue Amt = Op.getOperand(1);

  if (auto *CA = dyn_cast<ConstantSDNode>(Amt)) {
    unsigned ShAmt = CA->getZExtValue() & 15;
    if (ShAmt == 0)
      return Val;
    // Shift by 8+: move lo byte to hi position, zero lo, shift remaining
    // in i8 domain. Uses BUILD_PAIR to construct the result directly.
    if (ShAmt >= 8) {
      // Extract lo byte via TRUNCATE (maps to EXTRACT_SUBREG sub_lo).
      SDValue Lo = DAG.getNode(ISD::TRUNCATE, DL, MVT::i8, Val);
      SDValue Zero = DAG.getConstant(0, DL, MVT::i8);
      // Shift the lo byte left by (ShAmt - 8) in i8 domain via ADD self.
      SDValue Hi = Lo;
      for (unsigned i = 0; i < ShAmt - 8; ++i)
        Hi = DAG.getNode(ISD::ADD, DL, MVT::i8, Hi, Hi);
      // Build i16: lo=0, hi=shifted_lo
      return DAG.getNode(ISD::BUILD_PAIR, DL, MVT::i16, Zero, Hi);
    }
    // For shift amounts 1-7: unroll as ADD self (shift left by 1) repeated.
    SDValue Result = Val;
    for (unsigned i = 0; i < ShAmt; ++i)
      Result = DAG.getNode(ISD::ADD, DL, MVT::i16, Result, Result);
    return Result;
  }

  // Variable i16 shift left: emit libcall.
  TargetLowering::MakeLibCallOptions CallOptions;
  return makeLibCall(DAG, RTLIB::SHL_I16, MVT::i16, {Val, Amt}, CallOptions, DL).first;
}

SDValue V6CTargetLowering::LowerSRL_i16(SDValue Op, SelectionDAG &DAG) const {
  SDLoc DL(Op);
  SDValue Val = Op.getOperand(0);
  SDValue Amt = Op.getOperand(1);

  if (auto *CA = dyn_cast<ConstantSDNode>(Amt)) {
    unsigned ShAmt = CA->getZExtValue() & 15;
    if (ShAmt == 0)
      return Val;
    // Emit V6CISD::SRL16 → V6C_SRL16 pseudo → expandPostRAPseudo.
    return DAG.getNode(V6CISD::SRL16, DL, MVT::i16, Val,
                       DAG.getTargetConstant(ShAmt, DL, MVT::i8));
  }

  // Variable i16 logical right shift: emit libcall.
  TargetLowering::MakeLibCallOptions CallOptions;
  return makeLibCall(DAG, RTLIB::SRL_I16, MVT::i16, {Val, Amt}, CallOptions, DL).first;
}

SDValue V6CTargetLowering::LowerSRA_i16(SDValue Op, SelectionDAG &DAG) const {
  SDLoc DL(Op);
  SDValue Val = Op.getOperand(0);
  SDValue Amt = Op.getOperand(1);

  if (auto *CA = dyn_cast<ConstantSDNode>(Amt)) {
    unsigned ShAmt = CA->getZExtValue() & 15;
    if (ShAmt == 0)
      return Val;
    // Emit V6CISD::SRA16 → V6C_SRA16 pseudo → expandPostRAPseudo.
    return DAG.getNode(V6CISD::SRA16, DL, MVT::i16, Val,
                       DAG.getTargetConstant(ShAmt, DL, MVT::i8));
  }

  // Variable i16 arithmetic right shift: emit libcall.
  TargetLowering::MakeLibCallOptions CallOptions;
  return makeLibCall(DAG, RTLIB::SRA_I16, MVT::i16, {Val, Amt}, CallOptions, DL).first;
}

//===----------------------------------------------------------------------===//
// Zero/Sign/Any extend i8 → i16
//===----------------------------------------------------------------------===//

SDValue V6CTargetLowering::LowerZERO_EXTEND(SDValue Op,
                                              SelectionDAG &DAG) const {
  SDLoc DL(Op);
  SDValue Val = Op.getOperand(0);
  assert(Val.getValueType() == MVT::i8 && Op.getValueType() == MVT::i16);

  SDValue Zero = DAG.getConstant(0, DL, MVT::i8);
  return DAG.getNode(ISD::BUILD_PAIR, DL, MVT::i16, Val, Zero);
}

SDValue V6CTargetLowering::LowerSIGN_EXTEND(SDValue Op,
                                              SelectionDAG &DAG) const {
  SDLoc DL(Op);
  SDValue Val = Op.getOperand(0);
  assert(Val.getValueType() == MVT::i8 && Op.getValueType() == MVT::i16);

  // Use V6CISD::SEXT node — expands post-RA to RLC+SBB sequence.
  return DAG.getNode(V6CISD::SEXT, DL, MVT::i16, Val);
}

SDValue V6CTargetLowering::LowerANY_EXTEND(SDValue Op,
                                             SelectionDAG &DAG) const {
  SDLoc DL(Op);
  SDValue Val = Op.getOperand(0);
  assert(Val.getValueType() == MVT::i8 && Op.getValueType() == MVT::i16);

  SDValue Hi = DAG.getUNDEF(MVT::i8);
  return DAG.getNode(ISD::BUILD_PAIR, DL, MVT::i16, Val, Hi);
}

//===----------------------------------------------------------------------===//
// LowerFormalArguments — copy arguments from physical regs to virtual regs
//
// V6C_CConv (design §6.1): position-based register assignment.
//   Arg 1: i8 → A,   i16 → HL
//   Arg 2: i8 → E,   i16 → DE
//   Arg 3: i8 → C,   i16 → BC
//   Arg 4+: stack (right-to-left push, left-to-right access from callee)
//===----------------------------------------------------------------------===//

// Physical register assignment tables, indexed by argument position (0-based).
static const MCPhysReg ArgRegsI8[]  = {V6C::A, V6C::E, V6C::C};
static const MCPhysReg ArgRegsI16[] = {V6C::HL, V6C::DE, V6C::BC};
static const unsigned NumRegArgs = 3;

SDValue V6CTargetLowering::LowerFormalArguments(
    SDValue Chain, CallingConv::ID CallConv, bool isVarArg,
    const SmallVectorImpl<ISD::InputArg> &Ins, const SDLoc &DL,
    SelectionDAG &DAG, SmallVectorImpl<SDValue> &InVals) const {
  MachineFunction &MF = DAG.getMachineFunction();
  MachineFrameInfo &MFI = MF.getFrameInfo();
  MachineRegisterInfo &RegInfo = MF.getRegInfo();

  unsigned ArgIdx = 0; // Tracks position in calling convention.

  for (unsigned i = 0, e = Ins.size(); i != e; ++i) {
    MVT VT = Ins[i].VT;

    if (ArgIdx < NumRegArgs) {
      // Register argument.
      if (VT == MVT::i8) {
        Register VReg = RegInfo.createVirtualRegister(&V6C::GR8RegClass);
        RegInfo.addLiveIn(ArgRegsI8[ArgIdx], VReg);
        SDValue ArgVal = DAG.getCopyFromReg(Chain, DL, VReg, MVT::i8);
        InVals.push_back(ArgVal);
      } else if (VT == MVT::i16) {
        Register VReg = RegInfo.createVirtualRegister(&V6C::GR16RegClass);
        RegInfo.addLiveIn(ArgRegsI16[ArgIdx], VReg);
        SDValue ArgVal = DAG.getCopyFromReg(Chain, DL, VReg, MVT::i16);
        InVals.push_back(ArgVal);
      } else {
        report_fatal_error("V6C: unsupported argument type");
      }
      ++ArgIdx;
    } else {
      // Stack argument. Located above the return address (2 bytes).
      // Stack offsets: arg4 at SP+2, arg5 at SP+2+sizeof(arg4), etc.
      // The frame lowering will adjust these offsets once the frame is set up.
      unsigned Size = VT.getSizeInBits() / 8;
      int FI = MFI.CreateFixedObject(Size,
                                      /*SPOffset=*/0, // Adjusted later.
                                      /*IsImmutable=*/true);
      SDValue FIN = DAG.getFrameIndex(FI, MVT::i16);
      SDValue ArgVal = DAG.getLoad(VT, DL, Chain, FIN,
                                   MachinePointerInfo::getFixedStack(MF, FI));
      InVals.push_back(ArgVal);
      ++ArgIdx;
    }
  }

  return Chain;
}

//===----------------------------------------------------------------------===//
// LowerReturn — copy return value to physical registers
//
// Return: i8 → A, i16 → HL, i32 → DE:HL (DE=high, HL=low)
//===----------------------------------------------------------------------===//

SDValue V6CTargetLowering::LowerReturn(
    SDValue Chain, CallingConv::ID CallConv, bool isVarArg,
    const SmallVectorImpl<ISD::OutputArg> &Outs,
    const SmallVectorImpl<SDValue> &OutVals, const SDLoc &DL,
    SelectionDAG &DAG) const {
  SmallVector<SDValue, 4> RetOps;
  RetOps.push_back(Chain);

  SDValue Glue;

  // Return register assignment: i8→A, i16→HL (first), DE (second).
  // For i32 returns (type-legalized to two i16), this gives DE:HL.
  static const MCPhysReg RetRegsI16[] = {V6C::HL, V6C::DE};
  unsigned I16RetIdx = 0;

  for (unsigned i = 0, e = Outs.size(); i != e; ++i) {
    MVT VT = Outs[i].VT;
    SDValue Val = OutVals[i];

    if (VT == MVT::i8) {
      Chain = DAG.getCopyToReg(Chain, DL, V6C::A, Val, Glue);
      Glue = Chain.getValue(1);
      RetOps.push_back(DAG.getRegister(V6C::A, MVT::i8));
    } else if (VT == MVT::i16) {
      if (I16RetIdx >= 2)
        report_fatal_error("V6C: too many i16 return values");
      MCPhysReg Reg = RetRegsI16[I16RetIdx++];
      Chain = DAG.getCopyToReg(Chain, DL, Reg, Val, Glue);
      Glue = Chain.getValue(1);
      RetOps.push_back(DAG.getRegister(Reg, MVT::i16));
    } else {
      report_fatal_error("V6C: unsupported return type");
    }
  }

  RetOps[0] = Chain; // Update chain.
  if (Glue.getNode())
    RetOps.push_back(Glue);

  return DAG.getNode(V6CISD::RET, DL, MVT::Other, RetOps);
}

//===----------------------------------------------------------------------===//
// LowerCall — function call lowering with full calling convention
//
// V6C_CConv: position-based — see LowerFormalArguments for mapping.
// Stack args pushed right-to-left. Caller cleans up after return.
//===----------------------------------------------------------------------===//

SDValue V6CTargetLowering::LowerCall(TargetLowering::CallLoweringInfo &CLI,
                                      SmallVectorImpl<SDValue> &InVals) const {
  // V6C does not support tail calls at the ISel level. Reset the flag so
  // LLVM's generic machinery emits a normal CALL + RET sequence.
  CLI.IsTailCall = false;

  SelectionDAG &DAG = CLI.DAG;
  SDLoc DL = CLI.DL;
  SmallVectorImpl<ISD::OutputArg> &Outs = CLI.Outs;
  SmallVectorImpl<SDValue> &OutVals = CLI.OutVals;
  SmallVectorImpl<ISD::InputArg> &Ins = CLI.Ins;
  SDValue Chain = CLI.Chain;
  SDValue Callee = CLI.Callee;
  CallingConv::ID CallConv = CLI.CallConv;

  SmallVector<std::pair<Register, SDValue>, 4> RegsToPass;
  SmallVector<SDValue, 8> MemOpChains;
  SDValue Glue;

  // Compute total stack bytes needed for overflow arguments.
  unsigned NumStackBytes = 0;
  unsigned ArgIdx = 0;
  for (unsigned i = 0, e = Outs.size(); i != e; ++i) {
    MVT VT = Outs[i].VT;
    if (ArgIdx >= NumRegArgs) {
      unsigned Size = VT.getSizeInBits() / 8;
      NumStackBytes += Size;
    }
    ++ArgIdx;
  }

  // ADJCALLSTACKDOWN.
  Chain = DAG.getCALLSEQ_START(Chain, NumStackBytes, 0, DL);

  // Assign arguments: register args first, then stack.
  ArgIdx = 0;
  unsigned StackOffset = 0;
  for (unsigned i = 0, e = Outs.size(); i != e; ++i) {
    MVT VT = Outs[i].VT;
    SDValue Arg = OutVals[i];

    if (ArgIdx < NumRegArgs) {
      // Register argument.
      MCPhysReg Reg;
      if (VT == MVT::i8)
        Reg = ArgRegsI8[ArgIdx];
      else if (VT == MVT::i16)
        Reg = ArgRegsI16[ArgIdx];
      else
        report_fatal_error("V6C: unsupported call argument type");

      RegsToPass.push_back(std::make_pair(Reg, Arg));
    } else {
      // Stack argument. Push right-to-left (last arg at highest address).
      // We store to the outgoing argument area of the current frame.
      unsigned Size = VT.getSizeInBits() / 8;
      SDValue PtrOff = DAG.getIntPtrConstant(StackOffset, DL);
      SDValue SPAddr = DAG.getCopyFromReg(Chain, DL, V6C::SP, MVT::i16);
      SDValue Addr = DAG.getNode(ISD::ADD, DL, MVT::i16, SPAddr, PtrOff);
      SDValue Store = DAG.getStore(Chain, DL, Arg, Addr,
                                   MachinePointerInfo());
      MemOpChains.push_back(Store);
      StackOffset += Size;
    }
    ++ArgIdx;
  }

  // Emit all stores.
  if (!MemOpChains.empty())
    Chain = DAG.getNode(ISD::TokenFactor, DL, MVT::Other, MemOpChains);

  // Emit CopyToReg for each register argument.
  for (auto &Reg : RegsToPass) {
    Chain = DAG.getCopyToReg(Chain, DL, Reg.first, Reg.second, Glue);
    Glue = Chain.getValue(1);
  }

  // If the callee is a GlobalAddress or ExternalSymbol, wrap it.
  if (GlobalAddressSDNode *G = dyn_cast<GlobalAddressSDNode>(Callee))
    Callee = DAG.getTargetGlobalAddress(G->getGlobal(), DL, MVT::i16);
  else if (ExternalSymbolSDNode *E = dyn_cast<ExternalSymbolSDNode>(Callee))
    Callee = DAG.getTargetExternalSymbol(E->getSymbol(), MVT::i16);

  // Build the call node.
  SmallVector<SDValue, 8> Ops;
  Ops.push_back(Chain);
  Ops.push_back(Callee);

  // Add register arguments as implicit operands.
  for (auto &Reg : RegsToPass)
    Ops.push_back(DAG.getRegister(Reg.first,
                                  Reg.second.getValueType()));

  // Add a register mask indicating all registers are clobbered.
  const TargetRegisterInfo *TRI =
      DAG.getMachineFunction().getSubtarget().getRegisterInfo();
  const uint32_t *Mask =
      TRI->getCallPreservedMask(DAG.getMachineFunction(), CallConv);
  Ops.push_back(DAG.getRegisterMask(Mask));

  if (Glue.getNode())
    Ops.push_back(Glue);

  SDVTList NodeTys = DAG.getVTList(MVT::Other, MVT::Glue);
  Chain = DAG.getNode(V6CISD::CALL, DL, NodeTys, Ops);
  Glue = Chain.getValue(1);

  // ADJCALLSTACKUP.
  Chain = DAG.getCALLSEQ_END(Chain, NumStackBytes, 0, Glue, DL);
  Glue = Chain.getValue(1);

  // Copy return values from physical registers.
  for (unsigned i = 0, e = Ins.size(); i != e; ++i) {
    MVT VT = Ins[i].VT;
    MCPhysReg RetReg;
    if (VT == MVT::i8)
      RetReg = V6C::A;
    else if (VT == MVT::i16)
      RetReg = V6C::HL;
    else
      report_fatal_error("V6C: unsupported call return type");

    Chain = DAG.getCopyFromReg(Chain, DL, RetReg, VT, Glue).getValue(1);
    InVals.push_back(Chain.getValue(0));
    Glue = Chain.getValue(2);
  }

  return Chain;
}

//===----------------------------------------------------------------------===//
// EmitInstrWithCustomInserter — expand pseudo-instructions
//===----------------------------------------------------------------------===//

MachineBasicBlock *
V6CTargetLowering::EmitInstrWithCustomInserter(MachineInstr &MI,
                                                MachineBasicBlock *BB) const {
  switch (MI.getOpcode()) {
  default:
    llvm_unreachable("Unexpected instr type to insert");
  case V6C::V6C_SELECT_CC:
  case V6C::V6C_SELECT_CC16: {
    // Expand V6C_SELECT_CC into a diamond control flow:
    //   BB:
    //     ... (FLAGS set by preceding CMP)
    //     J_inv SinkBB        ; branch on inverted condition (false path)
    //   TrueBB:               ; fallthrough from BB (true path)
    //     ... = TrueVal
    //   SinkBB:               ; fallthrough from TrueBB
    //     ... = PHI(TrueVal from TrueBB, FalseVal from BB)

    const TargetInstrInfo &TII = *BB->getParent()->getSubtarget().getInstrInfo();
    DebugLoc DL = MI.getDebugLoc();

    Register DstReg = MI.getOperand(0).getReg();
    Register TrueReg = MI.getOperand(1).getReg();
    Register FalseReg = MI.getOperand(2).getReg();
    int64_t CC = MI.getOperand(3).getImm();

    // Create new basic blocks.
    MachineFunction *MF = BB->getParent();
    MachineBasicBlock *TrueBB = MF->CreateMachineBasicBlock();
    MachineBasicBlock *SinkBB = MF->CreateMachineBasicBlock();

    MachineFunction::iterator It = ++BB->getIterator();
    MF->insert(It, TrueBB);
    MF->insert(It, SinkBB);

    // Transfer successors and remaining instructions to SinkBB.
    SinkBB->splice(SinkBB->begin(), BB,
                   std::next(MachineBasicBlock::iterator(MI)), BB->end());
    SinkBB->transferSuccessorsAndUpdatePHIs(BB);

    // BB: emit inverted conditional branch to SinkBB (false path).
    // Layout is BB → TrueBB → SinkBB, so TrueBB is the fallthrough.
    // Branch on the INVERTED condition to SinkBB; fall through to TrueBB.
    unsigned InvJccOpc;
    switch (CC) {
    default: llvm_unreachable("Unknown V6C condition code");
    case V6CCC::COND_NZ: InvJccOpc = V6C::JZ;  break;
    case V6CCC::COND_Z:  InvJccOpc = V6C::JNZ; break;
    case V6CCC::COND_NC: InvJccOpc = V6C::JC;  break;
    case V6CCC::COND_C:  InvJccOpc = V6C::JNC; break;
    case V6CCC::COND_PO: InvJccOpc = V6C::JPE; break;
    case V6CCC::COND_PE: InvJccOpc = V6C::JPO; break;
    case V6CCC::COND_P:  InvJccOpc = V6C::JM;  break;
    case V6CCC::COND_M:  InvJccOpc = V6C::JP;  break;
    }

    BuildMI(BB, DL, TII.get(InvJccOpc)).addMBB(SinkBB);
    BB->addSuccessor(TrueBB);
    BB->addSuccessor(SinkBB);

    // TrueBB: just falls through to SinkBB (value comes from TrueReg).
    TrueBB->addSuccessor(SinkBB);

    // SinkBB: PHI node merges TrueReg and FalseReg.
    BuildMI(*SinkBB, SinkBB->begin(), DL, TII.get(TargetOpcode::PHI), DstReg)
        .addReg(TrueReg).addMBB(TrueBB)
        .addReg(FalseReg).addMBB(BB);

    MI.eraseFromParent();
    return SinkBB;
  }
  }
}

//===----------------------------------------------------------------------===//
// Inline assembly support
//===----------------------------------------------------------------------===//

TargetLowering::ConstraintType
V6CTargetLowering::getConstraintType(StringRef Constraint) const {
  if (Constraint.size() == 1) {
    switch (Constraint[0]) {
    case 'a': // Accumulator (A)
    case 'r': // Any 8-bit GPR
    case 'p': // 16-bit register pair
      return C_RegisterClass;
    case 'I': // 8-bit unsigned immediate
    case 'J': // 16-bit unsigned immediate
      return C_Immediate;
    default:
      break;
    }
  }
  return TargetLowering::getConstraintType(Constraint);
}

std::pair<unsigned, const TargetRegisterClass *>
V6CTargetLowering::getRegForInlineAsmConstraint(
    const TargetRegisterInfo *TRI, StringRef Constraint, MVT VT) const {
  if (Constraint.size() == 1) {
    switch (Constraint[0]) {
    case 'a': // Accumulator
      return std::make_pair(V6C::A, &V6C::AccRegClass);
    case 'r': // Any 8-bit GPR
      if (VT == MVT::i16)
        return std::make_pair(0U, &V6C::GR16RegClass);
      return std::make_pair(0U, &V6C::GR8RegClass);
    case 'p': // 16-bit register pair
      return std::make_pair(0U, &V6C::GR16RegClass);
    default:
      break;
    }
  }
  return TargetLowering::getRegForInlineAsmConstraint(TRI, Constraint, VT);
}
