// Verible directives
// verilog_lint: waive-start parameter-name-style
// verilog_lint: waive-start line-length

`default_nettype none

//! A register chain, which can be used as input and output registers for a pipeline stage.
//! Modern fitting tools will utilize this module for register re-timing to achieve better timing closure.
module reg_chain_v0_1_0 #(
    parameter int unsigned CHAIN_LEN = 2, //! Chain length. When this is 0, no chain is created and this module becomes just a path-through wire(s).
    parameter type T = logic //! input data type
)(
    input wire logic i_clk, //! clock signal, only used when ```CHAIN_LEN``` > 0
    input wire logic i_sync_rst, //! synchronous reset signal, only used when ```CHAIN_LEN``` > 0
    input wire logic i_freeze, //! Freeze directive, only used when ```CHAIN_LEN``` > 0. When ```i_freeze``` is 0 at the clock rising edge, the new input is taken into the chain and output is updated. When ```i_freeze``` is 1, the chain halts.
    input wire T i_us_data, //! data from upstream
    output wire T o_ds_data //! data to downstream
);
generate
    if (CHAIN_LEN == '0) begin: gen_pass_through
        assign o_ds_data = i_us_data;
    end else begin: gen_chain
        // ---------- parameter validation ----------
        // --------------------

        // ---------- functions ----------
        // --------------------

        // ---------- signals and storage ----------
        var T [CHAIN_LEN-1:0] r_chain; //! register chain
        // --------------------

        // ---------- instances ----------
        // --------------------

        // ---------- Drives output signals. ----------
        assign o_ds_data = r_chain[CHAIN_LEN-1];
        // --------------------

        // ---------- blocks ----------
        //! Updates the register chain.
        always_ff @(posedge i_clk) begin: blk_update_chain
            if (i_sync_rst) begin
                r_chain <= '{default: '0};
            end else if (!i_freeze) begin
                for (int i=1; i<CHAIN_LEN; ++i) begin
                    r_chain[i] <= r_chain[i-1];
                end
                r_chain[0] <= i_us_data;
            end
        end
        // --------------------
    end
endgenerate
endmodule

`default_nettype wire
