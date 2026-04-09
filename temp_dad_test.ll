target datalayout = "e-p:16:8-i1:8-i8:8-i16:8-i32:8-i64:8-n8:16-S8"
target triple = "i8080-unknown-v6c"

define i8 @load_offset(ptr %p, i16 %idx) {
  %ptr = getelementptr i8, ptr %p, i16 %idx
  %v = load i8, ptr %ptr
  ret i8 %v
}

define void @store_offset(ptr %p, i16 %idx, i8 %val) {
  %ptr = getelementptr i8, ptr %p, i16 %idx
  store i8 %val, ptr %ptr
  ret void
}
