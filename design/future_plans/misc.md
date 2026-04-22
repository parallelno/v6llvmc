1.
* rename -mv6c-annotate-pseudos into -mv6c-annotate
* update docs

2.
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