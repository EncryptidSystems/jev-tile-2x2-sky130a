# jev_tile_2x2

A flat 2 by 2 array. Two row sums. Its own shuttle, not the mesh tile.

One macro, one shuttle. SkyWater SKY130A, standard cells `sky130_fd_sc_hd`. This repository is only `jev_tile_2x2`.

| Property | Value |
| --- | --- |
| Die | 818.16 um by 828.88 um |
| Worst setup slack | 1.068 ns at max_ss_100C_1v60 |
| Worst hold slack | 0.829 ns at max_ss_100C_1v60 |
| Slew, capacitance, fanout, route DRC, LVS | 0 |

| `vh/jev_tile_2x2.vh` | Verilog blackbox |
| `rtl/jev_tile_2x2.v` | RTL |
| `metrics.json` | Signoff metrics |

The closed signoff directory for this shuttle has no GDS and no LEF. Those views are not invented here.

The sibling shuttles are separate repositories. `jev_kuramoto` is [kuramoto-oscillator-sky130a](https://github.com/EncryptidSystems/kuramoto-oscillator-sky130a).

Encryptid Systems, Frederick County, Maryland.
