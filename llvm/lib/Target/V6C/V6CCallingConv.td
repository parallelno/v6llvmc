//===-- V6CCallingConv.td - V6C Calling Convention ---------*- tablegen -*-===//
//
// Part of the V6C backend for LLVM.
//
// Calling convention definitions for the V6C (Intel 8080) target.
// See design.md §6 for the full specification.
//
// Argument assignment is type-driven (not position-based): a free-list
// allocator hands out registers from
//
//   i8  free-list:  A, B, C, D, E, L, H
//   i16 free-list:  HL, DE, BC
//
// Taking an i16 pair removes its two halves from the i8 list, and taking
// an i8 half removes its enclosing i16 pair from the i16 list. Once the
// relevant free-list is exhausted, remaining args go on the stack
// (right-to-left, caller cleans).
//
// Worked examples (see V6CISelLowering.cpp `V6CArgAllocator`):
//   foo(i8, i8, i8, i16, i16)  -> A,  B,  C,  HL, DE
//   foo(i16, i16, i8, i16)     -> HL, DE, A,  BC
//   foo(i8, i16, i8, i16)      -> A,  HL, B,  DE
//   foo(i16, i16, i8, i8)      -> HL, DE, A,  B
//
// Return values:
//   i8  -> A
//   i16 -> HL
//   i32 -> DE:HL (DE=high, HL=low)
//
// All registers are caller-saved (no callee-saved registers).
//
// The free-list allocation does not map to LLVM's standard CallingConv
// TableGen, so argument lowering is done in C++ (V6CISelLowering.cpp).
// Return values use the generated RetCC_V6C below.
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
