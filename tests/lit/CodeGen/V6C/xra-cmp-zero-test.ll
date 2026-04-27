; RUN: llc -march=v6c < %s | FileCheck %s
; RUN: llc -march=v6c -v6c-disable-peephole < %s | FileCheck %s --check-prefix=DISABLED

target datalayout = "e-p:16:8-i1:8-i8:8-i16:8-i32:8-i64:8-n8:16-S8"
target triple = "i8080-unknown-v6c"

declare dso_local i8 @bar(i8 noundef) local_unnamed_addr

; O38: MOV A,r; ORA A; JZ → XRA A; CMP r; JZ
; The XRA A sets A=0, and LoadImmCombine eliminates downstream MVI A,0.
;
; CHECK-LABEL: test_xra_cmp_jz:
; CHECK:       XRA A
; CHECK-NEXT:  CMP B
; CHECK-NOT:   ORA A
; CHECK-NOT:   MVI A, 0
;
; DISABLED-LABEL: test_xra_cmp_jz:
; DISABLED:       MOV A, B
; DISABLED-NEXT:  ORA A
define dso_local i8 @test_xra_cmp_jz(i8 noundef %x, i8 noundef %y) local_unnamed_addr {
  %cmpx = icmp eq i8 %x, 0
  br i1 %cmpx, label %test_y, label %call_bar

test_y:
  %cmpy = icmp eq i8 %y, 0
  br i1 %cmpy, label %ret_zero, label %call_bar_zero

call_bar:
  %r1 = tail call i8 @bar(i8 noundef %x)
  br label %exit

call_bar_zero:
  %r2 = tail call i8 @bar(i8 noundef 0)
  br label %exit

ret_zero:
  br label %exit

exit:
  %result = phi i8 [ %r1, %call_bar ], [ %r2, %call_bar_zero ], [ 0, %ret_zero ]
  ret i8 %result
}
