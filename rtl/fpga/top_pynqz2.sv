// Copyright lowRISC contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

// This is the top level SystemVerilog file that connects the IO on the board to the Ibex Demo System.
module top_pynqz2 (
  // These inputs are defined in data/pins_pynqz2.xdc
  input               clk,
  input               clk_rst,
  input  [ 1:0]       sw,
  input  [ 3:0]       btn,
  output [ 3:0]       led,
  output [ 5:0]       rgb_led,
  output [ 3:0]       disp_ctrl,
  input               uart_rx,
  output              uart_tx,
  input               spi_rx,
  output              spi_tx,
  output              spi_sck
);
  parameter SRAMInitFile = "";

  logic clk_sys, rst_sys_n;

  // Instantiating the Ibex Demo System.
  ibex_demo_system #(
    .GpiWidth(6),
    .GpoWidth(8),
    .PwmWidth(6),
    .SRAMInitFile(SRAMInitFile)
  ) u_ibex_demo_system (
    //input
    .clk_sys_i(clk_sys),
    .rst_sys_ni(rst_sys_n),
    .gp_i({sw, btn}),
    .uart_rx_i(uart_rx),

    //output
    .gp_o({led, disp_ctrl}),
    .pwm_o(rgb_led),
    .uart_tx_o(uart_tx),

    .spi_rx_i(spi_rx),
    .spi_tx_o(spi_tx),
    .spi_sck_o(spi_sck)
  );

  // Generating the system clock and reset for the FPGA.
  clkgen_pynqz2 clkgen(
    .IO_CLK(clk),
    .IO_RST_N(clk_rst),
    .clk_sys,
    .rst_sys_n
  );

endmodule
