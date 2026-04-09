; RUN: llc -march=v6c < %s | FileCheck %s

; CHECK-LABEL: add_i16:
; CHECK:       MOV A, L
; CHECK-NEXT:  ADD E
; CHECK-NEXT:  MOV L, A
; CHECK-NEXT:  MOV A, H
; CHECK-NEXT:  ADC D
; CHECK-NEXT:  MOV H, A
; CHECK-NEXT:  RET
define i16 @add_i16(i16 %a, i16 %b) {
  %r = add i16 %a, %b
  ret i16 %r
}
