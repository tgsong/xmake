#include <stdio.h>

extern "C" {
    int cs_add(int a, int b);
    int cs_multiply(int a, int b);
}

int main() {
    printf("cs_add(3,4)=%d\n", cs_add(3, 4));
    printf("cs_multiply(5,6)=%d\n", cs_multiply(5, 6));
    return 0;
}
