# https://docs.xilinx.com/r/en-US/ug470_7Series_Config/Configuration-Bitstream-Lengths
# https://github.com/arduino/OpenOCD/blob/master/tcl/target/zynq_7000.cfg
# https://github.com/arduino/OpenOCD/blob/master/tcl/interface/ftdi/digilent-hs1.cfg
# https://github.com/pulp-platform/riscv-dbg/blob/master/doc/debug-system.md

adapter driver ftdi
transport select jtag

ftdi_device_desc "Digilent Adept USB Device"
ftdi_vid_pid 0x0403 0x6010
ftdi_channel 0
ftdi_layout_init 0x0088 0x008b
reset_config none

# Configure JTAG chain and the target processor
set _CHIPNAME riscv

# Configure JTAG expected ID
# arty-z7-20
set _EXPECTED_ID 0x03727093 



jtag newtap $_CHIPNAME cpu -irlen 6 -expected-id $_EXPECTED_ID -ignore-version
set _TARGETNAME $_CHIPNAME.cpu
target create $_TARGETNAME riscv -chain-position $_TARGETNAME

riscv set_ir idcode 0x09
riscv set_ir dtmcs 0x22
riscv set_ir dmi 0x23

adapter speed 10000

riscv set_prefer_sba on
gdb_report_data_abort enable
gdb_report_register_access_error enable
gdb_breakpoint_override hard

reset_config none

init
halt



