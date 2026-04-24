declare void @sink(i8) "leaf"
define void @rmw_keep_orig(ptr %p) {
entry:
  %v = load i8, ptr %p
  %v1 = add i8 %v, 1
  store i8 %v1, ptr %p
  call void @sink(i8 %v)
  ret void
}
define void @rmw_dec_keep_orig(ptr %p) {
entry:
  %v = load i8, ptr %p
  %v1 = add i8 %v, -1
  store i8 %v1, ptr %p
  call void @sink(i8 %v)
  ret void
}
