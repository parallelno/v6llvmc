	ld hl, 0
	ld (__a_1_main), hl

main:
; 34 int main(int argc, char **argv) {
	ld (__a_2_main), hl
; 35     int r;
; 36     r = heavy_spill(10, 20);
	ld hl, 10
	ld (__a_1_heavy_spill), hl
	ld hl, 20
	call heavy_spill
	ld (main_r), hl
; 37     use_val(r);
	call use_val
; 38     r = nested_calls(5);
	ld hl, 5
	call nested_calls
	ld (main_r), hl
; 39     use_val(r);
	call use_val
; 40     return r;
	ld hl, (main_r)
	ret



heavy_spill:
; 15 int heavy_spill(int a, int b) {
	ld (__a_2_heavy_spill), hl

; 16     int x = a + 1;
	ld hl, (__a_1_heavy_spill)
	inc hl
	ld (heavy_spill_x), hl

; 17     int y = b + 2;
	ld hl, (__a_2_heavy_spill)
	inc hl
	inc hl
	ld (heavy_spill_y), hl

; 18     int z = a + b;
	ld hl, (__a_1_heavy_spill)
	ex hl, de
	ld hl, (__a_2_heavy_spill)
	add hl, de
	ld (heavy_spill_z), hl

; 19     use_val(x);
	ld hl, (heavy_spill_x)
	call use_val

; 20     use_val(y);
	ld hl, (heavy_spill_y)
	call use_val

; 21     use_val(z);
	ld hl, (heavy_spill_z)
	call use_val

; 22     return x + y + z;
	ld hl, (heavy_spill_x)
	ex hl, de
	ld hl, (heavy_spill_y)
	add hl, de
	ex hl, de
	ld hl, (heavy_spill_z)
	add hl, de
	ret



use_val:
; 6 void use_val(int x) {
	ld (__a_1_use_val), hl
; 7     sink_val = x;
	ld (sink_val), hl
	ret



nested_calls:
; 26 int nested_calls(int n) {
	ld (__a_1_nested_calls), hl
; 27     int a = get_val();
	call get_val
	ld (nested_calls_a), hl
; 28     int b = get_val();
	call get_val
	ld (nested_calls_b), hl
; 29     int c = a + b + n;
	ld hl, (nested_calls_a)
	ex hl, de
	ld hl, (nested_calls_b)
	add hl, de
	ex hl, de
	ld hl, (__a_1_nested_calls)
	add hl, de
	ld (nested_calls_c), hl
; 30     use_val(c);
	call use_val
; 31     return a + b;
	ld hl, (nested_calls_a)
	ex hl, de
	ld hl, (nested_calls_b)
	add hl, de
	ret



get_val:
; 10 int get_val(void) {
; 11     return sink_val;
	ld hl, (sink_val)
	ret




__bss:
sink_val:
	ds 2
__static_stack:
	ds 18
__end:
__s___init equ __static_stack + 18
__s_main equ __static_stack + 12
__a_1_main equ __s_main + 2
__a_2_main equ __s_main + 4
main_r equ __s_main + 0
__s_heavy_spill equ __static_stack + 2
__a_1_heavy_spill equ __s_heavy_spill + 6
__a_2_heavy_spill equ __s_heavy_spill + 8
__s_use_val equ __static_stack + 0
__a_1_use_val equ __s_use_val + 0
__s_nested_calls equ __static_stack + 2
__a_1_nested_calls equ __s_nested_calls + 6
heavy_spill_x equ __s_heavy_spill + 0
heavy_spill_y equ __s_heavy_spill + 2
heavy_spill_z equ __s_heavy_spill + 4
nested_calls_a equ __s_nested_calls + 0
nested_calls_b equ __s_nested_calls + 2
nested_calls_c equ __s_nested_calls + 4
__s_get_val equ __static_stack + 0
    savebin "tests\features\21\c8080.bin", __begin, __bss - __begin
