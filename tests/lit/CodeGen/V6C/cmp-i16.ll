; RUN: llc -march=v6c < %s | FileCheck %s

; Comparison expansion uses fused compare+branch pseudo.
; EQ/NE use XOR+OR to combine byte checks into a single flag.

; CHECK-LABEL: cmp_ne_i16:
; CHECK:       MOV A, H
; CHECK-NEXT:  XRA D
; CHECK-NEXT:  MOV H, A
; CHECK-NEXT:  MOV A, L
; CHECK-NEXT:  XRA E
; CHECK-NEXT:  ORA H
; CHECK-NEXT:  JZ
define i8 @cmp_ne_i16(i16 %a, i16 %b) {
  %c = icmp ne i16 %a, %b
  br i1 %c, label %then, label %else
then:
  ret i8 1
else:
  ret i8 0
}

; Unsigned less-than uses SUB/SBB + JC/JNC (LLVM may invert branch)
; CHECK-LABEL: cmp_ult_i16:
; CHECK:       SUB
; CHECK:       SBB
; CHECK:       J{{N?}}C
define i8 @cmp_ult_i16(i16 %a, i16 %b) {
  %c = icmp ult i16 %a, %b
  br i1 %c, label %then, label %else
then:
  ret i8 1
else:
  ret i8 0
}

; Signed less-than uses SUB/SBB + JM/JP (LLVM may invert branch)
; CHECK-LABEL: cmp_slt_i16:
; CHECK:       SUB
; CHECK:       SBB
; CHECK:       J{{[MP]}}
define i8 @cmp_slt_i16(i16 %a, i16 %b) {
  %c = icmp slt i16 %a, %b
  br i1 %c, label %then, label %else
then:
  ret i8 1
else:
  ret i8 0
}
