target datalayout = "e-p:16:8-i1:8-i8:8-i16:8-i32:8-i64:8-n8:16-S8"
target triple = "i8080-unknown-v6c"

define i16 @fib(i16 %n) {
entry:
  %cmp0 = icmp ult i16 %n, 2
  br i1 %cmp0, label %base, label %loop

base:
  ret i16 %n

loop:
  %i = phi i16 [ 2, %entry ], [ %i.next, %loop ]
  %prev = phi i16 [ 0, %entry ], [ %curr, %loop ]
  %curr = phi i16 [ 1, %entry ], [ %next, %loop ]
  %next = add i16 %prev, %curr
  %i.next = add i16 %i, 1
  %done = icmp eq i16 %i.next, %n
  br i1 %done, label %exit, label %loop

exit:
  ret i16 %next
}
