target datalayout = "e-p:16:8-i1:8-i8:8-i16:8-i32:8-i64:8-n8:16-S8"
target triple = "i8080-unknown-v6c"

define void @init_point(ptr %p) {
  store i8 10, ptr %p
  %f1 = getelementptr i8, ptr %p, i16 1
  store i8 20, ptr %f1
  %f2 = getelementptr i8, ptr %p, i16 2
  store i16 300, ptr %f2
  ret void
}

define i16 @sum_point(ptr %p) {
  %v0 = load i8, ptr %p
  %v0x = zext i8 %v0 to i16
  %f1 = getelementptr i8, ptr %p, i16 1
  %v1 = load i8, ptr %f1
  %v1x = zext i8 %v1 to i16
  %f2 = getelementptr i8, ptr %p, i16 2
  %v2 = load i16, ptr %f2
  %s1 = add i16 %v0x, %v1x
  %s2 = add i16 %s1, %v2
  ret i16 %s2
}
