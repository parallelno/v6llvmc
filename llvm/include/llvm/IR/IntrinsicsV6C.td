//===- IntrinsicsV6C.td - Defines V6C intrinsics -----------*- tablegen -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file defines all the V6C (Intel 8080) target-specific intrinsics.
//
//===----------------------------------------------------------------------===//

let TargetPrefix = "v6c" in {

// I/O port access
def int_v6c_in  : Intrinsic<[llvm_i8_ty], [llvm_i8_ty],
    [IntrInaccessibleMemOnly]>,
    ClangBuiltin<"__builtin_v6c_in">;

def int_v6c_out : Intrinsic<[], [llvm_i8_ty, llvm_i8_ty],
    [IntrInaccessibleMemOnly]>,
    ClangBuiltin<"__builtin_v6c_out">;

// Interrupt control
def int_v6c_di  : Intrinsic<[], [], [IntrNoDuplicate, IntrHasSideEffects]>,
    ClangBuiltin<"__builtin_v6c_di">;

def int_v6c_ei  : Intrinsic<[], [], [IntrNoDuplicate, IntrHasSideEffects]>,
    ClangBuiltin<"__builtin_v6c_ei">;

// Processor control
def int_v6c_hlt : Intrinsic<[], [], [IntrNoDuplicate, IntrHasSideEffects]>,
    ClangBuiltin<"__builtin_v6c_hlt">;

def int_v6c_nop : Intrinsic<[], [], [IntrHasSideEffects]>,
    ClangBuiltin<"__builtin_v6c_nop">;

} // TargetPrefix = "v6c"
