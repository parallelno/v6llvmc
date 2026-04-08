; TEST: fibonacci
; DESC: Compute fibonacci(10) = 55 using a loop - integration test
; EXPECT_HALT: yes
; EXPECT_OUTPUT: 55

    .org 0
    LXI SP, 0xFFFF

    ; Compute fib(10) = 55
    ; B = iterations remaining
    ; C = fib(n-2) (previous-previous)
    ; D = fib(n-1) (previous)
    ; After B iterations: D = fib(B+1) when starting with C=fib(0), D=fib(1)
    ; For fib(10): need 9 iterations (advances from fib(1) to fib(10))

    MVI B, 9            ; 9 iterations
    MVI C, 0            ; fib(0) = 0
    MVI D, 1            ; fib(1) = 1

fib_loop:
    MOV A, B
    CPI 0
    JZ fib_done         ; if count == 0, done

    MOV A, C            ; A = fib(n-2)
    ADD D               ; A = fib(n-2) + fib(n-1) = fib(n)
    MOV C, D            ; C = old fib(n-1)
    MOV D, A            ; D = new fib(n)

    DCR B               ; count--
    JMP fib_loop

fib_done:
    MOV A, D            ; result = fib(10) = 55
    OUT 0xED            ; expect 55

    HLT
