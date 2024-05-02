# AXI4-Lite slave template

A compact template of AXI4-Lite slave.

## 1. Prerequisites

This example is tested under the following conditions:

- GNU bash 5.1.16
- GNU make 4.3
- Vivado 2023.2

## 2. How to run

```bash
make -f sim/Makefile elab # elaboration
make -f sim/Makefile dump  # Run simulation and dump waveforms
make -f sim/Makefile wave # Launch Vivado to view waveforms
```

Details are described in [`sim/Makefile`](sim/Makefile).
