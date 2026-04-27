//===-- V6CRegisterInfo.td - V6C Register Definitions ------*- tablegen -*-===//
//
// Part of the V6C backend for LLVM.
//
// Register definitions for the Intel 8080 / KR580VM80A CPU.
// See design.md §3 for register architecture details.
//
//===----------------------------------------------------------------------===//

//===----------------------------------------------------------------------===//
// Sub-register indices
//===----------------------------------------------------------------------===//

let Namespace = "V6C" in {
  def sub_lo : SubRegIndex<8>;       // Low byte (offset 0)
  def sub_hi : SubRegIndex<8, 8>;    // High byte (offset 8)
}

//===----------------------------------------------------------------------===//
// Register alternate-name indices
//===----------------------------------------------------------------------===//

// Pair8080 — i8080-canonical pair-form mnemonics used by every instruction
// that takes a register-pair operand (PUSH, POP, INX, DCX, DAD, LXI, LDAX,
// STAX). Maps BC->"B", DE->"D", HL->"H", SP->"SP", PSW->"PSW".
def Pair8080 : RegAltNameIndex;

//===----------------------------------------------------------------------===//
// 8-bit Registers
//===----------------------------------------------------------------------===//

// HWEncoding matches the 8080 3-bit register encoding:
//   B=000, C=001, D=010, E=011, H=100, L=101, (M=110), A=111
class V6CReg<bits<16> Enc, string n> : Register<n> {
  let HWEncoding = Enc;
  let Namespace = "V6C";
}

def B : V6CReg<0, "B">;
def C : V6CReg<1, "C">;
def D : V6CReg<2, "D">;
def E : V6CReg<3, "E">;
def H : V6CReg<4, "H">;
def L : V6CReg<5, "L">;
def A : V6CReg<7, "A">;

// FLAGS register (not directly addressable by 8080 instructions).
def FLAGS : V6CReg<6, "FLAGS">;

//===----------------------------------------------------------------------===//
// 16-bit Register Pairs
//===----------------------------------------------------------------------===//

// HWEncoding for pairs uses the 2-bit register-pair field:
//   BC=00, DE=01, HL=10, SP=11
class V6CRegPair<bits<16> Enc, string n, list<Register> subregs>
    : RegisterWithSubRegs<n, subregs> {
  let HWEncoding = Enc;
  let Namespace = "V6C";
  let SubRegIndices = [sub_lo, sub_hi];
  let CoveredBySubRegs = 1;
}

// Note: subregs = [lo, hi] following LLVM convention
let RegAltNameIndices = [Pair8080] in {
  def BC  : V6CRegPair<0, "BC",  [C, B]>     { let AltNames = ["B"];   }
  def DE  : V6CRegPair<1, "DE",  [E, D]>     { let AltNames = ["D"];   }
  def HL  : V6CRegPair<2, "HL",  [L, H]>     { let AltNames = ["H"];   }
  def PSW : V6CRegPair<3, "PSW", [FLAGS, A]> { let AltNames = ["PSW"]; }
}

// SP is a standalone 16-bit register (not a sub-register pair).
let RegAltNameIndices = [Pair8080] in
def SP : V6CReg<3, "SP"> { let AltNames = ["SP"]; }

// PC is implicit, not modeled as allocatable.

//===----------------------------------------------------------------------===//
// Register Classes (per design §3.2)
//===----------------------------------------------------------------------===//

// GR8 — General 8-bit registers.
// Allocation order: A, L, H, E, D, C, B (per design §3.4).
def GR8 : RegisterClass<"V6C", [i8], 8, (add A, L, H, E, D, C, B)>;

// GR8NoA — All 8-bit GPRs except the accumulator.
def GR8NoA : RegisterClass<"V6C", [i8], 8, (add L, H, E, D, C, B)>;

// Acc — Singleton accumulator class.
def Acc : RegisterClass<"V6C", [i8], 8, (add A)>;

// GR16 — General 16-bit register pairs (BC, DE, HL).
def GR16 : RegisterClass<"V6C", [i16], 8, (add HL, DE, BC)>;

// GR16Ptr — Memory pointer (HL only, for M operand).
def GR16Ptr : RegisterClass<"V6C", [i16], 8, (add HL)>;

// GR16Idx — Index pairs for LDAX/STAX (BC, DE only).
def GR16Idx : RegisterClass<"V6C", [i16], 8, (add BC, DE)>;

// GR16SP — Stack pointer only.
def GR16SP : RegisterClass<"V6C", [i16], 8, (add SP)>;

// GR16All — All 16-bit operands including SP (for PUSH/POP, LXI, INX, DCX, DAD).
def GR16All : RegisterClass<"V6C", [i16], 8, (add HL, DE, BC, SP)>;

// FlagReg — Implicit def/use on ALU/compare instructions.
def FlagReg : RegisterClass<"V6C", [i8], 8, (add FLAGS)> {
  let CopyCost = -1;
  let isAllocatable = 0;
}
