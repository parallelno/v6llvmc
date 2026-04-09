//===-- V6CCallingConv.td - V6C Calling Convention ---------*- tablegen -*-===//
//
// Part of the V6C backend for LLVM.
//
// Calling convention definitions for the V6C (Intel 8080) target.
// See design.md §6 for the full specification.
//
// The V6C calling convention is position-based:
//   Arg 1: i8 → A,   i16 → HL
//   Arg 2: i8 → E,   i16 → DE
//   Arg 3: i8 → C,   i16 → BC
//   Arg 4+: stack (right-to-left, caller cleans)
//
// Return values:
//   i8  → A
//   i16 → HL
//   i32 → DE:HL (DE=high, HL=low)
//
// All registers are caller-saved (no callee-saved registers).
//
// The position-based argument assignment doesn't map to LLVM's standard
// CallingConv TableGen, so argument lowering is done in C++
// (V6CISelLowering.cpp). Return values use the generated RetCC_V6C.
//
//===----------------------------------------------------------------------===//

//===----------------------------------------------------------------------===//
// Return value calling convention
//===----------------------------------------------------------------------===//

def RetCC_V6C : CallingConv<[
  CCIfType<[i8],  CCAssignToReg<[A]>>,
  CCIfType<[i16], CCAssignToReg<[HL]>>,
  // i32 returns use DE:HL (DE=high, HL=low) — handled via Custom in C++.
  CCIfType<[i32], CCAssignToReg<[HL, DE]>>
]>;
