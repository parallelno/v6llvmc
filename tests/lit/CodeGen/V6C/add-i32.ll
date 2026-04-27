; RUN: llc -march=v6c < %s | FileCheck %s

; i32 constant: returns low in HL, high in DE
; CHECK-LABEL: const_i32:
; CHECK:       LXI H, 0x5678
; CHECK-NEXT:  LXI D, 0x1234
; CHECK-NEXT:  RET
define i32 @const_i32() {
  ret i32 305419896
}

; i32 add: should produce add chains (verbose but functional)
; CHECK-LABEL: add_i32:
; CHECK:       ADD
; CHECK:       ADC
; CHECK:       RET
define i32 @add_i32(i32 %a, i32 %b) {
  %r = add i32 %a, %b
  ret i32 %r
}
