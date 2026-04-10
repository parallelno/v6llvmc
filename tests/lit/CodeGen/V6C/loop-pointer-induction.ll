; RUN: llc -march=v6c -O2 < %s | FileCheck %s

; V6CLoopPointerInduction converts base+counter GEPs to running pointers.
; The loop should use LDAX/STAX with pointer increments instead of
; recomputing addresses from base + counter each iteration.

@src = dso_local global [100 x i8] zeroinitializer, align 1
@dst = dso_local global [100 x i8] zeroinitializer, align 1

; CHECK-LABEL: copy_loop:
; The src pointer should be loaded into BC and kept in a register.
; CHECK:       LXI BC, src
; The loop body should use indirect loads/stores, not base+counter DAD.
; CHECK:       .LBB0_1:
; CHECK:       LDAX BC
; CHECK:       STAX DE
; The exit comparison should be against src+100 (pointer end address).
; CHECK:       src+100
; CHECK:       JNZ .LBB0_1
define void @copy_loop() {
entry:
  br label %loop

loop:
  %i = phi i16 [ 0, %entry ], [ %i.next, %loop ]
  %src.ptr = getelementptr inbounds [100 x i8], ptr @src, i16 0, i16 %i
  %val = load i8, ptr %src.ptr, align 1
  %dst.ptr = getelementptr inbounds [100 x i8], ptr @dst, i16 0, i16 %i
  store i8 %val, ptr %dst.ptr, align 1
  %i.next = add nuw nsw i16 %i, 1
  %done = icmp eq i16 %i.next, 100
  br i1 %done, label %exit, label %loop

exit:
  ret void
}
