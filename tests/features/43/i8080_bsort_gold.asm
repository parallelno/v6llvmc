main:
	di
	lxi h, 0
	sphl

	lxi hl, arr
	shld __a_1_bsort_for
	mvi a, 16
	call bsort_for
	call print_arr
	hlt

print_arr:
	lxi h, arr
	mvi c, 16
@loop:
	mov a, m
	out 0xED
	inx h
	dcr c
	jnz @loop
	ret


bsort_for:
	sta __a_2_bsort_for
	xra a
	sta bsort_for_i
l_0:
	lhld __a_2_bsort_for
	mvi h, 0
	dcx h
	xchg
	lhld bsort_for_i
	mvi h, 0
	call __o_sub_16
	rnc
	xra a
	sta bsort_for_j
; 12         while (j < n - 1 - i) {
l_3:
	lhld __a_2_bsort_for
	mvi h, 0
	dcx h
	lda bsort_for_i
	mov e, a
	mvi d, 0
	call __o_sub_16
	xchg
	lhld bsort_for_j
	mvi h, 0
	call __o_sub_16
	jnc, l_4
; 13             uint8_t a = arr[j];
	lhld __a_1_bsort_for
	xchg
	lhld bsort_for_j
	mvi h, 0
	dad d
	mov a, m
	sta bsort_for_a
; 14             uint8_t b = arr[j + 1];
	lhld __a_1_bsort_for
	xchg
	lhld bsort_for_j
	mvi h, 0
	inx h
	dad d
	mov a, m
	sta bsort_for_b
; 15             if (a > b) {
	lxi hl, bsort_for_a
	cmp m
	jnc l_5
; 16                 arr[j]     = b;
	lhld __a_1_bsort_for
	xchg
	lhld bsort_for_j
	mvi h, 0
	dad d
	mov m, a
; 17                 arr[j + 1] = a;
	lhld __a_1_bsort_for
	xchg
	lhld bsort_for_j
	mvi h, 0
	inx h
	dad d
	lda bsort_for_a
	mov m, a
l_5:
; 18             }
; 19             j++;
	lda bsort_for_j
	inr a
	sta bsort_for_j
	jmp l_3
l_4:
	lda bsort_for_i
	inr a
	sta bsort_for_i
	jmp l_0

__o_sub_16:
        mvi  a, l
        sub  e
        mov  l, a
        mov  a, h
        sbc  d
        mov  h, a
	ret

arr:
	.storage 16
__static_stack:
	.storage 11
__end:

__s___init = __static_stack + 11
__s_main = __static_stack + 7
__a_1_main = __s_main + 0
__a_2_main = __s_main + 2
__s_bsort_for = __static_stack + 0
__a_1_bsort_for = __s_bsort_for + 4
__a_2_bsort_for = __s_bsort_for + 6
bsort_for_i = __s_bsort_for + 0
bsort_for_j = __s_bsort_for + 1
bsort_for_a = __s_bsort_for + 2
bsort_for_b = __s_bsort_for + 3
__s___o_sub_16 = __static_stack + 0
