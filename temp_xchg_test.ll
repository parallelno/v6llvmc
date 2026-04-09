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
