# PeakRDL trial

An demonstration of generating CSR by PeakRDL.

An AXI4-Lite slave `my_mod` has CSR and single-port RAM.
The RDL source file is located in `src/rdl`.

## 1. Prerequisites

This example is tested under the following conditions:

- PeakRDL 1.1.0
- GNU bash 5.1.16
- GNU make 4.3
- Python 3.10.13
- Vivado 2023.2

## 2. Generate CSR

```bash
# Generate CSR document (interactive HTML document).
# The output is stored in `build-out/doc/addr_map`.
# On Windows, `launcher-windows-xxx.bat` can be used to launch the browser.
# On Linux, `build-tools/csr/view_doc.sh` should be used.
build-tools/csr/gen_doc.sh

# Generate CSR RTL.
# The output is stored in `src/rtl/csr`.
build-tools/csr/gen_rtl_code.sh

# Generate C header for embedded software.
# The output is stored in `src/c_cpp/csr`.
build-tools/csr/gen_c_header.sh
```

## 3. Simulation

### 3.1. test bench without UVM

Simulation can be run with the following commands:

```bash
make -f build-tools/sim/without_uvm/Makefile elab # elaboration
make -f build-tools/sim/without_uvm/Makefile dump  # Run simulation and dump waveforms
make -f build-tools/sim/without_uvm/Makefile wave # Launch Vivado to view waveforms
```

Details are described in [`build-tools/sim/without_uvm/Makefile`](build-tools/sim/without_uvm/Makefile).

### 3.2. test bench with UVM

This is very similar to the test bench without UVM.
The only difference is the Makefile used.
Use `build-tools/sim/with_uvm/Makefile` instead of `build-tools/sim/without_uvm/Makefile`.

#### 3.2.1. Limitation

- Accessing `uvm_mem` instance causes Vivado Simulator to crash. In this test bench, test for `uvm_mem` instance is skipped.
