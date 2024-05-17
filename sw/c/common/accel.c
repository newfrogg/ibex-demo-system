#include "accel.h"
#include "demo_system.h"
#include "dev_access.h"

void write_r_valid(uint32_t value) {
    puts("[WRITE] r_valid: ");
    puthex(value);
    puts("\n");
    DEV_WRITE(R_VALID, value);
}

void write_is_last_data_gate(uint32_t value) {
    puts("[WRITE] is_last_data_gate: ");
    puthex(value);
    puts("\n");
    DEV_WRITE(IS_LAST_DATA_GATE, value);
}

void write_data_in(uint32_t value, uint32_t addr) {
    puts("[WRITE] data_in: ");
    puthex(value);
    puts(" to address: ");
    puthex(addr);
    puts("\n");
    DEV_WRITE(addr, value);
}

uint32_t read_r_data() {
    return DEV_READ(R_DATA);
}

uint32_t read_w_valid() {
    return DEV_READ(W_VALID);
}

uint32_t read_t_valid() {
    return DEV_READ(T_VALID);
}

uint32_t read_out_data(uint32_t addr) {
    return DEV_READ(addr);
}