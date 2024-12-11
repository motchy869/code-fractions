// Verible directive
// verilog_lint: waive-start parameter-name-style
// verilog_lint: waive-start line-length

`include "us_side_reg_layer.svh"
`include "ds_side_reg_layer.svh"
`include "frag_to_chunk.svh"

`default_nettype none

//! A fully-registered-output version of `frag_to_chunk` with some additional latency introduced.
module frag_to_chunk_fr#(
    parameter int S_MAX_IN = 16, //! max size of the input fragment
    parameter int S_OUT = 8, //! The size of the output chunk. **Recommended to be power of 2**. Other large numbers may lead to timing closure failure due to costly modulus operation.
    parameter type T = logic, //! data type of the elements
    localparam int BIT_WIDTH__S_MAX_IN = $clog2(S_MAX_IN+1) //! bit width required to represent `S_MAX_IN`
)(
    //! common ports
    input wire logic i_clk, //! input clock
    input wire logic i_sync_rst, //! input reset signal synchronous to the input clock

    //! @virtualbus us_side_if @dir in upstream side interface
    input wire logic i_frag_valid, //! input valid signal which indicates that the input fragment is valid
    input wire logic [BIT_WIDTH__S_MAX_IN-1:0] i_frag_size, //! The size of the input fragment. When this exceeds `S_MAX_IN`, `o_next_frag_ready` will be deasserted.
    //! Directive to append zero or more empty (all bits are set to 0) elements to the **internal** fragment buffer to ensure that the internal buffer has integer multiple of `S_OUT` elements.
    //! This can be used to flush the internal buffer.
    //! When `i_pad_tail` is asserted and one of the following conditions is met, appropriate empty elements are added to the fragment buffer.
    //!
    //! (a) `i_frag_valid` is **not** asserted and the number of elements in the internal fragment buffer (let it be called `r_buf_elem_cnt`) is not an integer multiple of `S_OUT`.
    //!
    //! (b) `i_frag_valid` and `o_next_frag_ready` are asserted and the sum of the `r_buf_elem_cnt` and `i_frag_size` is not an integer multiple of `S_OUT`.
    input wire logic i_pad_tail,
    input wire T i_frag[S_MAX_IN], //! input fragment
    output wire logic o_next_frag_ready, //! Output ready signal which indicates that the upstream-side can send the next fragment. Masked by reset.
    //! @end

    //! @virtualbus ds_side_if @dir out downstream side interface
    //! input ready signal which indicates that the downstream side is ready to accept a new chunk
    input wire logic i_ds_ready,
    output wire logic o_chunk_valid, //! output valid signal which indicates that the output chunk is valid
    output wire T o_chunk[S_OUT] //! output chunk
    //! @end
);

//! parameter validation
generate
    if (S_MAX_IN < 1) begin: gen_input_fragment_size_param_validation
        $error("S_MAX_IN must be greater than or equal to 1");
        nonexistent_module_to_throw_a_custom_error_message_for invalid_parameters();
    end

    if (S_OUT < 1) begin: gen_output_chunk_size_param_validation
        $error("S_OUT must be greater than or equal to 1");
        nonexistent_module_to_throw_a_custom_error_message_for invalid_parameters();
    end
endgenerate

// ---------- local parameters ----------
// --------------------

// ---------- functions ----------
// --------------------

// ---------- internal signals and storage ----------
//! struct to bundle data from upstream side
typedef struct {
    logic [BIT_WIDTH__S_MAX_IN-1:0] frag_size;
    logic pad_tail;
    T frag[S_MAX_IN];
} data_from_us_t;

//! struct to bundle data to downstream side
typedef struct {
    T chunk[S_OUT];
} data_to_ds_t;

wire data_to_ds_t w_data_to_ds;
// --------------------

// ---------- instances ----------
//! interface to bundle signals between core's upstream side and upstream side register layer
us_side_reg_layer_core_side_if#(.T(data_from_us_t)) us_side_reg_layer_core_side_if_inst();
//! interface to bundle signals between core's downstream side and downstream side register layer
ds_side_reg_layer_core_side_if#(.T(data_to_ds_t)) ds_side_reg_layer_core_side_if_inst();

us_side_reg_layer#(.T(data_from_us_t)) us_side_reg_layer_inst(
    .i_clk(i_clk),
    .i_sync_rst(i_sync_rst),

    .if_m_core_side(us_side_reg_layer_core_side_if_inst.mst_port),

    .i_valid_from_partner(i_frag_valid),
    .i_data_from_partner('{frag_size: i_frag_size, pad_tail: i_pad_tail, frag: i_frag}),
    .o_ready_to_partner(o_next_frag_ready)
);

ds_side_reg_layer#(.T(data_to_ds_t)) ds_side_reg_layer_inst(
    .i_clk(i_clk),
    .i_sync_rst(i_sync_rst),

    .if_s_core_side(ds_side_reg_layer_core_side_if_inst.slv_port),

    .i_ready_from_partner(i_ds_ready),
    .o_valid_to_partner(o_chunk_valid),
    .o_data_to_partner(w_data_to_ds)
);

frag_to_chunk#(.S_MAX_IN(S_MAX_IN), .S_OUT(S_OUT), .T(T)) core_inst (
    .i_clk(i_clk),
    .i_sync_rst(i_sync_rst),

    .i_frag_valid(us_side_reg_layer_core_side_if_inst.valid_reg_layer_to_core),
    .i_frag_size(us_side_reg_layer_core_side_if_inst.data_reg_layer_to_core.frag_size),
    .i_pad_tail(us_side_reg_layer_core_side_if_inst.data_reg_layer_to_core.pad_tail),
    .i_frag(us_side_reg_layer_core_side_if_inst.data_reg_layer_to_core.frag),
    .o_next_frag_ready(us_side_reg_layer_core_side_if_inst.ready_core_to_reg_layer),

    .i_ds_ready(ds_side_reg_layer_core_side_if_inst.ready_reg_layer_to_core),
    .o_chunk_valid(ds_side_reg_layer_core_side_if_inst.valid_core_to_reg_layer),
    .o_chunk(ds_side_reg_layer_core_side_if_inst.data_core_to_reg_layer.chunk)
);
// --------------------

// ---------- Drives output signals. ----------
assign o_chunk = w_data_to_ds.chunk;
// --------------------

// ---------- processes ----------
// --------------------

endmodule

`default_nettype wire
