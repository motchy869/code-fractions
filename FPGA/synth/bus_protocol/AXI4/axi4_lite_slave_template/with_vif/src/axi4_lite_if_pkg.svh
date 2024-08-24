// Verible directive
// verilog_lint: waive-start parameter-name-style
// verilog_lint: waive-start line-length

`ifndef AXI4_LITE_IF_PKG_SVH_INCLUDED
`define AXI4_LITE_IF_PKG_SVH_INCLUDED

`include "axi4_lite_if.svh"

package axi4_lite_if_pkg;
    typedef enum logic [1:0] {
        AXI4_RESP_OKAY = 2'b00,
        AXI4_RESP_EXOKAY = 2'b01,
        AXI4_RESP_SLVERR = 2'b10,
        AXI4_RESP_DECERR = 2'b11
    } axi4_resp_t;

    // for simulation only
    `ifdef ALLOW_NON_SYNTHESIZABLE
        class axi4_lite_access#(
            parameter int AXI4_LITE_ADDR_BIT_WIDTH = 32,
            parameter int AXI4_LITE_DATA_BIT_WIDTH = 32
        );
            typedef virtual interface axi4_lite_if #(
                .ADDR_BIT_WIDTH(AXI4_LITE_ADDR_BIT_WIDTH),
                .DATA_BIT_WIDTH(AXI4_LITE_DATA_BIT_WIDTH)
            ) vif_t;

            // (1)
            // `ifdef XILINX_SIMULATOR // Vivado 2023.2 crashes with SIGSEGV when clocking block is used.
            //     `define WAIT_CLK_POSEDGE @(posedge vif.i_clk)
            // `else
            //     `define WAIT_CLK_POSEDGE @vif.mst_cb
            // `endif
            // (2) Clocking block is buggy in Xcelium, so we decided to simply use `@(posedge vif.i_clk)`
            `define WAIT_CLK_POSEDGE @(posedge vif.i_clk)

            //! Reset the master output signals.
            static task automatic reset_mst_out_sigs(
                vif_t vif, //! virtual interface to DUT
                input bit wait_for_next_clk_pos_edge = 1'b0 //! 1'b1/1'b0: wait/do not wait for the next positive edge of the clock before driving signals
            );
                if (wait_for_next_clk_pos_edge) begin
                    `WAIT_CLK_POSEDGE;
                end
                vif.awaddr <= '0;
                vif.awprot <= '0;
                vif.awvalid <= 1'b0;
                vif.wdata <= '0;
                vif.wstrb <= '0;
                vif.wvalid <= 1'b0;
                vif.bready <= 1'b0;
                vif.araddr <= '0;
                vif.arprot <= '0;
                vif.arvalid <= 1'b0;
                vif.rready <= 1'b0;
            endtask

            //! Reset the slave output signals.
            static task automatic reset_slv_out_sigs(
                vif_t vif, //! virtual interface to DUT
                input bit wait_for_next_clk_pos_edge = 1'b0 //! 1'b1/1'b0: wait/do not wait for the next positive edge of the clock before driving signals
            );
                if (wait_for_next_clk_pos_edge) begin
                    `WAIT_CLK_POSEDGE;
                end
                vif.awready <= 1'b0;
                vif.wready <= 1'b0;
                vif.bresp <= '0;
                vif.bvalid <= 1'b0;
                vif.arready <= 1'b0;
                vif.rdata <= '0;
                vif.rresp <= '0;
                vif.rvalid <= 1'b0;
            endtask

            //! Perform AXI4-Lite read transaction.
            //! This task is based on the following blog post.
            //! [Testing Verilog AXI4-Lite Peripherals](https://klickverbot.at/blog/2016/01/testing-verilog-axi4-lite-peripherals/)
            static task automatic axi4_lite_read(
                vif_t vif, //! virtual interface to DUT
                input bit [AXI4_LITE_ADDR_BIT_WIDTH-1:0] addr, //! address
                output bit [AXI4_LITE_DATA_BIT_WIDTH-1:0] data, //! storage for read data
                output axi4_resp_t resp //! storage for response
            );
                if (vif.arvalid) begin
                    const string msg = "There is a read transaction in progress. Waiting for it to complete.";
                    `ifdef uvm_info
                        `uvm_info("INFO", msg, UVM_MEDIUM);
                    `else
                        $info(msg);
                    `endif
                    forever begin
                        `WAIT_CLK_POSEDGE;
                        if (!vif.arvalid) begin
                            break;
                        end
                    end
                end

                `WAIT_CLK_POSEDGE begin
                    vif.araddr <= addr;
                    vif.arvalid <= 1'b1;
                    vif.rready <= 1'b1;
                end

                // Note that RVALID may come AFTER the ARREADY's falling edge.
                forever begin
                    `WAIT_CLK_POSEDGE;
                    if (vif.arready) begin
                        vif.arvalid <= 1'b0; // Should be de-asserted here, otherwise possible protocol violation (AXI4_ERRM_ARVALID_STABLE: Once ARVALID is asserted, it must remain asserted until ARREADY is high. Spec: section A3.2.1.)
                        if (!vif.rvalid) begin
                            forever begin
                                `WAIT_CLK_POSEDGE;
                                if (vif.rvalid) begin
                                    break;
                                end
                            end
                        end
                        data = vif.rdata;
                        resp = axi4_resp_t'(vif.rresp);
                        vif.rready <= 1'b0;
                        break;
                    end
                end
            endtask

            //! Perform AXI4-Lite write transaction.
            //! This task is based on the following blog post.
            //! [Testing Verilog AXI4-Lite Peripherals](https://klickverbot.at/blog/2016/01/testing-verilog-axi4-lite-peripherals/)
            static task automatic axi4_lite_write(
                vif_t vif, //! virtual interface to DUT
                input bit [AXI4_LITE_ADDR_BIT_WIDTH-1:0] addr, //! address
                input bit [AXI4_LITE_DATA_BIT_WIDTH-1:0] data, //! data
                input bit [(AXI4_LITE_DATA_BIT_WIDTH/8)-1:0] wstrb = '1, //! write strobe
                output axi4_resp_t resp //! storage for response
            );
                if (vif.awvalid || vif.wvalid) begin
                    const string msg = "There is a write transaction in progress. Waiting for it to complete.";
                    `ifdef uvm_info
                        `uvm_info("INFO", msg, UVM_MEDIUM);
                    `else
                        $info(msg);
                    `endif
                    forever begin
                        `WAIT_CLK_POSEDGE;
                        if (!vif.awvalid && !vif.wvalid) begin
                            break;
                        end
                    end
                end

                `WAIT_CLK_POSEDGE begin
                    vif.awaddr <= addr;
                    vif.awvalid <= 1'b1;
                    vif.wdata <= data;
                    vif.wstrb <= wstrb;
                    vif.wvalid <= 1'b1;
                    vif.bready <= 1'b1;
                end

                forever begin
                    `WAIT_CLK_POSEDGE;
                    if (vif.awready && vif.wready) begin
                        vif.awvalid <= 1'b0;
                        vif.wvalid <= 1'b0;
                        break;
                    end
                end

                // Note that BRESP can comes after WREADY.
                if (!(vif.bready && vif.bvalid)) begin
                    forever begin
                        `WAIT_CLK_POSEDGE;
                        if (vif.bready && vif.bvalid) begin
                            break;
                        end
                    end
                end

                resp = axi4_resp_t'(vif.bresp);
            endtask

            `undef WAIT_CLK_POSEDGE
        endclass
    `endif
endpackage

`endif
