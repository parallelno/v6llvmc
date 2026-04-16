// O43: SHLD/LHLD to PUSH/POP — feature test (c8080 version)
// Two-array summation loop that triggers HL spills in static stack mode.

volatile int arr1[200];
volatile int arr2[200];

int sumarray() {
    int sum = 0;
    int i;
    for (i = 0; i < 200; ++i)
        sum += arr1[i] + arr2[i];
    return sum;
}

int main(int argc, char **argv) {
    return sumarray();
}
