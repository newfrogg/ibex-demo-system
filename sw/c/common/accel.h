#ifndef ACCEL_H__
#define ACCEL_H__

#include <stdint.h>

/*
BEGINNING OF INPUT INTERFACES
*/
// r_valid
#define R_VALID 0x96
// is_last_data_gate
#define IS_LAST_DATA_GATE 0x100
// data_in
#define KERNEL_WEIGHT_F_X3 0x4 // 3 * 8bit (1eight)
#define KERNEL_WEIGHT_I_X3 0x8
#define KERNEL_WEIGHT_O_X3 0x12
#define KERNEL_WEIGHT_C_TEMP_X3 0x16

#define X_t_DATA_3X 0x20 // 3 * 8bit (1input)

#define BIAS_DATA_F_1 0x32
#define BIAS_DATA_I_1 0x36
#define BIAS_DATA_O_1 0x40
#define BIAS_DATA_C_TEMP_1 0x44

#define RECURRENT_KERNEL_WEIGHT_F_X3 0x48
#define RECURRENT_KERNEL_WEIGHT_I_X3 0x52
#define RECURRENT_KERNEL_WEIGHT_O_X3 0x56
#define RECURRENT_KERNEL_WEIGHT_C_TEMP_X3 0x60

#define H_t_DATA_X4_1 0x64
#define H_t_DATA_X4_2 0x68
#define H_t_DATA_X4_3 0x72
#define H_t_DATA_X4_4 0x76
/*
END OF INPUT INTERFACES
*/
//////////////////////////////////////////////////
/*
BEGINNING OF OUTPUT INTERFACES
*/
// r_data
#define R_DATA 0x104
// w_valid
#define W_VALID 0x108
// t_valid
#define T_VALID 0x112
// out_data
#define H_t_OUT_X4_1 0x80
#define H_t_OUT_X4_2 0x84
#define H_t_OUT_X4_3 0x88
#define H_t_OUT_X4_4 0x92
/*
END OF OUTPUT INTERFACES
*/

// Support methods
void write_r_valid(uint32_t value);

void write_is_last_data_gate(uint32_t value);

void write_data_in(uint32_t value, uint32_t addr);

uint32_t read_r_data();

uint32_t read_w_valid();

uint32_t read_t_valid();

uint32_t read_out_data(uint32_t addr);

#endif
