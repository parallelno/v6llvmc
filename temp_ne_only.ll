target datalayout = "e-p:16:8-i1:8-i8:8-i16:8-i32:8-i64:8-n8:16-S8"
target triple = "i8080-unknown-v6c"

define i8 @cmp_ne_i16(i16 %a, i16 %b) {
  %c = icmp ne i16 %a, %b
  br i1 %c, label %then, label %else
then:
  ret i8 1
else:
  ret i8 0
}
