##
## Xdc template from 
## https://github.com/Digilent/digilent-xdc/blob/master/Arty-Z7-20-Master.xdc
## 
## port ibex-demo-system/data/pins_artya7.xdc to artyz7
##
## ------------------------------------------------------------------------------------------------------
## This file is a general .xdc for the ARTY Z7-20 Rev.B
## To use it in a project:
## - uncomment the lines corresponding to used pins
## - rename the used ports (in each line, after get_ports) according to the top level signal names in the project

## Clock Signal
set_property -dict { PACKAGE_PIN H16    IOSTANDARD LVCMOS33 } [get_ports { clk }]; #IO_L13P_T2_MRCC_35 Sch=SYSCLK
create_clock -add -name sys_clk_pin -period 8.00 -waveform {0 4} [get_ports { clk }];#set

## Switches
set_property -dict { PACKAGE_PIN M20    IOSTANDARD LVCMOS33 } [get_ports { sw[0] }]; #IO_L7N_T1_AD2N_35 Sch=SW0
set_property -dict { PACKAGE_PIN M19    IOSTANDARD LVCMOS33 } [get_ports { sw[1] }]; #IO_L7P_T1_AD2P_35 Sch=SW1

## RGB LEDs
set_property -dict { PACKAGE_PIN L15    IOSTANDARD LVCMOS33 } [get_ports { rgb_led[0] }]; #IO_L22N_T3_AD7P_35 Sch=LED4_B
set_property -dict { PACKAGE_PIN G17    IOSTANDARD LVCMOS33 } [get_ports { rgb_led[1] }]; #IO_L16P_T2_35 Sch=LED4_G
set_property -dict { PACKAGE_PIN N15    IOSTANDARD LVCMOS33 } [get_ports { rgb_led[2] }]; #IO_L21P_T3_DQS_AD14P_35 Sch=LED4_R
set_property -dict { PACKAGE_PIN G14    IOSTANDARD LVCMOS33 } [get_ports { rgb_led[3] }]; #IO_0_35 Sch=LED5_B
set_property -dict { PACKAGE_PIN M15    IOSTANDARD LVCMOS33 } [get_ports { rgb_led[4] }]; #IO_L23N_T3_35 Sch=LED5_R
set_property -dict { PACKAGE_PIN L14    IOSTANDARD LVCMOS33 } [get_ports { rgb_led[5] }]; #IO_L22P_T3_AD7P_35 Sch=LED5_G

## LEDs
set_property -dict { PACKAGE_PIN R14    IOSTANDARD LVCMOS33 } [get_ports { led[0] }]; #IO_L6N_T0_VREF_34 Sch=LED0
set_property -dict { PACKAGE_PIN P14    IOSTANDARD LVCMOS33 } [get_ports { led[1] }]; #IO_L6P_T0_34 Sch=LED1
set_property -dict { PACKAGE_PIN N16    IOSTANDARD LVCMOS33 } [get_ports { led[2] }]; #IO_L21N_T3_DQS_AD14N_35 Sch=LED2
set_property -dict { PACKAGE_PIN M14    IOSTANDARD LVCMOS33 } [get_ports { led[3] }]; #IO_L23P_T3_35 Sch=LED3

## Buttons
set_property -dict { PACKAGE_PIN D19    IOSTANDARD LVCMOS33 } [get_ports { btn[0] }]; #IO_L4P_T0_35 Sch=BTN0
set_property -dict { PACKAGE_PIN D20    IOSTANDARD LVCMOS33 } [get_ports { btn[1] }]; #IO_L4N_T0_35 Sch=BTN1
set_property -dict { PACKAGE_PIN L20    IOSTANDARD LVCMOS33 } [get_ports { btn[2] }]; #IO_L9N_T1_DQS_AD3N_35 Sch=BTN2
set_property -dict { PACKAGE_PIN L19    IOSTANDARD LVCMOS33 } [get_ports { btn[3] }]; #IO_L9P_T1_DQS_AD3P_35 Sch=BTN3

## USB-UART Interface
# set_property -dict { PACKAGE_PIN C8   IOSTANDARD LVCMOS33 } [get_ports { uart_tx }]; #PS_MIO15_500 Sch=UART_RXD_OUT
# set_property -dict { PACKAGE_PIN C5   IOSTANDARD LVCMOS33 } [get_ports { uart_rx }]; #PS_MIO14_500 Sch=UART_TDX_IN

set_property -dict { PACKAGE_PIN F17   IOSTANDARD LVCMOS33 } [get_ports { uart_tx }]; #IO_L6N_T0_VREF_35
set_property -dict { PACKAGE_PIN T9    IOSTANDARD LVCMOS33 } [get_ports { uart_rx }]; #IO_L12P_T1_MRCC_13


## ChipKit Inner Analog Header - as Digital I/O
## NOTE: The following constraints should be used when using the inner analog header ports as digital I/O.
#set_property -dict { PACKAGE_PIN F19   IOSTANDARD LVCMOS33 } [get_ports { ck_a6  }]; #IO_L15P_T2_DQS_AD12P_35 Sch=AD12_P
#set_property -dict { PACKAGE_PIN F20   IOSTANDARD LVCMOS33 } [get_ports { ck_a7  }]; #IO_L15N_T2_DQS_AD12N_35 Sch=AD12_N
#set_property -dict { PACKAGE_PIN C20   IOSTANDARD LVCMOS33 } [get_ports { ck_a8  }]; #IO_L1P_T0_AD0P_35       Sch=AD0_P
#set_property -dict { PACKAGE_PIN B20   IOSTANDARD LVCMOS33 } [get_ports { ck_a9  }]; #IO_L1N_T0_AD0N_35       Sch=AD0_N
#set_property -dict { PACKAGE_PIN B19   IOSTANDARD LVCMOS33 } [get_ports { ck_a10 }]; #IO_L2P_T0_AD8P_35       Sch=AD8_P
#set_property -dict { PACKAGE_PIN A20   IOSTANDARD LVCMOS33 } [get_ports { ck_a11 }]; #IO_L2N_T0_AD8N_35       Sch=AD8_N

## Alternative port name with use pins_artya7 as reference
set_property -dict { PACKAGE_PIN F20   IOSTANDARD LVCMOS33 } [get_ports { disp_ctrl[0]  }]; #IO_L15N_T2_DQS_AD12N_35 Sch=AD12_N
set_property -dict { PACKAGE_PIN C20   IOSTANDARD LVCMOS33 } [get_ports { disp_ctrl[1]  }]; #IO_L1P_T0_AD0P_35       Sch=AD0_P
set_property -dict { PACKAGE_PIN B20   IOSTANDARD LVCMOS33 } [get_ports { disp_ctrl[2]  }]; #IO_L1N_T0_AD0N_35       Sch=AD0_N
set_property -dict { PACKAGE_PIN F19   IOSTANDARD LVCMOS33 } [get_ports { spi_tx  }]; #IO_L15P_T2_DQS_AD12P_35 Sch=AD12_P
set_property -dict { PACKAGE_PIN B19   IOSTANDARD LVCMOS33 } [get_ports { spi_sck }]; #IO_L2P_T0_AD8P_35       Sch=AD8_P
set_property -dict { PACKAGE_PIN A20   IOSTANDARD LVCMOS33 } [get_ports { disp_ctrl[3] }]; #IO_L2N_T0_AD8N_35       Sch=AD8_N



## Misc. ChipKit Ports
#set_property -dict { PACKAGE_PIN Y13   IOSTANDARD LVCMOS33 } [get_ports { ck_ioa }]; #IO_L20N_T3_13 Sch=CK_IOA
# set_property -dict { PACKAGE_PIN D9    IOSTANDARD LVCMOS33 } [get_ports { clk_rst }]; #PS_MIO12_500 Sch=CK_RST
set_property -dict { PACKAGE_PIN U9    IOSTANDARD LVCMOS33 } [get_ports { clk_rst }]; #IO_L17P_T2_13
