// Macro blackbox. Signal ports match rtl/jev_tile_2x2.v.
// VPWR and VGND are the sky130_fd_sc_hd supplies of the hardened view.
// Another public PDK synthesizes the RTL and uses that PDK's supply names.
module jev_tile_2x2(
`ifdef USE_POWER_PINS
  inout VPWR,
  inout VGND,
`endif
  input clk,
  input rst,
  input w_we,
  input[7:0] w_addr,
  input[31:0] w_data,
  input x_we,
  input[1:0] x_k,
  input[31:0] x0,
  input[31:0] x1,
  input x_go,
  input y_ready,
  output x_ready,
  output[31:0] y0,
  output[31:0] y1,
  output y_valid
);
endmodule
