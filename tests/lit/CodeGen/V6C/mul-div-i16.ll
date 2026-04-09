; RUN: llc -mtriple=i8080-unknown-v6c -verify-machineinstrs < %s | FileCheck %s

; Test that i16 multiply generates a call to __mulhi3

define i16 @test_mul_i16(i16 %a, i16 %b) {
; CHECK-LABEL: test_mul_i16:
; CHECK: CALL __mulhi3
  %r = mul i16 %a, %b
  ret i16 %r
}

; Test that i16 signed divide generates a call to __divhi3

define i16 @test_sdiv_i16(i16 %a, i16 %b) {
; CHECK-LABEL: test_sdiv_i16:
; CHECK: CALL __divhi3
  %r = sdiv i16 %a, %b
  ret i16 %r
}

; Test that i16 unsigned divide generates a call to __udivhi3

define i16 @test_udiv_i16(i16 %a, i16 %b) {
; CHECK-LABEL: test_udiv_i16:
; CHECK: CALL __udivhi3
  %r = udiv i16 %a, %b
  ret i16 %r
}

; Test that i16 signed remainder generates a call to __modhi3

define i16 @test_srem_i16(i16 %a, i16 %b) {
; CHECK-LABEL: test_srem_i16:
; CHECK: CALL __modhi3
  %r = srem i16 %a, %b
  ret i16 %r
}

; Test that i16 unsigned remainder generates a call to __umodhi3

define i16 @test_urem_i16(i16 %a, i16 %b) {
; CHECK-LABEL: test_urem_i16:
; CHECK: CALL __umodhi3
  %r = urem i16 %a, %b
  ret i16 %r
}
