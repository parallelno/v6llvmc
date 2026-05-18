target datalayout = "e-p:16:8-i1:8-i8:8-i16:8-i32:8-i64:8-n8:16-S8"
target triple = "i8080-unknown-v6c"

declare i8 @helper(i8)

define i8 @main() section ".text._start" {
  %r = call i8 @helper(i8 7)
  ret i8 %r
}

