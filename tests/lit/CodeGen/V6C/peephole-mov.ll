; RUN: llc -march=v6c < %s | FileCheck %s

; Test V6CPeephole: redundant MOV elimination.
; Self-MOV (MOV X, X) should be removed.

; Simple function that returns its argument — should not have MOV A, A.
; CHECK-LABEL: test_self_mov:
; CHECK-NOT:   MOV A, A
; CHECK:       RET
define i8 @test_self_mov(i8 %a) {
  ret i8 %a
}

; Function with add that shouldn't produce redundant MOVs.
; CHECK-LABEL: test_no_redundant:
; CHECK:       ADD
; CHECK:       RET
define i8 @test_no_redundant(i8 %a, i8 %b) {
  %r = add i8 %a, %b
  ret i8 %r
}
