; RUN: llc -mtriple=i8080-unknown-v6c -verify-machineinstrs < %s | FileCheck %s

; Test that i8 multiply (promoted to i16) emits __mulhi3

define i8 @test_mul_i8(i8 %a, i8 %b) {
; CHECK-LABEL: test_mul_i8:
; CHECK: CALL __mulhi3
  %r = mul i8 %a, %b
  ret i8 %r
}

; Test that i8 variable shift left (promoted to i16) emits libcall

define i8 @test_shl_i8_var(i8 %val, i8 %amt) {
; CHECK-LABEL: test_shl_i8_var:
; CHECK: CALL __ashlhi3
  %r = shl i8 %val, %amt
  ret i8 %r
}

; Test that i8 variable logical right shift emits libcall

define i8 @test_lshr_i8_var(i8 %val, i8 %amt) {
; CHECK-LABEL: test_lshr_i8_var:
; CHECK: CALL __lshrhi3
  %r = lshr i8 %val, %amt
  ret i8 %r
}

; Test that i8 variable arithmetic right shift emits libcall

define i8 @test_ashr_i8_var(i8 %val, i8 %amt) {
; CHECK-LABEL: test_ashr_i8_var:
; CHECK: CALL __ashrhi3
  %r = ashr i8 %val, %amt
  ret i8 %r
}
