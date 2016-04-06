#include <stdio.h>
#include <stdlib.h>

void test(int a, int b, int c){
    printf("In test");
}

int main() {
  test(1, 2, 3);
  test(6, 7, 8);

  return 0;
}

