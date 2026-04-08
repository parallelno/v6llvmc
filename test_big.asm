    MVI A, 42h
    LDA 1234h
    STA 5678h
    LDAX B
    STAX D
    LXI B, 1234h
    LXI SP, 0DEF0h
    PUSH B
    PUSH PSW
    POP B
    POP PSW
    ADI 42h
    JMP 1234h
    CALL 1234h
    RET
    RST 0
    RST 7
    IN 42h
    OUT 42h
