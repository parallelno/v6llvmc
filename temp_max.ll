target datalayout = "e-p:16:8-i1:8-i8:8-i16:8-i32:8-i64:8-n8:16-S8"
target triple = "i8080-unknown-v6c"

define i8 @find_max(ptr %arr, i16 %n) {
entry:
  %first = load i8, ptr %arr
  br label %loop

loop:
  %i = phi i16 [ 1, %entry ], [ %i.next, %loop ]
  %max = phi i8 [ %first, %entry ], [ %newmax, %loop ]
  %p = getelementptr i8, ptr %arr, i16 %i
  %val = load i8, ptr %p
  %gt = icmp ugt i8 %val, %max
  %newmax = select i1 %gt, i8 %val, i8 %max
  %i.next = add i16 %i, 1
  %done = icmp eq i16 %i.next, %n
  br i1 %done, label %exit, label %loop

exit:
  ret i8 %newmax
}
