#ifndef AND2_H__
#define AND2_H__

#include "stdint.h"

#define BASE_AND_REG    0x80008000
#define AND_INPUT_REG   BASE_AND_REG + 0x4
#define AND_OUTPUT_REG  BASE_AND_REG + 0x8


void write_input(uint32_t values);
uint32_t get_result();
#endif

