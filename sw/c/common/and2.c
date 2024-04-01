#include "and2.h"

#include "demo_system.h"
#include "demo_system_regs.h"
#include "dev_access.h"

void write_input(uint32_t values) {
  enable_interrupts(AND_IRQ);
  set_global_interrupt_enable(1);
  DEV_WRITE(AND_INPUT_REG, values);
}

uint32_t get_result() { 
  return DEV_READ(AND_OUTPUT_REG); 
}