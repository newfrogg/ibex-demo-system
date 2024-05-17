#ifndef ACCEL_H__
#define ACCEL_H__

#include <stdint.h>

/*
BEGINNING OF INPUT INTERFACES
*/
#define ACCEL_BASE_REG 0x80008000
#define R_VALID 0x58 + ACCEL_BASE_REG
#define IS_LAST_DATA_GATE 0x5c + ACCEL_BASE_REG

// // WRITE weight, bias, x_t (input data); h_t (hidden state)
#define KERNEL_WEIGHT_F_X3 0x04 + ACCEL_BASE_REG  // 3 * 8bit (1eight)
#define KERNEL_WEIGHT_I_X3 0x08 + ACCEL_BASE_REG
#define KERNEL_WEIGHT_O_X3 0x0c + ACCEL_BASE_REG
#define KERNEL_WEIGHT_C_TEMP_X3 0x10 + ACCEL_BASE_REG

#define X_t_DATA_3X 0x14 + ACCEL_BASE_REG  // 3 * 8bit (1input)

#define BIAS_DATA_F_1 0x18 + ACCEL_BASE_REG
#define BIAS_DATA_I_1 0x1C + ACCEL_BASE_REG
#define BIAS_DATA_O_1 0x20 + ACCEL_BASE_REG
#define BIAS_DATA_C_TEMP_1 0x24 + ACCEL_BASE_REG

#define RECURRENT_KERNEL_WEIGHT_F_X3 0x28 + ACCEL_BASE_REG
#define RECURRENT_KERNEL_WEIGHT_I_X3 0x2c + ACCEL_BASE_REG
#define RECURRENT_KERNEL_WEIGHT_O_X3 0x30 + ACCEL_BASE_REG
#define RECURRENT_KERNEL_WEIGHT_C_TEMP_X3 0x34 + ACCEL_BASE_REG

#define H_t_DATA_X4_2 0x3c + ACCEL_BASE_REG
#define H_t_DATA_X4_1 0x38 + ACCEL_BASE_REG
#define H_t_DATA_X4_3 0x40 + ACCEL_BASE_REG
#define H_t_DATA_X4_4 0x44 + ACCEL_BASE_REG

// // READ output (hidden state (output includeded))
#define H_t_OUT_X4_1 0x48 + ACCEL_BASE_REG
#define H_t_OUT_X4_2 0x4c + ACCEL_BASE_REG
#define H_t_OUT_X4_3 0x50 + ACCEL_BASE_REG
#define H_t_OUT_X4_4 0x54 + ACCEL_BASE_REG

//  Control signal
#define R_DATA 0x60 + ACCEL_BASE_REG
#define W_VALID 0x64 + ACCEL_BASE_REG
#define T_VALID 0x68 + ACCEL_BASE_REG

// Support methods
void write_r_valid(uint32_t value);

void write_is_last_data_gate(uint32_t value);

void write_data_in(uint32_t value, uint32_t addr);

uint32_t read_r_data();

uint32_t read_w_valid();

uint32_t read_t_valid();

uint32_t read_out_data(uint32_t addr);

#endif
