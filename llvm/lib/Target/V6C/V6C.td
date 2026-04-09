// V6C.td - Top-level TableGen description for the V6C (Vector 06c) target
//
// This is the root TableGen file for the Intel 8080-based Vector 06c backend.
// It includes all target-specific definitions: registers, instructions,
// calling conventions, and scheduling model.

include "llvm/Target/Target.td"

//===----------------------------------------------------------------------===//
// Included definitions
//===----------------------------------------------------------------------===//

include "V6CRegisterInfo.td"
include "V6CSchedule.td"
include "V6CInstrInfo.td"
include "V6CCallingConv.td"

//===----------------------------------------------------------------------===//
// V6C Target Definition
//===----------------------------------------------------------------------===//

def V6CInstrInfo : InstrInfo;

//===----------------------------------------------------------------------===//
// V6C Processor Definition
//===----------------------------------------------------------------------===//

def : ProcessorModel<"i8080", V6CModel, []>;

def V6CAsmWriter : AsmWriter {
  string AsmWriterClassName = "InstPrinter";
  int PassSubtarget = 0;
  int Variant = 0;
}

def V6C : Target {
  let InstructionSet = V6CInstrInfo;
  let AssemblyWriters = [V6CAsmWriter];
}
