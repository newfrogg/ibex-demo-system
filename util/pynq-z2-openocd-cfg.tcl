# https://docs.xilinx.com/r/en-US/ug470_7Series_Config/Configuration-Bitstream-Lengths
# https://github.com/arduino/OpenOCD/blob/master/tcl/target/zynq_7000.cfg
# https://github.com/arduino/OpenOCD/blob/master/tcl/interface/ftdi/digilent-hs1.cfg
# https://github.com/pulp-platform/riscv-dbg/blob/master/doc/debug-system.md

# Copyright lowRISC contributors.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0
# openocd 0.12+latest
adapter driver ftdi
transport select jtag
ftdi tdo_sample_edge falling
ftdi device_desc "TUL"
ftdi vid_pid 0x0403 0x6010
ftdi channel 0
ftdi layout_init 0x0088 0x008b
reset_config none

# Configure JTAG chain and the target processor
set _CHIPNAME riscv

# Configure JTAG expected ID
set _EXPECTED_ID 0x23727093

jtag newtap $_CHIPNAME cpu -irlen 6 -expected-id $_EXPECTED_ID -ignore-version

# just to avoid a warning about the auto-detected arm core
# see: https://github.com/pulp-platform/riscv-dbg/blob/master/doc/debug-system.md
jtag newtap arm_unused tap -irlen 4 -expected-id 0x4ba00477

set _TARGETNAME $_CHIPNAME.cpu
target create $_TARGETNAME riscv -chain-position $_TARGETNAME

riscv set_ir idcode 0x09
riscv set_ir dtmcs 0x22
riscv set_ir dmi 0x23

adapter speed 10000

# riscv set_prefer_sba on
gdb_report_data_abort enable
gdb_report_register_access_error enable
gdb_breakpoint_override hard

reset_config none

init
halt