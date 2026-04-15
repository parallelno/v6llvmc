; RUN: llc -march=v6c < %s | FileCheck %s

@g16 = global i16 0

; CHECK-LABEL: load_global:
; CHECK:       LHLD g16
; CHECK-NEXT:  RET
define i16 @load_global() {
  %v = load i16, ptr @g16
  ret i16 %v
}

; CHECK-LABEL: store_global:
; CHECK:       SHLD g16
; CHECK-NEXT:  RET
define void @store_global(i16 %val) {
  store i16 %val, ptr @g16
  ret void
}

; CHECK-LABEL: load_ptr:
; CHECK:       MOV A, M
; CHECK:       INX HL
; CHECK-NEXT:  MOV H, M
; CHECK-NEXT:  MOV L, A
define i16 @load_ptr(ptr %p) {
  %v = load i16, ptr %p
  ret i16 %v
}

; CHECK-LABEL: store_ptr:
; CHECK:       PUSH DE
; CHECK-NEXT:  MOV A, L
; CHECK-NEXT:  STAX DE
; CHECK-NEXT:  INX DE
; CHECK-NEXT:  MOV A, H
; CHECK-NEXT:  STAX DE
; CHECK-NEXT:  POP DE
; CHECK-NEXT:  RET
define void @store_ptr(i16 %val, ptr %p) {
  store i16 %val, ptr %p
  ret void
}
