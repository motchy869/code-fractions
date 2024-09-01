`ifndef AVMM_IF_OPS_PKG__V0_1_0_SVH_INCLUDED
`define AVMM_IF_OPS_PKG__V0_1_0_SVH_INCLUDED

// Verible directive
// verilog_lint: waive-start parameter-name-style
// verilog_lint: waive-start line-length

`include "avmm_if_defs_pkg_v0_1_0.svh"
`include "avmm_if_lv0_v0_1_0.svh"

//! package for operations used in Avalon Memory-Mapped Interface
package avmm_if_ops_pkg_v0_1_0;
    class avmm_if_lv0_access #(
        parameter int AVMM_ADDR_BIT_WIDTH = 32,
        parameter int AVMM_DATA_BIT_WIDTH = 32
    );
        typedef virtual interface avmm_if_lv0_v0_1_0 #(
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

        // Performs read transaction without checking preceding transactions.
        static task automatic read(
            vif_t vif, // virtual interface to DUT
            input bit [AVMM_ADDR_BIT_WIDTH-1:0] addr, // address
            output bit [AVMM_DATA_BIT_WIDTH-1:0] data, // storage for read data
            output avmm_if_defs_pkg_v0_1_0::avmm_resp_t resp, // storage for response
            input bit wait_for_next_clk_pos_edge = 1'b0 //! 1/0: wait/do not wait for the next positive edge of the clock before driving signals
        );
            if (wait_for_next_clk_pos_edge) begin
                @(posedge vif.i_clk);
            end

            // Issues a read request.
            vif.read <= 1'b1;
            vif.write <= 1'b0;
            vif.address <= addr;

            // Collects the response.
            @(posedge vif.i_clk);
            data = vif.readdata;
            vif.read <= 1'b0;
            vif.address <= '0;

            $cast(resp, vif.response);
        endtask

        // Performs write transaction without checking preceding transactions.
        static task automatic write(
            vif_t vif, // virtual interface to DUT
            input bit [AVMM_ADDR_BIT_WIDTH-1:0] addr, // address
            input bit [AVMM_DATA_BIT_WIDTH-1:0] data, // data to write
            input bit [AVMM_DATA_BIT_WIDTH/8-1:0] byte_en, // byte enable
            output avmm_if_defs_pkg_v0_1_0::avmm_resp_t resp, // storage for response
            input bit wait_for_next_clk_pos_edge = 1'b0 //! 1/0: wait/do not wait for the next positive edge of the clock before driving signals
        );
            if (wait_for_next_clk_pos_edge) begin
                @(posedge vif.i_clk);
            end

            // Issues a write request.
            vif.read <= 1'b0;
            vif.write <= 1'b1;
            vif.address <= addr;
            vif.writedata <= data;
            vif.byteenable <= byte_en;

            // Collects the response.
            @(posedge vif.i_clk);
            vif.write <= 1'b0;
            vif.address <= '0;
            vif.writedata <= '0;
            vif.byteenable <= '0;

            $cast(resp, vif.response);
        endtask
    endclass
endpackage

`endif // AVMM_IF_OPS_PKG__V0_1_0_SVH_INCLUDED
