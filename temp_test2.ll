target datalayout = "e-p:16:8-i1:8-i8:8-i16:8-i32:8-i64:8-n8:16-S8"
target triple = "i8080-unknown-v6c"

define i16 @trunc_i16_to_i8(i16 %x) {
  %t = trunc i16 %x to i8
  %r = zext i8 %t to i16
  ret i16 %r
}

define i16 @zext_i8_to_i16(i8 %x) {
  %r = zext i8 %x to i16
  ret i16 %r
}

define i16 @sext_i8_to_i16(i8 %x) {
  %r = sext i8 %x to i16
  ret i16 %r
}

define i16 @select_i16(i8 %cond, i16 %a, i16 %b) {
  %c = trunc i8 %cond to i1
  %r = select i1 %c, i16 %a, i16 %b
  ret i16 %r
}

define i16 @gep_i16(ptr %base, i16 %idx) {
  %ptr = getelementptr i16, ptr %base, i16 %idx
  %v = load i16, ptr %ptr
  ret i16 %v
}
