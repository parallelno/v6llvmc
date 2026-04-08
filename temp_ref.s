; Reference test: same as llc output
test_branch:
    CMP E
    JNZ else_block
    JMP then_block
then_block:
    MVI A, 1
    RET
else_block:
    MVI A, 0
    RET
