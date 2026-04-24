;================================================
* rename -mv6c-annotate-pseudos into -mv6c-annotate
* update docs

;================================================
unsigned char arr_sum(unsigned char a[], unsigned int n) {
    unsigned char s = 0;
    for (unsigned int i = 0; i < n; ++i)
        s += a[i] + i;
    return s;
}
	;--- V6C_RELOAD8 ---
	PUSH	HL
	LXI	HL, __v6c_ss.arr_sum
	MOV	B, M
	POP	HL
	ADD	B
can be:
	;--- V6C_RELOAD8 ---
	PUSH	HL
	LXI	HL, __v6c_ss.arr_sum
	add	M
	POP	HL

after the spill into reload imm implementation the code should be:
	;--- V6C_RELOAD8 ---
__v6c_ss.arr_sum:
	MVI	B, 0
	ADD	B
so the peephole can do that:
	;--- V6C_RELOAD8 ---
__v6c_ss.arr_sum:
	ADI 0

;================================================
used for i8 reg spill when A live
; %bb.3:
	MVI	E, 0
	MOV	D, E
	;--- V6C_SPILL8 ---
	PUSH	HL
	LXI	HL, __v6c_ss.arr_sum+7
	MOV	M, D
	POP	HL
	;--- V6C_BUILD_PAIR ---
	MOV	B, E
	MOV	C, A

;================================================
what does it do?
	;--- V6C_SRL16 ---
	MOV	D, H
	MOV	E, L
	MOV	E, D
	MOV	D, B

;================================================
