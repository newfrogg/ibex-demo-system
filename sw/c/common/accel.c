#include "accel.h"
#include "demo_system.h"
#include "dev_access.h"
#define ACCEL_BASE 0x80005000

void write_r_valid(uint32_t value) {
    puts(" [INPUT] r_valid: ");
    puthex(value);
    puts("\n");
    DEV_WRITE(ACCEL_BASE + R_VALID, value);
}

void write_is_last_data_gate(uint32_t value) {
    puts(" [INPUT] data_in: ");
    puthex(value);
    puts("\n");
    DEV_WRITE(ACCEL_BASE + IS_LAST_DATA_GATE, value);
}

void write_data_in(uint32_t value, uint32_t addr) {
    puts(" [INPUT] data_in: ");
    puthex(value);
    puts("\n");
    DEV_WRITE(ACCEL_BASE + addr, value);
}

uint32_t read_r_data() {
    return DEV_READ(ACCEL_BASE + R_DATA);
}

uint32_t read_w_valid() {
    return DEV_READ(ACCEL_BASE + W_VALID);
}

uint32_t read_t_valid() {
    return DEV_READ(ACCEL_BASE + T_VALID);
}

uint32_t read_out_data(uint32_t addr) {
    return DEV_READ(ACCEL_BASE + addr);
}