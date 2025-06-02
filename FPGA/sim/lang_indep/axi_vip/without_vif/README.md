# Using AXI VIP without dedicated Vivado project

This example shows how to use the AXI VIP without a dedicated Vivado project.
In this example, VIP's major parameters are configured as the following:

- INTERFACE MODE: PASS THROUGH
- PROTOCOL: AXI4LITE

The following procedure is known to work on Vivado 2023.2.

## 1. Step to acquire the necessary files

1. Define the desired VIP
   1. Create a temporary Vivado project and add an AXI VIP to the project where the VIP is configured as desired.
   At this time, IP's RTL files are not generated yet.
2. Generate IP's RTL files
   1. Create an example design by executing "Open IP Example Design" from context menu of the VIP which is added in the previous step.
   The instance name is arbitrary, but here we choose `axi_vip_passthrough` for explanation.
   This step generates IP's RTL files.
   2. Pick up the following files from the example design's directory `path-to-vivado_proj/axi_vip_passthrough_ex/axi_vip_passthrough_ex.gen/sources_1`.
      - `ip/axi_vip_passthrough/sim/axi_vip_passthrough_pkg.sv`
      - `ip/axi_vip_passthrough/sim/axi_vip_passthrough.sv`
      - `bd/ex_sim/ipshared/fd36/hdl/axi_vip_v1_1_vl_rfs.sv`

## 2. Tips to elaborate the design

1. The following directory should be added to include list of `xvlog` command:
   - `$(VIVADO_DIR)/data/xilinx_vip/include`

   Where the `VIVADO_DIR` is the directory where Vivado is installed (e.g. `/tools/Xilinx/Vivado/2023.2`).
2. The following files should be added to the list of files to be compiled by `xelab` command:
   - `$(VIVADO_DIR)/data/xilinx_vip/hdl/xil_common_vip_pkg.sv`
   - `$(VIVADO_DIR)/data/xilinx_vip/hdl/axi_vip_pkg.sv`
   - `$(VIVADO_DIR)/data/xilinx_vip/hdl/axi_vip_if.sv`
   - `$(VIVADO_DIR)/data/xilinx_vip/hdl/axi_vip_axi4pc.sv`

Above tips are considered in the [Makefile](./sim/Makefile) of this example.
