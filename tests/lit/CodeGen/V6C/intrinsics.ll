; RUN: llc -march=v6c < %s | FileCheck %s

; CHECK-LABEL: test_di:
; CHECK:       DI
; CHECK-NEXT:  RET
define void @test_di() {
  call void @llvm.v6c.di()
  ret void
}

; CHECK-LABEL: test_ei:
; CHECK:       EI
; CHECK-NEXT:  RET
define void @test_ei() {
  call void @llvm.v6c.ei()
  ret void
}

; CHECK-LABEL: test_hlt:
; CHECK:       HLT
; CHECK-NEXT:  RET
define void @test_hlt() {
  call void @llvm.v6c.hlt()
  ret void
}

; CHECK-LABEL: test_nop:
; CHECK:       NOP
; CHECK-NEXT:  RET
define void @test_nop() {
  call void @llvm.v6c.nop()
  ret void
}

; CHECK-LABEL: test_in:
; CHECK:       IN 0x10
; CHECK-NEXT:  RET
define i8 @test_in() {
  %v = call i8 @llvm.v6c.in(i8 16)
  ret i8 %v
}

; CHECK-LABEL: test_out:
; CHECK:       OUT 0x20
; CHECK-NEXT:  RET
define void @test_out(i8 %val) {
  call void @llvm.v6c.out(i8 32, i8 %val)
  ret void
}

declare void @llvm.v6c.di()
declare void @llvm.v6c.ei()
declare void @llvm.v6c.hlt()
declare void @llvm.v6c.nop()
declare i8 @llvm.v6c.in(i8)
declare void @llvm.v6c.out(i8, i8)
