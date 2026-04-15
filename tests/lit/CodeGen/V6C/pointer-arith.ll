; RUN: llc -march=v6c < %s | FileCheck %s

; GEP with i16 index on i16 element: base + idx * 2
; CHECK-LABEL: gep_i16:
; CHECK:       ADD
; CHECK:       ADC
; CHECK:       DAD DE
; CHECK:       MOV A, M
; CHECK:       INX HL
; CHECK-NEXT:  MOV H, M
; CHECK-NEXT:  MOV L, A
define i16 @gep_i16(ptr %base, i16 %idx) {
  %ptr = getelementptr i16, ptr %base, i16 %idx
  %v = load i16, ptr %ptr
  ret i16 %v
}
