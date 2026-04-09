target datalayout = "e-p:16:8-i1:8-i8:8-i16:8-i32:8-i64:8-n8:16-S8"
target triple = "i8080-unknown-v6c"
define void @bubble_sort(ptr %arr, i16 %n) {
entry:
  %n1 = sub i16 %n, 1
  br label %outer
outer:
  %i = phi i16 [ 0, %entry ], [ %i.next, %outer.next ]
  %i.next = add i16 %i, 1
  %done.outer = icmp eq i16 %i, %n1
  br i1 %done.outer, label %done, label %inner.start
inner.start:
  %limit = sub i16 %n1, %i
  br label %inner
inner:
  %j = phi i16 [ 0, %inner.start ], [ %j.next, %inner.next ]
  %j.next = add i16 %j, 1
  %p = getelementptr i8, ptr %arr, i16 %j
  %q = getelementptr i8, ptr %arr, i16 %j.next
  %a = load i8, ptr %p
  %b = load i8, ptr %q
  %cmp = icmp ugt i8 %a, %b
  br i1 %cmp, label %swap, label %noswap
swap:
  store i8 %b, ptr %p
  store i8 %a, ptr %q
  br label %inner.next
noswap:
  br label %inner.next
inner.next:
  %done.inner = icmp eq i16 %j.next, %limit
  br i1 %done.inner, label %outer.next, label %inner
outer.next:
  br label %outer
done:
  ret void
}
