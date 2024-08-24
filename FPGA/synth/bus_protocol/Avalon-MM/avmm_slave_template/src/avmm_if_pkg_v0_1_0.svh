`ifndef AVMM_IF_PKG__V0_1_0_SVH_INCLUDED
`define AVMM_IF_PKG__V0_1_0_SVH_INCLUDED

// Verible directive
// verilog_lint: waive-start parameter-name-style
// verilog_lint: waive-start line-length

`include "avmm_if_v0_1_0.svh"

package avmm_if_pkg_v0_1_0;
    //! Avalon MM response type
    typedef enum logic [1:0] {
        AVMM_RESP_OKAY = 2'b00,
        AVMM_RESP_RESERVED = 2'b01,
        AVMM_RESP_SLVERR = 2'b10,
        AVMM_RESP_DECODEERROR = 2'b11
    } avmm_resp_t;

    // for simulation only
    `ifdef ALLOW_NON_SYNTHESIZABLE
        class avmm_access #(
            parameter int AVMM_ADDR_BIT_WIDTH = 32,
            parameter int AVMM_DATA_BIT_WIDTH = 32
        );
            typedef virtual interface avmm_if_v0_1_0 #(
                .AVMM_ADDR_BIT_WIDTH(AVMM_ADDR_BIT_WIDTH),
                .AVMM_DATA_BIT_WIDTH(AVMM_DATA_BIT_WIDTH)
            ) vif_t;

            // Resets the host output signals.
            static task automatic reset_hst_out_sigs(
                vif_t vif, // virtual interface to DUT
                input bit wait_for_next_clk_pos_edge = 1'b0 //! 1/0: wait/do not wait for the next positive edge of the clock before driving signals
            );
                if (wait_for_next_clk_pos_edge) begin
                    @(posedge vif.i_clk);
                end
                vif.read <= 1'b0;
                vif.write <= 1'b0;
                vif.address <= '0;
                vif.writedata <= '0;
                vif.byteenable <= '0;
            endtask

            // Performs read transaction.
            // If there is a preceding read transaction in progress, a fatal error is issued.
            static task automatic read(
                vif_t vif, // virtual interface to DUT
                input bit [AVMM_ADDR_BIT_WIDTH-1:0] addr, // address
                output bit [AVMM_DATA_BIT_WIDTH-1:0] data, // storage for read data
                output avmm_resp_t resp // storage for response
            );
                string msg;

                if (vif.read || vif.readdatavalid || vif.write || vif.writeresponsevalid) begin
                    if (vif.read || vif.readdatavalid) begin
                        msg = "There is a preceding read transaction in progress. Waiting for it to complete.";
                    end else if (vif.write || vif.writeresponsevalid) begin
                        msg = "There is a preceding write transaction in progress. Waiting for it to complete.";
                    end
                    `ifdef uvm_fatal
                        `uvm_fatal("INFO", msg, UVM_MEDIUM);
                    `else
                        $fatal(2, msg);
                    `endif
                end

                // Issues a read request.
                @(posedge vif.i_clk);
                vif.read <= 1'b1;
                vif.write <= 1'b0;
                vif.address <= addr;

                // Waits until the read data is valid.
                forever begin
                    @(posedge vif.i_clk);
                    if (!vif.waitrequest && vif.readdatavalid) begin
                        break;
                    end
                end

                data = vif.readdata;
                resp = vif.response;
            endtask

            // Performs write transaction.
            // If there is a preceding write transaction in progress, a fatal error is issued.
            static task automatic write(
                vif_t vif, // virtual interface to DUT
                input bit [AVMM_ADDR_BIT_WIDTH-1:0] addr, // address
                input bit [AVMM_DATA_BIT_WIDTH-1:0] data, // data to write
                input bit [AVMM_DATA_BIT_WIDTH/8-1:0] byte_en, // byte enable
                output avmm_resp_t resp // storage for response
            );
                string msg;

                if (vif.read || vif.readdatavalid || vif.write || vif.writeresponsevalid) begin
                    if (vif.read || vif.readdatavalid) begin
                        msg = "There is a preceding read transaction in progress. Waiting for it to complete.";
                    end else if (vif.write || vif.writeresponsevalid) begin
                        msg = "There is a preceding write transaction in progress. Waiting for it to complete.";
                    end
                    `ifdef uvm_fatal
                        `uvm_fatal("INFO", msg, UVM_MEDIUM);
                    `else
                        $fatal(2, msg);
                    `endif
                end

                // Issues a write request.
                @(posedge vif.i_clk);
                vif.read <= 1'b0;
                vif.write <= 1'b1;
                vif.address <= addr;

                // Waits until the write response is valid.
                forever begin
                    @(posedge vif.i_clk);
                    if (!vif.waitrequest && vif.writeresponsevalid) begin
                        break;
                    end
                end

                resp = vif.response;
            endtask
        endclass
    `endif
endpackage

`endif // AVMM_IF_PKG__V0_1_0_SVH_INCLUDED
