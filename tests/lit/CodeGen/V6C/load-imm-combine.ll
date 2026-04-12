; RUN: llc -march=v6c < %s | FileCheck %s

; Test V6CLoadImmCombine: MVI instructions should be replaced when the
; value is already available in another register (→ MOV) or the register
; holds imm±1 (→ INR/DCR).

target datalayout = "e-p:16:8-i1:8-i8:8-i16:8-i32:8-i64:8-n8:16-S8"
target triple = "i8080-unknown-v6c"

@g_out8 = external global i8
@g_out16 = external global i16

; --- Test 1: Sequential values — MVI A, 10 then MVI A, 11 → INR A ---
; CHECK-LABEL: test_sequential_inc:
; CHECK:       MVI A, 0xa
; CHECK:       STA g_out8
; CHECK-NEXT:  INR A
; CHECK-NEXT:  STA g_out8
define void @test_sequential_inc() {
  store volatile i8 10, ptr @g_out8
  store volatile i8 11, ptr @g_out8
  ret void
}

; --- Test 2: Sequential values — MVI A, 10 then MVI A, 9 → DCR A ---
; CHECK-LABEL: test_sequential_dec:
; CHECK:       MVI A, 0xa
; CHECK:       STA g_out8
; CHECK-NEXT:  DCR A
; CHECK-NEXT:  STA g_out8
define void @test_sequential_dec() {
  store volatile i8 10, ptr @g_out8
  store volatile i8 9, ptr @g_out8
  ret void
}

; --- Test 3: Disable flag — with -v6c-disable-load-imm-combine, MVI kept ---
; (tested separately in load-imm-combine-disabled.ll)

; --- Test 4: Zero propagation via MOV after MVI 0 ---
; When one register holds 0, another MVI r, 0 should become MOV r, r'.
; CHECK-LABEL: test_zero_reuse:
; CHECK:       MVI {{[A-L]}}, 0
; CHECK-NOT:   MVI {{[A-L]}}, 0
define void @test_zero_reuse(i8 %a, i8 %b) {
  %wa = zext i8 %a to i16
  %wb = zext i8 %b to i16
  %sum = add i16 %wa, %wb
  store volatile i16 %sum, ptr @g_out16
  ret void
}

; --- Test 5: LXI value tracking — after LXI HL, 0x0500, H=5 and L=0 ---
; If we then need MVI r, 0, should use MOV r, L (L is known 0).
; CHECK-LABEL: test_lxi_tracking:
; CHECK:       LXI HL, 0x500
; CHECK:       SHLD
; CHECK-NEXT:  MOV A, L
; CHECK-NEXT:  STA g_out8
define void @test_lxi_tracking() {
  store volatile i16 1280, ptr @g_out16  ; 0x0500
  store volatile i8 0, ptr @g_out8
  ret void
}
