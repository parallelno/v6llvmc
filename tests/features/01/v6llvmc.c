int helper(int x);
void void_func(void);

/* Simple tail call — should become JMP */
int wrapper(int x) {
    return helper(x);
}

/* Void tail call — should become JMP */
void void_wrapper(void) {
    return void_func();
}

/* NOT a tail call — work after call */
int not_tail(int x) {
    int r = helper(x);
    return r + 1;
}

int main(int argc, char** argv) {
    wrapper(42);
    void_wrapper();
    not_tail(10);
    return 0;
}
