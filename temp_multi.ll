target datalayout = "e-p:16:8-i1:8-i8:8-i16:8-i32:8-i64:8-n8:16-S8"
target triple = "i8080-unknown-v6c"

define i16 @compute(i16 %x) {
  %a = mul i16 %x, %x
  %b = add i16 %a, %x
  ret i16 %b
}

define i16 @app_main() {
  %r1 = call i16 @compute(i16 5)
  %r2 = call i16 @compute(i16 3)
  %total = add i16 %r1, %r2
  ret i16 %total
}
