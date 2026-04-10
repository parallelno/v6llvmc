//===-- V6CInstrInfo.td - V6C Instruction Definitions ------*- tablegen -*-===//
//
// Part of the V6C backend for LLVM.
//
// Complete instruction set for the Intel 8080 / KR580VM80A.
// See design.md §4.2 for instruction categories and modeling notes.
//
// Encoding reference: Intel 8080 opcode map.
// All encodings validated against v6asm output (plan M2 step 9).
//
//===----------------------------------------------------------------------===//

include "V6CInstrFormats.td"

//===----------------------------------------------------------------------===//
// Operand types
//===----------------------------------------------------------------------===//

def imm8  : Operand<i8>;
def imm16 : Operand<i16>;
def i8port : Operand<i8>;

// Branch target (16-bit absolute address)
def brtarget : Operand<OtherVT> {
  let PrintMethod = "printBrTarget";
}

//===----------------------------------------------------------------------===//
// 8080 Condition codes (3-bit encoding for Jcc/Ccc/Rcc)
//===----------------------------------------------------------------------===//
//   NZ=000, Z=001, NC=010, C=011, PO=100, PE=101, P=110, M=111

//===----------------------------------------------------------------------===//
// V6C-specific SDNode definitions
//===----------------------------------------------------------------------===//

def SDT_V6CRet     : SDTypeProfile<0, 0, []>;
def SDT_V6CCall    : SDTypeProfile<0, 1, [SDTCisVT<0, iPTR>]>;
def SDT_V6CCmp     : SDTypeProfile<0, 2, [SDTCisSameAs<0, 1>]>;
def SDT_V6CBrCond  : SDTypeProfile<0, 2, [SDTCisVT<0, OtherVT>,
                                           SDTCisVT<1, i8>]>;
def SDT_V6CSelectCC : SDTypeProfile<1, 3, [SDTCisSameAs<0, 1>,
                                            SDTCisSameAs<1, 2>,
                                            SDTCisVT<3, i8>]>;
def SDT_V6CWrapper : SDTypeProfile<1, 1, [SDTCisSameAs<0, 1>,
                                           SDTCisPtrTy<0>]>;

def V6Cretflag  : SDNode<"V6CISD::RET", SDTNone,
                          [SDNPHasChain, SDNPOptInGlue, SDNPVariadic]>;
def V6Ccall     : SDNode<"V6CISD::CALL", SDT_V6CCall,
                          [SDNPHasChain, SDNPOutGlue, SDNPOptInGlue,
                           SDNPVariadic]>;
def V6Ccmp      : SDNode<"V6CISD::CMP", SDT_V6CCmp, [SDNPOutGlue]>;
def V6Cbrcond   : SDNode<"V6CISD::BRCOND", SDT_V6CBrCond,
                          [SDNPHasChain, SDNPInGlue]>;
def V6Cselectcc : SDNode<"V6CISD::SELECT_CC", SDT_V6CSelectCC,
                          [SDNPInGlue]>;
def V6Cwrapper  : SDNode<"V6CISD::Wrapper", SDT_V6CWrapper>;

// BR_CC16: chain, lhs(i16), rhs(i16), cc(i8), dest(OtherVT) → chain
def SDT_V6CBrCC16 : SDTypeProfile<0, 4, [SDTCisVT<0, i16>,
                                          SDTCisVT<1, i16>,
                                          SDTCisVT<2, i8>,
                                          SDTCisVT<3, OtherVT>]>;
def V6Cbrcc16 : SDNode<"V6CISD::BR_CC16", SDT_V6CBrCC16,
                        [SDNPHasChain]>;

// SEXT: sign-extend i8 to i16
def SDT_V6CSext : SDTypeProfile<1, 1, [SDTCisVT<0, i16>, SDTCisVT<1, i8>]>;
def V6Csext    : SDNode<"V6CISD::SEXT", SDT_V6CSext>;

// SRL16/SRA16: right-shift i16 by constant i8 amount
def SDT_V6CShift16 : SDTypeProfile<1, 2, [SDTCisVT<0, i16>,
                                            SDTCisVT<1, i16>,
                                            SDTCisVT<2, i8>]>;
def V6Csrl16 : SDNode<"V6CISD::SRL16", SDT_V6CShift16>;
def V6Csra16 : SDNode<"V6CISD::SRA16", SDT_V6CShift16>;

// DAD: 16-bit add constrained to HL pair (maps to physical DAD rp).
def V6Cdad : SDNode<"V6CISD::DAD", SDTIntBinOp, [SDNPCommutative]>;

//===----------------------------------------------------------------------===//
// V6C condition codes (used in BRCOND and SELECT_CC)
//===----------------------------------------------------------------------===//

def V6CCC_NZ : PatLeaf<(i8 0)>;   // Not zero
def V6CCC_Z  : PatLeaf<(i8 1)>;   // Zero
def V6CCC_NC : PatLeaf<(i8 2)>;   // No carry
def V6CCC_C  : PatLeaf<(i8 3)>;   // Carry
def V6CCC_PO : PatLeaf<(i8 4)>;   // Parity odd
def V6CCC_PE : PatLeaf<(i8 5)>;   // Parity even
def V6CCC_P  : PatLeaf<(i8 6)>;   // Plus (positive)
def V6CCC_M  : PatLeaf<(i8 7)>;   // Minus (negative)

//===----------------------------------------------------------------------===//
// Data Move — MOV, MVI
//===----------------------------------------------------------------------===//

// MOV r,r — 01_DDD_SSS (register-to-register)
def MOVrr : V6CInstRegDstSrc<
    (outs GR8:$rd), (ins GR8:$rs),
    "MOV\t$rd, $rs", []>;

// MOV r,M — 01_DDD_110 (memory-to-register, via HL pointer)
let Uses = [HL], mayLoad = 1 in
def MOVrM : V6CInstRegDst<0b110,
    (outs GR8:$rd), (ins),
    "MOV\t$rd, M", []> {
  let Inst{7-6} = 0b01;
}

// MOV M,r — 01_110_SSS (register-to-memory, via HL pointer)
let Uses = [HL], mayStore = 1 in
def MOVMr : V6CInstRegSrc<0b110,
    (outs), (ins GR8:$rs),
    "MOV\tM, $rs", []> {
  let Inst{7-6} = 0b01;
  let Inst{5-3} = 0b110;
}

// MVI r,d8 — 00_DDD_110 [d8]
let isReMaterializable = 1, isAsCheapAsAMove = 1 in
def MVIr : V6CInstImm8Dst<
    (outs GR8:$rd), (ins imm8:$imm),
    "MVI\t$rd, $imm", [(set i8:$rd, (i8 imm:$imm))]>;

// MVI M,d8 — 00_110_110 [d8] = 0x36
let Uses = [HL], mayStore = 1 in
def MVIM : V6CInstImm8Opc<0b110,
    (outs), (ins imm8:$imm),
    "MVI\tM, $imm", []> {
  let Inst{15-14} = 0b00;
  let Inst{10-8}  = 0b110;
}

//===----------------------------------------------------------------------===//
// Data Move — LDA, STA, LDAX, STAX, LHLD, SHLD
//===----------------------------------------------------------------------===//

// LDA addr — 0x3A [lo] [hi]
let mayLoad = 1 in
def LDA : V6CInstImm16Opc<0x3A,
    (outs Acc:$dst), (ins imm16:$addr),
    "LDA\t$addr", []>;

// STA addr — 0x32 [lo] [hi]
let mayStore = 1 in
def STA : V6CInstImm16Opc<0x32,
    (outs), (ins Acc:$src, imm16:$addr),
    "STA\t$addr", []>;

// LDAX rp — 00_RP_1010 (rp = BC or DE)
let mayLoad = 1 in
def LDAX : V6CInstRegPair<0b00, 0b1010,
    (outs Acc:$dst), (ins GR16Idx:$rp),
    "LDAX\t$rp", []>;

// STAX rp — 00_RP_0010 (rp = BC or DE)
let mayStore = 1 in
def STAX : V6CInstRegPair<0b00, 0b0010,
    (outs), (ins Acc:$src, GR16Idx:$rp),
    "STAX\t$rp", []>;

// LHLD addr — 0x2A [lo] [hi]
// Always loads into HL (implicit). Modeled with GR16Ptr output for regalloc.
let mayLoad = 1 in
def LHLD : V6CInstImm16Opc<0x2A,
    (outs GR16Ptr:$dst), (ins imm16:$addr),
    "LHLD\t$addr", []>;

// SHLD addr — 0x22 [lo] [hi]
// Always stores from HL (implicit). Modeled with GR16Ptr input for regalloc.
let mayStore = 1 in
def SHLD : V6CInstImm16Opc<0x22,
    (outs), (ins GR16Ptr:$src, imm16:$addr),
    "SHLD\t$addr", []>;

//===----------------------------------------------------------------------===//
// Data Move — LXI (load immediate 16-bit)
//===----------------------------------------------------------------------===//

// LXI rp,d16 — 00_RP_0001 [lo] [hi]
let isReMaterializable = 1, isAsCheapAsAMove = 1 in
def LXI : V6CInstImm16Pair<
    (outs GR16All:$rp), (ins imm16:$imm),
    "LXI\t$rp, $imm", []>;

//===----------------------------------------------------------------------===//
// Data Move — XCHG
//===----------------------------------------------------------------------===//

// XCHG — 0xEB — Exchange DE and HL
let Defs = [DE, HL], Uses = [DE, HL] in
def XCHG : V6CInstImplied<0xEB,
    (outs), (ins),
    "XCHG", []>;

//===----------------------------------------------------------------------===//
// Stack Operations — PUSH, POP, SPHL, XTHL
//===----------------------------------------------------------------------===//

// PUSH rp — 11_RP_0101 (rp: BC=00, DE=01, HL=10, PSW=11)
let Uses = [SP], Defs = [SP], mayStore = 1 in
def PUSH : V6CInstRegPair<0b11, 0b0101,
    (outs), (ins GR16All:$rp),
    "PUSH\t$rp", []>;

// POP rp — 11_RP_0001 (rp: BC=00, DE=01, HL=10, PSW=11)
let Uses = [SP], Defs = [SP], mayLoad = 1 in
def POP : V6CInstRegPair<0b11, 0b0001,
    (outs GR16All:$rp), (ins),
    "POP\t$rp", []>;

// SPHL — 0xF9 — Load SP from HL
let Uses = [HL], Defs = [SP] in
def SPHL : V6CInstImplied<0xF9,
    (outs), (ins),
    "SPHL", []>;

// XTHL — 0xE3 — Exchange top-of-stack with HL
let Uses = [SP, HL], Defs = [HL], mayLoad = 1, mayStore = 1 in
def XTHL : V6CInstImplied<0xE3,
    (outs), (ins),
    "XTHL", []>;

//===----------------------------------------------------------------------===//
// ALU 8-bit — Register operand: ADD, ADC, SUB, SBB, ANA, ORA, XRA, CMP
// Format: 10_OOO_SSS
//
// OPC encoding: ADD=000, ADC=001, SUB=010, SBB=011,
//               ANA=100, XRA=101, ORA=110, CMP=111
//
// All arithmetic/logic ops use the accumulator (A) as implicit LHS and
// destination.  We model A as an explicit Acc operand so the register
// allocator sees the data-flow.  FLAGS is an implicit def.
//===----------------------------------------------------------------------===//

// --- Register source variants ---

// Ops that read and write A — explicit Acc in/out, FLAGS implicit def
let Defs = [FLAGS] in {
  let Constraints = "$dst = $lhs" in {
    def ADDr : V6CInstRegSrc<0b000,
        (outs Acc:$dst), (ins Acc:$lhs, GR8:$rs),
        "ADD\t$rs", [(set i8:$dst, (add i8:$lhs, i8:$rs))]>;
    def ADCr : V6CInstRegSrc<0b001,
        (outs Acc:$dst), (ins Acc:$lhs, GR8:$rs),
        "ADC\t$rs", []>;
    def SUBr : V6CInstRegSrc<0b010,
        (outs Acc:$dst), (ins Acc:$lhs, GR8:$rs),
        "SUB\t$rs", [(set i8:$dst, (sub i8:$lhs, i8:$rs))]>;
    def SBBr : V6CInstRegSrc<0b011,
        (outs Acc:$dst), (ins Acc:$lhs, GR8:$rs),
        "SBB\t$rs", []>;
    def ANAr : V6CInstRegSrc<0b100,
        (outs Acc:$dst), (ins Acc:$lhs, GR8:$rs),
        "ANA\t$rs", [(set i8:$dst, (and i8:$lhs, i8:$rs))]>;
    def XRAr : V6CInstRegSrc<0b101,
        (outs Acc:$dst), (ins Acc:$lhs, GR8:$rs),
        "XRA\t$rs", [(set i8:$dst, (xor i8:$lhs, i8:$rs))]>;
    def ORAr : V6CInstRegSrc<0b110,
        (outs Acc:$dst), (ins Acc:$lhs, GR8:$rs),
        "ORA\t$rs", [(set i8:$dst, (or i8:$lhs, i8:$rs))]>;
  }

  // CMP: reads A but does NOT modify it — no output, sets FLAGS only
  def CMPr : V6CInstRegSrc<0b111,
      (outs), (ins Acc:$lhs, GR8:$rs),
      "CMP\t$rs", [(V6Ccmp i8:$lhs, i8:$rs)]>;
}

// --- Memory (M via HL) source variants ---
// Same opcode pattern but src bits = 110 (M)
// Explicit Acc in/out, FLAGS implicit def, HL implicit use.

let Defs = [FLAGS], Uses = [HL], mayLoad = 1 in {
  let Constraints = "$dst = $lhs" in {
    def ADDM : V6CInstImplied<0x86, (outs Acc:$dst), (ins Acc:$lhs), "ADD\tM", []>;
    def ADCM : V6CInstImplied<0x8E, (outs Acc:$dst), (ins Acc:$lhs), "ADC\tM", []>;
    def SUBM : V6CInstImplied<0x96, (outs Acc:$dst), (ins Acc:$lhs), "SUB\tM", []>;
    def SBBM : V6CInstImplied<0x9E, (outs Acc:$dst), (ins Acc:$lhs), "SBB\tM", []>;
    def ANAM : V6CInstImplied<0xA6, (outs Acc:$dst), (ins Acc:$lhs), "ANA\tM", []>;
    def XRAM : V6CInstImplied<0xAE, (outs Acc:$dst), (ins Acc:$lhs), "XRA\tM", []>;
    def ORAM : V6CInstImplied<0xB6, (outs Acc:$dst), (ins Acc:$lhs), "ORA\tM", []>;
  }
  // CMP M: reads A, does NOT modify it
  def CMPM : V6CInstImplied<0xBE, (outs), (ins Acc:$lhs), "CMP\tM", []>;
}

//===----------------------------------------------------------------------===//
// ALU 8-bit — Immediate: ADI, ACI, SUI, SBI, ANI, ORI, XRI, CPI
// Format: 11_OOO_110 [d8]
//===----------------------------------------------------------------------===//

let Defs = [FLAGS] in {
  let Constraints = "$dst = $lhs" in {
    def ADI : V6CInstImm8Opc<0b000,
        (outs Acc:$dst), (ins Acc:$lhs, imm8:$imm),
        "ADI\t$imm", [(set i8:$dst, (add i8:$lhs, (i8 imm:$imm)))]>;
    def ACI : V6CInstImm8Opc<0b001,
        (outs Acc:$dst), (ins Acc:$lhs, imm8:$imm),
        "ACI\t$imm", []>;
    def SUI : V6CInstImm8Opc<0b010,
        (outs Acc:$dst), (ins Acc:$lhs, imm8:$imm),
        "SUI\t$imm", [(set i8:$dst, (sub i8:$lhs, (i8 imm:$imm)))]>;
    def SBI : V6CInstImm8Opc<0b011,
        (outs Acc:$dst), (ins Acc:$lhs, imm8:$imm),
        "SBI\t$imm", []>;
    def ANI : V6CInstImm8Opc<0b100,
        (outs Acc:$dst), (ins Acc:$lhs, imm8:$imm),
        "ANI\t$imm", [(set i8:$dst, (and i8:$lhs, (i8 imm:$imm)))]>;
    def XRI : V6CInstImm8Opc<0b101,
        (outs Acc:$dst), (ins Acc:$lhs, imm8:$imm),
        "XRI\t$imm", [(set i8:$dst, (xor i8:$lhs, (i8 imm:$imm)))]>;
    def ORI : V6CInstImm8Opc<0b110,
        (outs Acc:$dst), (ins Acc:$lhs, imm8:$imm),
        "ORI\t$imm", [(set i8:$dst, (or i8:$lhs, (i8 imm:$imm)))]>;
  }
  // CPI: reads A, does NOT modify it — sets FLAGS only
  def CPI : V6CInstImm8Opc<0b111,
      (outs), (ins Acc:$lhs, imm8:$imm),
      "CPI\t$imm", [(V6Ccmp i8:$lhs, (i8 imm:$imm))]>;
}

//===----------------------------------------------------------------------===//
// ALU 16-bit — DAD, INX, DCX
//===----------------------------------------------------------------------===//

// DAD rp — 00_RP_1001 — Add rp to HL
let Defs = [HL, FLAGS], Uses = [HL] in
def DAD : V6CInstRegPair<0b00, 0b1001,
    (outs), (ins GR16All:$rp),
    "DAD\t$rp", []>;

// INX rp — 00_RP_0011 — Increment register pair
let Constraints = "$rp = $src" in
def INX : V6CInstRegPair<0b00, 0b0011,
    (outs GR16All:$rp), (ins GR16All:$src),
    "INX\t$rp", []>;

// DCX rp — 00_RP_1011 — Decrement register pair
let Constraints = "$rp = $src" in
def DCX : V6CInstRegPair<0b00, 0b1011,
    (outs GR16All:$rp), (ins GR16All:$src),
    "DCX\t$rp", []>;

//===----------------------------------------------------------------------===//
// Increment / Decrement 8-bit — INR, DCR
//===----------------------------------------------------------------------===//

// INR r — 00_DDD_100 — Sets all flags except CY
let Defs = [FLAGS] in
def INRr : V6CInstRegDst<0b100,
    (outs GR8:$rd), (ins GR8:$src),
    "INR\t$rd", [(set i8:$rd, (add i8:$src, (i8 1)))]> {
  let Constraints = "$rd = $src";
}

// DCR r — 00_DDD_101 — Sets all flags except CY
let Defs = [FLAGS] in
def DCRr : V6CInstRegDst<0b101,
    (outs GR8:$rd), (ins GR8:$src),
    "DCR\t$rd", [(set i8:$rd, (add i8:$src, (i8 -1)))]> {
  let Constraints = "$rd = $src";
}

// INR M — 0x34 — Increment memory at (HL)
let Defs = [FLAGS], Uses = [HL], mayLoad = 1, mayStore = 1 in
def INRM : V6CInstImplied<0x34,
    (outs), (ins), "INR\tM", []>;

// DCR M — 0x35 — Decrement memory at (HL)
let Defs = [FLAGS], Uses = [HL], mayLoad = 1, mayStore = 1 in
def DCRM : V6CInstImplied<0x35,
    (outs), (ins), "DCR\tM", []>;

//===----------------------------------------------------------------------===//
// Rotate — RLC, RRC, RAL, RAR (accumulator only, 4cc)
//===----------------------------------------------------------------------===//

let Defs = [FLAGS] in {
  let Constraints = "$dst = $src" in {
    def RLC : V6CInstImplied<0x07, (outs Acc:$dst), (ins Acc:$src), "RLC", []>;
    def RRC : V6CInstImplied<0x0F, (outs Acc:$dst), (ins Acc:$src), "RRC", []>;
    def RAL : V6CInstImplied<0x17, (outs Acc:$dst), (ins Acc:$src), "RAL", []>;
    def RAR : V6CInstImplied<0x1F, (outs Acc:$dst), (ins Acc:$src), "RAR", []>;
  }
}

//===----------------------------------------------------------------------===//
// Branch — JMP, Jcc
//===----------------------------------------------------------------------===//

// JMP addr — 0xC3 [lo] [hi]
let isBranch = 1, isTerminator = 1, isBarrier = 1 in
def JMP : V6CInstImm16Opc<0xC3,
    (outs), (ins brtarget:$addr),
    "JMP\t$addr", []>;

// Conditional jumps — 11_CCC_010 [lo] [hi]
//   NZ=000, Z=001, NC=010, C=011, PO=100, PE=101, P=110, M=111
let isBranch = 1, isTerminator = 1, Uses = [FLAGS] in {
  def JNZ : V6CInstImm16Opc<0xC2, (outs), (ins brtarget:$addr), "JNZ\t$addr", []>;
  def JZ  : V6CInstImm16Opc<0xCA, (outs), (ins brtarget:$addr), "JZ\t$addr", []>;
  def JNC : V6CInstImm16Opc<0xD2, (outs), (ins brtarget:$addr), "JNC\t$addr", []>;
  def JC  : V6CInstImm16Opc<0xDA, (outs), (ins brtarget:$addr), "JC\t$addr", []>;
  def JPO : V6CInstImm16Opc<0xE2, (outs), (ins brtarget:$addr), "JPO\t$addr", []>;
  def JPE : V6CInstImm16Opc<0xEA, (outs), (ins brtarget:$addr), "JPE\t$addr", []>;
  def JP  : V6CInstImm16Opc<0xF2, (outs), (ins brtarget:$addr), "JP\t$addr", []>;
  def JM  : V6CInstImm16Opc<0xFA, (outs), (ins brtarget:$addr), "JM\t$addr", []>;
}

// PCHL — 0xE9 — Jump to address in HL
let isBranch = 1, isTerminator = 1, isBarrier = 1, isIndirectBranch = 1,
    Uses = [HL] in
def PCHL : V6CInstImplied<0xE9,
    (outs), (ins), "PCHL", []>;

//===----------------------------------------------------------------------===//
// Call — CALL, Ccc
//===----------------------------------------------------------------------===//

// CALL addr — 0xCD [lo] [hi]
// All registers clobbered (no callee-saved per design §6.1).
// The register mask on the MachineInstr (added by LowerCall) handles clobbers;
// Defs here just lists SP (for stack adjustment).
let isCall = 1, Uses = [SP], Defs = [SP, A, B, C, D, E, H, L, FLAGS] in
def CALL : V6CInstImm16Opc<0xCD,
    (outs), (ins brtarget:$addr),
    "CALL\t$addr", []>;

// Conditional calls — 11_CCC_100 [lo] [hi]
let isCall = 1, Uses = [SP, FLAGS], Defs = [SP] in {
  def CNZ : V6CInstImm16Opc<0xC4, (outs), (ins brtarget:$addr), "CNZ\t$addr", []>;
  def CZ  : V6CInstImm16Opc<0xCC, (outs), (ins brtarget:$addr), "CZ\t$addr", []>;
  def CNC : V6CInstImm16Opc<0xD4, (outs), (ins brtarget:$addr), "CNC\t$addr", []>;
  def CC  : V6CInstImm16Opc<0xDC, (outs), (ins brtarget:$addr), "CC\t$addr", []>;
  def CPO : V6CInstImm16Opc<0xE4, (outs), (ins brtarget:$addr), "CPO\t$addr", []>;
  def CPE : V6CInstImm16Opc<0xEC, (outs), (ins brtarget:$addr), "CPE\t$addr", []>;
  def CP  : V6CInstImm16Opc<0xF4, (outs), (ins brtarget:$addr), "CP\t$addr", []>;
  def CM  : V6CInstImm16Opc<0xFC, (outs), (ins brtarget:$addr), "CM\t$addr", []>;
}

//===----------------------------------------------------------------------===//
// Return — RET, Rcc
//===----------------------------------------------------------------------===//

// RET — 0xC9
let isReturn = 1, isTerminator = 1, isBarrier = 1,
    Uses = [SP], Defs = [SP], mayLoad = 1 in
def RET : V6CInstImplied<0xC9,
    (outs), (ins), "RET", [(V6Cretflag)]>;

// Conditional returns — 11_CCC_000
let isReturn = 1, isTerminator = 1,
    Uses = [SP, FLAGS], Defs = [SP], mayLoad = 1 in {
  def RNZ : V6CInstImplied<0xC0, (outs), (ins), "RNZ", []>;
  def RZ  : V6CInstImplied<0xC8, (outs), (ins), "RZ", []>;
  def RNC : V6CInstImplied<0xD0, (outs), (ins), "RNC", []>;
  def RC  : V6CInstImplied<0xD8, (outs), (ins), "RC", []>;
  def RPO : V6CInstImplied<0xE0, (outs), (ins), "RPO", []>;
  def RPE : V6CInstImplied<0xE8, (outs), (ins), "RPE", []>;
  def RP  : V6CInstImplied<0xF0, (outs), (ins), "RP", []>;
  def RM  : V6CInstImplied<0xF8, (outs), (ins), "RM", []>;
}

//===----------------------------------------------------------------------===//
// RST — Restart (RST 0-7)
// Encoding: 11_NNN_111
//===----------------------------------------------------------------------===//

let isCall = 1, Uses = [SP], Defs = [SP] in {
  def RST0 : V6CInstRST<0, (outs), (ins), "RST\t0", []>;
  def RST1 : V6CInstRST<1, (outs), (ins), "RST\t1", []>;
  def RST2 : V6CInstRST<2, (outs), (ins), "RST\t2", []>;
  def RST3 : V6CInstRST<3, (outs), (ins), "RST\t3", []>;
  def RST4 : V6CInstRST<4, (outs), (ins), "RST\t4", []>;
  def RST5 : V6CInstRST<5, (outs), (ins), "RST\t5", []>;
  def RST6 : V6CInstRST<6, (outs), (ins), "RST\t6", []>;
  def RST7 : V6CInstRST<7, (outs), (ins), "RST\t7", []>;
}

//===----------------------------------------------------------------------===//
// Miscellaneous — NOP, HLT, CMA, STC, CMC, DAA, EI, DI
//===----------------------------------------------------------------------===//

def NOP : V6CInstImplied<0x00, (outs), (ins), "NOP", []>;

let hasSideEffects = 1 in
def HLT : V6CInstImplied<0x76, (outs), (ins), "HLT", []>;

// CMA — Complement A
let Constraints = "$dst = $src" in
def CMA : V6CInstImplied<0x2F, (outs Acc:$dst), (ins Acc:$src), "CMA",
    [(set i8:$dst, (not i8:$src))]>;

// STC — Set carry flag
let Defs = [FLAGS] in
def STC : V6CInstImplied<0x37, (outs), (ins), "STC", []>;

// CMC — Complement carry flag
let Defs = [FLAGS], Uses = [FLAGS] in
def CMC : V6CInstImplied<0x3F, (outs), (ins), "CMC", []>;

// DAA — Decimal adjust accumulator
let Defs = [FLAGS], Uses = [FLAGS] in
def DAA : V6CInstImplied<0x27, (outs Acc:$dst), (ins Acc:$src), "DAA", []> {
  let Constraints = "$dst = $src";
}

// EI — Enable interrupts
let hasSideEffects = 1 in
def EI : V6CInstImplied<0xFB, (outs), (ins), "EI", []>;

// DI — Disable interrupts
let hasSideEffects = 1 in
def DI : V6CInstImplied<0xF3, (outs), (ins), "DI", []>;

//===----------------------------------------------------------------------===//
// I/O — IN, OUT
//===----------------------------------------------------------------------===//

// IN port — 0xDB [port]
let hasSideEffects = 1 in
def IN : V6CInstIO<0xDB,
    (outs Acc:$dst), (ins i8port:$port),
    "IN\t$port", []>;

// OUT port — 0xD3 [port]
let hasSideEffects = 1 in
def OUT : V6CInstIO<0xD3,
    (outs), (ins Acc:$src, i8port:$port),
    "OUT\t$port", []>;

//===----------------------------------------------------------------------===//
// Pseudo-instructions for M4 ISel
//===----------------------------------------------------------------------===//

// V6C_BRCOND — Conditional branch. Expanded to Jcc in post-ISel.
// Operand 0: branch target, Operand 1: V6C condition code (i8)
let isBranch = 1, isTerminator = 1, Uses = [FLAGS] in
def V6C_BRCOND : V6CPseudo<(outs),
    (ins brtarget:$dst, i8imm:$cc),
    "# V6C_BRCOND $dst, $cc",
    [(V6Cbrcond bb:$dst, (i8 imm:$cc))]>;

// V6C_SELECT_CC — Conditional select. Expanded to compare+branch sequence.
// Uses FLAGS (set by a preceding V6CISD::CMP).
let usesCustomInserter = 1, Uses = [FLAGS] in
def V6C_SELECT_CC : V6CPseudo<(outs GR8:$dst),
    (ins GR8:$trueval, GR8:$falseval, i8imm:$cc),
    "# V6C_SELECT_CC $dst, $trueval, $falseval, $cc",
    [(set i8:$dst, (V6Cselectcc i8:$trueval, i8:$falseval, (i8 imm:$cc)))]>;

// V6C_LOAD8_G — Load i8 from global address.
// Pseudo: expands to LXI HL, addr + MOV $dst, M
let mayLoad = 1, Defs = [HL] in
def V6C_LOAD8_G : V6CPseudo<(outs GR8:$dst), (ins imm16:$addr),
    "# LOAD8 $dst, $addr", []>;

// V6C_STORE8_G — Store i8 to global address.
// Pseudo: expands to LXI HL, addr + MOV M, $src
let mayStore = 1, Defs = [HL] in
def V6C_STORE8_G : V6CPseudo<(outs), (ins GR8:$src, imm16:$addr),
    "# STORE8 $src, $addr", []>;

// V6C_LOAD8_P — Load i8 from i16 pointer (in register pair).
// Pseudo: expands to HL = ptr, MOV $dst, M
// The ptr must be copied to HL first; expansion handles this.
let mayLoad = 1, Defs = [HL] in
def V6C_LOAD8_P : V6CPseudo<(outs GR8:$dst), (ins GR16:$addr),
    "# LOAD8P $dst, ($addr)",
    [(set i8:$dst, (load i16:$addr))]>;

// V6C_STORE8_P — Store i8 to i16 pointer (in register pair).
// Pseudo: expands to HL = ptr, MOV M, $src
let mayStore = 1, Defs = [HL] in
def V6C_STORE8_P : V6CPseudo<(outs), (ins GR8:$src, GR16:$addr),
    "# STORE8P $src, ($addr)",
    [(store i8:$src, i16:$addr)]>;

// Spill/reload pseudos for register allocation.
// Expanded in eliminateFrameIndex with PUSH/POP preservation.
// Non-H/L: PUSH HL; LXI HL,off+2; DAD SP; MOV M,r / MOV r,M; POP HL
// H/L:     PUSH DE; save other half in D; LXI+DAD; MOV H/L,M; restore; POP DE
// Only FLAGS is clobbered (by DAD SP). All other regs preserved via PUSH/POP.
let mayStore = 1, Defs = [FLAGS] in
def V6C_SPILL8 : V6CPseudo<(outs), (ins GR8:$src, i16imm:$fi),
    "# SPILL8 $src, $fi", []>;

let mayLoad = 1, Defs = [FLAGS] in
def V6C_RELOAD8 : V6CPseudo<(outs GR8:$dst), (ins i16imm:$fi),
    "# RELOAD8 $dst, $fi", []>;

// 16-bit spill/reload pseudos for register pair allocation.
// Expanded in eliminateFrameIndex with PUSH/POP preservation so that
// registers OTHER than the src/dst are not clobbered.
// Only FLAGS is clobbered (by DAD SP inside the expansion).
let mayStore = 1, Defs = [FLAGS] in
def V6C_SPILL16 : V6CPseudo<(outs), (ins GR16:$src, i16imm:$fi),
    "# SPILL16 $src, $fi", []>;

let mayLoad = 1, Defs = [FLAGS] in
def V6C_RELOAD16 : V6CPseudo<(outs GR16:$dst), (ins i16imm:$fi),
    "# RELOAD16 $dst, $fi", []>;

//===----------------------------------------------------------------------===//
// Pseudo-instructions (design §5.5)
// These expand to real instructions during or after ISel.
//===----------------------------------------------------------------------===//

// Adjcallstackdown / adjcallstackup — frame setup/teardown markers
let Defs = [SP], Uses = [SP], hasSideEffects = 1 in {
  def ADJCALLSTACKDOWN : V6CPseudo<(outs), (ins i16imm:$amt, i16imm:$amt2),
                                   "# ADJCALLSTACKDOWN $amt $amt2", []>;
  def ADJCALLSTACKUP   : V6CPseudo<(outs), (ins i16imm:$amt, i16imm:$amt2),
                                   "# ADJCALLSTACKUP $amt $amt2", []>;
}

// V6C_LEA_FI — Compute address of a frame index (stack slot).
// Expands in eliminateFrameIndex to: LXI HL, offset; DAD SP
let Defs = [FLAGS] in
def V6C_LEA_FI : V6CPseudo<(outs GR16:$dst), (ins i16imm:$fi),
    "# LEA $dst, $fi", []>;

//===----------------------------------------------------------------------===//
// Additional patterns — selected via Pat<> (no encoding change needed)
//===----------------------------------------------------------------------===//

// GlobalAddress lowering: (V6CWrapper GA) patterns
def : Pat<(V6Cwrapper tglobaladdr:$addr), (LXI tglobaladdr:$addr)>;
def : Pat<(V6Cwrapper texternalsym:$addr), (LXI texternalsym:$addr)>;

// Load i8 from global address via LDA (result always in A)
def : Pat<(i8 (load (V6Cwrapper tglobaladdr:$addr))),
          (LDA tglobaladdr:$addr)>;

// Store i8 to global address via STA (source must be in A)
def : Pat<(store i8:$val, (V6Cwrapper tglobaladdr:$addr)),
          (STA i8:$val, tglobaladdr:$addr)>;

// Unconditional branch → JMP
def : Pat<(br bb:$dst), (JMP bb:$dst)>;

// i16 constant materialization → LXI
def : Pat<(i16 imm:$val), (LXI imm:$val)>;

//===----------------------------------------------------------------------===//
// M7: i16 Pseudo-instructions
//===----------------------------------------------------------------------===//

// 16-bit arithmetic pseudos. These expand post-RA into 8-bit sequences via A.
// All clobber A (used as temp) and FLAGS.

// V6C_DAD: HL-constrained 16-bit add → physical DAD rp instruction.
// Result and lhs are tied and constrained to GR16Ptr (HL only).
// Does NOT clobber A — only FLAGS — giving better register pressure than
// the general V6C_ADD16 which uses an 8-bit chain through A.
// Selected via V6CISD::DAD from PerformDAGCombine when the add result
// is used as a memory address (load/store pointer).
let Defs = [FLAGS] in
def V6C_DAD : V6CPseudo<(outs GR16Ptr:$dst), (ins GR16Ptr:$lhs, GR16All:$rp),
    "# DAD $dst, $lhs, $rp",
    [(set i16:$dst, (V6Cdad i16:$lhs, i16:$rp))]> {
  let Constraints = "$dst = $lhs";
}

let Defs = [A, FLAGS] in {
  def V6C_ADD16 : V6CPseudo<(outs GR16:$dst), (ins GR16:$lhs, GR16:$rhs),
      "# ADD16 $dst, $lhs, $rhs",
      [(set i16:$dst, (add i16:$lhs, i16:$rhs))]>;
  def V6C_SUB16 : V6CPseudo<(outs GR16:$dst), (ins GR16:$lhs, GR16:$rhs),
      "# SUB16 $dst, $lhs, $rhs",
      [(set i16:$dst, (sub i16:$lhs, i16:$rhs))]>;
  def V6C_AND16 : V6CPseudo<(outs GR16:$dst), (ins GR16:$lhs, GR16:$rhs),
      "# AND16 $dst, $lhs, $rhs",
      [(set i16:$dst, (and i16:$lhs, i16:$rhs))]>;
  def V6C_OR16 : V6CPseudo<(outs GR16:$dst), (ins GR16:$lhs, GR16:$rhs),
      "# OR16 $dst, $lhs, $rhs",
      [(set i16:$dst, (or i16:$lhs, i16:$rhs))]>;
  def V6C_XOR16 : V6CPseudo<(outs GR16:$dst), (ins GR16:$lhs, GR16:$rhs),
      "# XOR16 $dst, $lhs, $rhs",
      [(set i16:$dst, (xor i16:$lhs, i16:$rhs))]>;
}

// 16-bit shift pseudos (constant shift amount only).
// Variable shifts are library calls.
let Defs = [A, FLAGS] in {
  def V6C_SHL16 : V6CPseudo<(outs GR16:$dst), (ins GR16:$src, i8imm:$amt),
      "# SHL16 $dst, $src, $amt", []>;
  def V6C_SRL16 : V6CPseudo<(outs GR16:$dst), (ins GR16:$src, i8imm:$amt),
      "# SRL16 $dst, $src, $amt",
      [(set i16:$dst, (V6Csrl16 i16:$src, (i8 timm:$amt)))]>;
  def V6C_SRA16 : V6CPseudo<(outs GR16:$dst), (ins GR16:$src, i8imm:$amt),
      "# SRA16 $dst, $src, $amt",
      [(set i16:$dst, (V6Csra16 i16:$src, (i8 timm:$amt)))]>;
}

// 16-bit load from pointer (register pair).
// Expands to: copy addr to HL, MOV lo, M; INX HL; MOV hi, M
let mayLoad = 1, Defs = [HL] in
def V6C_LOAD16_P : V6CPseudo<(outs GR16:$dst), (ins GR16:$addr),
    "# LOAD16P $dst, ($addr)",
    [(set i16:$dst, (load i16:$addr))]>;

// 16-bit store to pointer (register pair).
// Expands to: copy addr to HL, MOV M, lo; INX HL; MOV M, hi
// A is clobbered when Val=HL (needs STAX path).
let mayStore = 1, Defs = [HL, A] in
def V6C_STORE16_P : V6CPseudo<(outs), (ins GR16:$val, GR16:$addr),
    "# STORE16P $val, ($addr)",
    [(store i16:$val, i16:$addr)]>;

// 16-bit load from global address.
// For known addresses, try LHLD (result always in HL).
// Pseudo: LXI HL, addr; MOV lo, M; INX HL; MOV hi, M
let mayLoad = 1, Defs = [HL] in
def V6C_LOAD16_G : V6CPseudo<(outs GR16:$dst), (ins imm16:$addr),
    "# LOAD16G $dst, $addr", []>;

// 16-bit store to global address.
// Pseudo: LXI HL, addr; MOV M, lo; INX HL; MOV M, hi
let mayStore = 1, Defs = [HL] in
def V6C_STORE16_G : V6CPseudo<(outs), (ins GR16:$val, imm16:$addr),
    "# STORE16G $val, $addr", []>;

// Load i16 from global via LHLD (result always in HL).
def : Pat<(i16 (load (V6Cwrapper tglobaladdr:$addr))),
          (LHLD tglobaladdr:$addr)>;

// Store i16 to global via SHLD (source must be in HL).
def : Pat<(store i16:$val, (V6Cwrapper tglobaladdr:$addr)),
          (SHLD i16:$val, tglobaladdr:$addr)>;

// BUILD_PAIR: combine two i8 values into i16 register pair.
// Post-RA: expands to pair of MOV instructions.
// Selected via C++ code in V6CISelDAGToDAG for BUILD_PAIR nodes.
let isPseudo = 1 in
def V6C_BUILD_PAIR : V6CPseudo<(outs GR16:$dst), (ins GR8:$lo, GR8:$hi),
    "# BUILD_PAIR $dst, $lo, $hi", []>;

// SEXT: sign-extend i8 to i16 via RLC+SBB (hi = 0x00 or 0xFF).
let isPseudo = 1, Defs = [A, FLAGS] in
def V6C_SEXT : V6CPseudo<(outs GR16:$dst), (ins GR8:$src),
    "# SEXT $dst, $src",
    [(set i16:$dst, (V6Csext i8:$src))]>;

// EXTRACT_SUBREG patterns for truncate i16 → i8.
def : Pat<(i8 (trunc i16:$src)),
          (EXTRACT_SUBREG i16:$src, sub_lo)>;

// 16-bit conditional select. Expanded to diamond CFG.
let usesCustomInserter = 1, Uses = [FLAGS] in
def V6C_SELECT_CC16 : V6CPseudo<(outs GR16:$dst),
    (ins GR16:$trueval, GR16:$falseval, i8imm:$cc),
    "# V6C_SELECT_CC16 $dst, $trueval, $falseval, $cc",
    [(set i16:$dst, (V6Cselectcc i16:$trueval, i16:$falseval, (i8 imm:$cc)))]>;

// Fused 16-bit compare + conditional branch.
// Expanded post-RA into 8-bit compare sequence + Jcc.
// $lhs is clobbered by the EQ/NE expansion (XOR-based), so it is declared
// as a tied output (early clobber) to let the register allocator know.
let isBranch = 1, isTerminator = 1, Defs = [A, FLAGS] in
def V6C_BR_CC16 : V6CPseudo<(outs GR16:$lhs_wb),
    (ins GR16:$lhs, GR16:$rhs, i8imm:$cc, brtarget:$dst),
    "# BR_CC16 $lhs, $rhs, $cc, $dst",
    []> {
  let Constraints = "$lhs = $lhs_wb";
}

// 16-bit comparison (for use in i16 BR_CC lowering).
// Produces FLAGS via subtraction (SUB lo, SBB hi).
let Defs = [A, FLAGS] in
def V6C_CMP16 : V6CPseudo<(outs), (ins GR16:$lhs, GR16:$rhs),
    "# CMP16 $lhs, $rhs",
    [(V6Ccmp i16:$lhs, i16:$rhs)]>;

//===----------------------------------------------------------------------===//
// Intrinsic patterns — map LLVM intrinsics to machine instructions
//===----------------------------------------------------------------------===//

// __builtin_v6c_in(port) → IN port (result in A)
def : Pat<(int_v6c_in (i8 imm:$port)), (IN imm:$port)>;

// __builtin_v6c_out(port, val) → OUT port (val must be in A)
def : Pat<(int_v6c_out (i8 imm:$port), Acc:$val), (OUT Acc:$val, imm:$port)>;

// __builtin_v6c_di() → DI
def : Pat<(int_v6c_di), (DI)>;

// __builtin_v6c_ei() → EI
def : Pat<(int_v6c_ei), (EI)>;

// __builtin_v6c_hlt() → HLT
def : Pat<(int_v6c_hlt), (HLT)>;

// __builtin_v6c_nop() → NOP
def : Pat<(int_v6c_nop), (NOP)>;
