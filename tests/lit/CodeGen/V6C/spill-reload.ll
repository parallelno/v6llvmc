; RUN: llc -march=v6c < %s | FileCheck %s

; Test that a function with local variables generates stack access patterns
; (spill/reload through LXI+DAD SP and either MOV M,_ or STAX BC/DE).
; Either store form is valid — the concrete choice depends on which pair
; the register allocator picks for the V6C_LEA_FI result.
; CHECK-LABEL: stack_access:
; CHECK:       LXI HL,
; CHECK:       DAD SP
; CHECK:       {{MOV[[:space:]]+M,|STAX[[:space:]]+(BC|DE)}}
; CHECK:       RET
define i8 @stack_access(i8 %a, i8 %b) {
  %p = alloca i8
  store i8 %a, ptr %p
  %x = add i8 %a, %b
  %v = load i8, ptr %p
  %r = sub i8 %x, %v
  ret i8 %r
}
