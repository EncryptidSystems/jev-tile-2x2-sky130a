# jev_tile_2x2

`jev_tile_2x2` is the RTL, the blackbox, and the signoff metrics for a SkyWater SKY130 (`sky130_fd_sc_hd`) block. This package contains the logical view:

| File | What it is |
|---|---|
| `vh/jev_tile_2x2.vh` | Verilog blackbox. Its signal ports match `rtl/jev_tile_2x2.v` |
| `rtl/jev_tile_2x2.v` / `rtl/jev_tile_2x2.vhd` | Generated RTL in Verilog and VHDL |
| `rtl/jev_tile_2x2.rom.txt` | Controller ROM tables for the four engines |
| `rtl/jev_tile_2x2_tb.v` / `rtl/jev_tile_2x2_tb.vhd` | Self-checking testbenches (16 golden vectors) |
| `metrics.json` | Signoff metrics. Die size and slack are recorded here |

The LEF and the GDS are not part of this package.

## Macro summary

| Property | Value |
|---|---|
| Size | 818.16 µm × 828.88 µm (origin 0, 0), from `design__die__bbox` in `metrics.json` |
| Signal pins | 178 (112 input bits, 66 output bits), counted from the blackbox |
| Power | `VPWR` and `VGND` are ports of the blackbox when `USE_POWER_PINS` is defined. Strap geometry lives in a LEF, and this package has no LEF |
| Signoff | Corner `max_ss_100C_1v60`. Worst setup slack 1.068 ns. Worst hold slack 0.829 ns. Slew, capacitance, fanout, route DRC, Magic DRC, KLayout DRC, and LVS are 0. The saved files have no `CLOCK_PERIOD` entry |

## Ports

| Port | Dir | Width | Notes |
|---|---|---|---|
| `clk` | in | 1 | Clock |
| `rst` | in | 1 | Synchronous reset, active high |
| `w_we` | in | 1 | Write enable for one weight |
| `w_addr` | in | 8 | Weight address. Addresses 0 to 15 select the 16 weight registers. The high nibble is 0 for those addresses |
| `w_data` | in | 32 | Weight word |
| `x_we` | in | 1 | Write enable for one activation beat |
| `x_k` | in | 2 | Which of the four beats this word is |
| `x0` | in | 32 | Activation word for column 0 |
| `x1` | in | 32 | Activation word for column 1 |
| `x_go` | in | 1 | Start the staged set on a clock where `x_ready` is high |
| `y_ready` | in | 1 | The host can take `y0` and `y1` |
| `x_ready` | out | 1 | The engines can take a set |
| `y0` | out | 32 | Sum of the two row 0 engines |
| `y1` | out | 32 | Sum of the two row 1 engines |
| `y_valid` | out | 1 | `y0` and `y1` hold a finished pair of sums |
| `VPWR`, `VGND` | inout | 1 | Only when `USE_POWER_PINS` is defined |

## How it works

This section was traced from the gate netlist in `rtl/jev_tile_2x2.v`. Sums are 32-bit, so they wrap at 2^32.

**Weights.** Sixteen registers, `wt0` through `wt15`. A write with `w_we` high stores `w_data` at `w_addr`. Address `(row * 2 + column) * 4 + k` is weight `k` of the engine at that row and column. Load weights while the engines are idle.

**Activations.** `x_we` with `x_k` writes one beat into the staging registers. Beat `k` stores `x0` as column 0 slot `k` and `x1` as column 1 slot `k`. `x_go`, on a clock where `x_ready` is high, copies the staged words into the active set and starts the engines. The staging registers and the active registers are separate, so the next set can be written while the engines run the current one.

**The four engines.** `e0_0` and `e0_1` are row 0. `e1_0` and `e1_1` are row 1. Each engine multiplies four pairs, one product per clock, the same way `jev_dot_pipe` does, and keeps a 32-bit sum. Both engines in a row see that row's activation words. Each engine has its own four weights.

**The two sums.**

```
y0 = e0_0 + e0_1
y1 = e1_0 + e1_1
```

`y_valid` follows the result-valid of `e0_0`. The engines run in lockstep, so the two sums finish together. `y_ready` is back-pressure: while it is low the engines hold the sums, and `x_ready` falls until they can take another set.

## RTL

The RTL comes from the WASMApollo EDA (heapvm vgpu apollo), generated from the typed fabric `jev_tile_2x2`. The Verilog and VHDL are the same design.

| Property | Value |
|---|---|
| LUT4 cells | 217 |
| Word PEs | 106 |
| Registers | 105 |
| Combinational depth | 6 levels |
| Clocking | Single `clk`. Every register latches on the rising edge from the settled levels |
| Reset | `rst` is synchronous, active high, and loads the fabric's initial state |

### Microcode ROMs

Each engine has `route_x`, `route_w`, and `mac_op`. The tables are in the header of `rtl/jev_tile_2x2.v` and in `rtl/jev_tile_2x2.rom.txt`. States 0 to 3 select `x0`/`w0` through `x3`/`w3`, and every state selects `mac` (code `1`).

## Simulation

Both testbenches are self-checking. Each vector holds `rst` for one cycle, runs 12 cycles, and then compares `x_ready`, `y0`, `y1`, and `y_valid` against the fabric's golden model (RefSim).

```sh
# Verilog (Icarus), from rtl/
iverilog -o tb jev_tile_2x2.v jev_tile_2x2_tb.v && vvp tb
# expected: PASS jev_tile_2x2: 16 vectors

# VHDL (GHDL), from rtl/
ghdl -a jev_tile_2x2.vhd jev_tile_2x2_tb.vhd && ghdl -e jev_tile_2x2_tb && ghdl -r jev_tile_2x2_tb
```

The VHDL testbench was run with GHDL and passes all 16 vectors. The Icarus command above is the Verilog run.

## Using the macro

### In RTL

```verilog
`include "jev_tile_2x2.vh"

jev_tile_2x2 u_tile (
`ifdef USE_POWER_PINS
  .VPWR(vccd1),
  .VGND(vssd1),
`endif
  .clk(clk), .rst(rst),
  .w_we(w_we), .w_addr(w_addr), .w_data(w_data),
  .x_we(x_we), .x_k(x_k), .x0(x0), .x1(x1), .x_go(x_go),
  .y_ready(y_ready),
  .x_ready(x_ready), .y0(y0), .y1(y1), .y_valid(y_valid)
);
```

The blackbox file in this package is `vh/jev_tile_2x2.vh`. Define `USE_POWER_PINS` for power-aware simulation and LVS. Leave it undefined for plain RTL simulation.

### In OpenLane / OpenROAD

Synthesize `rtl/jev_tile_2x2.v` as ordinary RTL. `EXTRA_LEFS` and `EXTRA_GDS_FILES` stay empty for this package, because the LEF and the GDS are not in it. The die size and the slack from the recorded signoff are in `metrics.json`.

## Other PDKs

`VPWR` and `VGND` are the SKY130 supply names on the blackbox. To target another public PDK, synthesize `rtl/jev_tile_2x2.v` there and use that PDK's supply names.
