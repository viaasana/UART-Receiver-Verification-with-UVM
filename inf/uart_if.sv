//***************************************************************************************************************
// Clock and reset module
//***************************************************************************************************************
`timescale 1ns/1ps

interface uart_if (input logic clk, input logic rst);

  logic uart_clk;
  logic rx_data;
  wire  o_valid;
  wire [7:0] o_data;


endinterface
