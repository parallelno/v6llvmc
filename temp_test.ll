@global_i16 = global i16 0
@global_arr = global [4 x i16] zeroinitializer

define i16 @load_global_i16() {
  %v = load i16, ptr @global_i16
  ret i16 %v
}

define void @store_global_i16(i16 %val) {
  store i16 %val, ptr @global_i16
  ret void
}

define i16 @load_ptr_i16(ptr %p) {
  %v = load i16, ptr %p
  ret i16 %v
}

define void @store_ptr_i16(i16 %val, ptr %p) {
  store i16 %val, ptr %p
  ret void
}

define i16 @shl_i16(i16 %a) {
  %r = shl i16 %a, 1
  ret i16 %r
}

define i16 @shl3_i16(i16 %a) {
  %r = shl i16 %a, 3
  ret i16 %r
}
