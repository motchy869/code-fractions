// Verible directive
// verilog_lint: waive-start line-length

//! Some techniques used in this file are based on the following source:
//! - [UVM Register Model Example](https://www.chipverify.com/uvm/uvm-register-model-example)

`ifndef MY_VERIF_PKG_SVH_INCLUDED
    $fatal("compile \"my_verif_pkg.sv\" instead of including this file");
`endif

`include "../../axi4_lite_if.svh"

class my_bus_driver extends uvm_driver#(my_bus_seq_item);
    `uvm_component_utils(my_bus_driver)

    virtual axi4_lite_if m_vif;

    function new(string name = "my_bus_driver", uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual axi4_lite_if)::get(null, "uvm_test_top", "bus_vif", m_vif)) begin
            `uvm_fatal("NO-VIF", {"virtual interface must be set for: ", "uvm_test_top", ".bus_vif"})
        end
    endfunction

    extern virtual task read_access(
        input bit [my_verif_params_pkg::AXI4_LITE_ADDR_BIT_WIDTH-1:0] addr,
        ref bit [my_verif_params_pkg::AXI4_LITE_DATA_BIT_WIDTH-1:0] data
    );

    extern virtual task write_access(
        input bit [my_verif_params_pkg::AXI4_LITE_ADDR_BIT_WIDTH-1:0] addr,
        input bit [my_verif_params_pkg::AXI4_LITE_DATA_BIT_WIDTH-1:0] data,
        input bit [my_verif_params_pkg::AXI4_LITE_DATA_BIT_WIDTH/8-1:0] wstrb
    );

    extern virtual task run_phase(uvm_phase phase);
endclass

task my_bus_driver::read_access(
    input bit [my_verif_params_pkg::AXI4_LITE_ADDR_BIT_WIDTH-1:0] addr,
    ref bit [my_verif_params_pkg::AXI4_LITE_DATA_BIT_WIDTH-1:0] data
);
    if (m_vif.arvalid) begin
        `uvm_info("INFO", "There is a read transaction in progress. Waiting for it to complete.", UVM_MEDIUM);
        wait(!m_vif.arvalid);
    end

    `ifdef XILINX_SIMULATOR // Vivado 2023.2 crushes with SIGSEGV when clocking block is used.
        `define WAIT_CLK_POSEDGE @(posedge m_vif.clk)
    `else
        `define WAIT_CLK_POSEDGE @m_vif.mst_cb
    `endif

    `WAIT_CLK_POSEDGE begin
        m_vif.araddr <= addr;
        m_vif.arvalid <= 1'b1;
        m_vif.rready <= 1'b1;
    end

    wait(m_vif.arready);

    if (m_vif.rvalid) begin
        data = m_vif.rdata;
        `WAIT_CLK_POSEDGE begin
            m_vif.arvalid <= 1'b0;
            m_vif.rready <= 1'b0;
        end
    end else begin
        `WAIT_CLK_POSEDGE begin
            m_vif.arvalid <= 1'b0; // Should be de-asserted here, otherwise possible protocol violation (AXI4_ERRM_ARVALID_STABLE: Once ARVALID is asserted, it must remain asserted until ARREADY is high. Spec: section A3.2.1.)
        end

        wait(m_vif.rvalid); // Note that RVALID may come AFTER the ARREADY's falling edge.
        data = m_vif.rdata;
        `WAIT_CLK_POSEDGE begin
            m_vif.rready <= 1'b0;
        end
    end

    `undef WAIT_CLK_POSEDGE
endtask

task my_bus_driver::write_access(
    input bit [my_verif_params_pkg::AXI4_LITE_ADDR_BIT_WIDTH-1:0] addr,
    input bit [my_verif_params_pkg::AXI4_LITE_DATA_BIT_WIDTH-1:0] data,
    input bit [my_verif_params_pkg::AXI4_LITE_DATA_BIT_WIDTH/8-1:0] wstrb
);
    if (m_vif.awvalid || m_vif.wvalid) begin
        `uvm_info("INFO", "There is a write transaction in progress. Waiting for it to complete.", UVM_MEDIUM);
        wait(!m_vif.awvalid && !m_vif.wvalid);
    end

    `ifdef XILINX_SIMULATOR // Vivado 2023.2 crushes with SIGSEGV when clocking block is used.
        `define WAIT_CLK_POSEDGE @(posedge m_vif.clk)
    `else
        `define WAIT_CLK_POSEDGE @m_vif.mst_cb
    `endif

    `WAIT_CLK_POSEDGE begin
        m_vif.awaddr <= addr;
        m_vif.awvalid <= 1'b1;
        m_vif.wdata <= data;
        m_vif.wstrb <= wstrb;
        m_vif.wvalid <= 1'b1;
        m_vif.bready <= 1'b1;
    end

    wait(m_vif.awready && m_vif.wready);

    `WAIT_CLK_POSEDGE begin
        m_vif.awvalid <= 1'b0;
        m_vif.wvalid <= 1'b0;
    end

    `undef WAIT_CLK_POSEDGE
endtask

task my_bus_driver::run_phase(uvm_phase phase);
    my_bus_seq_item pkt;

    phase.raise_objection(this);

    m_vif.awaddr <= '0;
    m_vif.awprot <= '0;
    m_vif.awvalid <= 1'b0;
    m_vif.wdata <= '0;
    m_vif.wstrb <= '0;
    m_vif.wvalid <= 1'b0;
    m_vif.bready <= 1'b0;
    m_vif.araddr <= '0;
    m_vif.arprot <= '0;
    m_vif.arvalid <= 1'b0;
    m_vif.rready <= 1'b0;

    forever begin
        seq_item_port.get_next_item(pkt);
        if (pkt.write) begin
            write_access(pkt.addr, pkt.data, pkt.wstrb);
        end else begin
            read_access(pkt.addr, pkt.data);
        end
        seq_item_port.item_done();

        if (pkt.is_last_item) begin
            phase.drop_objection(this);
        end
    end
endtask
