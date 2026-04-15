// O42 Liveness-Aware Pseudo Expansion — feature test (c8080 version)

int arr1[100];
int arr2[100];

// Two-array summation
int sumarray() {
    int sum;
    int i;
    sum = 0;
    for (i = 0; i < 100; ++i)
        sum += arr1[i] + arr2[i];
    return sum;
}

// Single-array sum
int data[50];
int singlesum() {
    int total;
    int i;
    total = 0;
    for (i = 0; i < 50; ++i)
        total += data[i];
    return total;
}

int main(int argc, char **argv) {
    return sumarray() + singlesum();
}
