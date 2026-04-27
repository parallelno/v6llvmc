; RUN: llc -march=v6c < %s | FileCheck %s

; Test prologue/epilogue for function with 1 byte of locals.
; CHECK-LABEL: one_local:
; CHECK:       LXI H, 0xffff
; CHECK-NEXT:  DAD SP
; CHECK-NEXT:  SPHL
; CHECK:       LXI H, 1
; CHECK-NEXT:  DAD SP
; CHECK-NEXT:  SPHL
; CHECK-NEXT:  RET
define i8 @one_local(i8 %x) {
  %p = alloca i8
  store i8 %x, ptr %p
  %v = load i8, ptr %p
  ret i8 %v
}

; Test prologue/epilogue for function with 4-byte array local.
; CHECK-LABEL: array_local:
; CHECK:       LXI H, 0xfffc
; CHECK-NEXT:  DAD SP
; CHECK-NEXT:  SPHL
; CHECK:       LXI H, 4
; CHECK-NEXT:  DAD SP
; CHECK-NEXT:  SPHL
; CHECK-NEXT:  RET
define i8 @array_local(i8 %x) {
  %arr = alloca [4 x i8]
  %p = getelementptr [4 x i8], ptr %arr, i16 0, i16 0
  store i8 %x, ptr %p
  %v = load i8, ptr %p
  ret i8 %v
}
