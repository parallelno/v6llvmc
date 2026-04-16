// O44 Adjacent XCHG Cancellation — feature test (c8080 version)
// Same test case for c8080 reference compiler comparison.

volatile int arr1[100];
volatile int arr2[100];

// Two-array summation
int sumarray() {
    int sum = 0;
    int i;
    for (i = 0; i < 100; ++i)
        sum += arr1[i] + arr2[i];
    return sum;
}

int main(int argc, char **argv) {
    return sumarray();
}
