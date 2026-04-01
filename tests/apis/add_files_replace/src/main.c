#include <stdio.h>

#ifndef REPLACED_VALUE
#define REPLACED_VALUE "original"
#endif

int main(int argc, char** argv) {
    printf("hello %s!\n", REPLACED_VALUE);
    return 0;
}
