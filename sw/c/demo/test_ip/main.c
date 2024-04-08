#include <math.h>
#include <stdio.h>
#include <time.h>
#include <math.h>
#include "and2.h"
#include "demo_system.h"
#include "example.h"
#include "stdint.h"
#include "stdbool.h"

void test_and2_irq(void) __attribute__((interrupt));

volatile uint32_t result;

void test_and2_irq(void) {
  uint32_t a = 9561753;
  write_input(a);
  asm volatile("wfi");
}

int main() {
  install_exception_handler(AND_IRQ_NUM, &test_and2_irq);
  result = get_result();
  uint16_t a = 956, b = 1753;
  // uint32_t c = a & b;
  puthex(a & b);
  puts("_____");
  puthex(result);
  puts("\n");
  return 0;
}

