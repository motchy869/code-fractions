// Verible directive
// verilog_lint: waive-start parameter-name-style
// verilog_lint: waive-start line-length

`include "axi4_lite_if_pkg.svh"
`include "axi4_lite_if.svh"

`default_nettype none

//! AXI4-Lite slave template with 4 writable registers.
//! This is obtained by modifying the AXI4-Lite slave template generated from Vivado 2023.2.
module my_axi4_lite_slv_template #(
    parameter int AXI4_LITE_ADDR_BIT_WIDTH = 32, //! bit width of AXI4-Lite address bus
    parameter int AXI4_LITE_DATA_BIT_WIDTH = 32 //! bit width of AXI4-Lite data bus
)(
    input wire logic i_clk, //! clock signal
    input wire logic i_sync_rst, //! reset signal synchronous to clock
    axi4_lite_if.slv_port if_s_axi4_lite //! AXI4-Lite slave interface
);
    // ---------- parameters ----------
    //! example-specific design signals
    //! local parameter for addressing 32 bit / 64 bit AXI4_LITE_DATA_BIT_WIDTH
    //! AXI4_LITE_ADDR_LSB is used for addressing 32/64 bit registers/memories.
    //! AXI4_LITE_ADDR_LSB = 2 for 32 bits (n downto 2)
    //! AXI4_LITE_ADDR_LSB = 3 for 64 bits (n downto 3)
    localparam int AXI4_LITE_ADDR_LSB = (AXI4_LITE_DATA_BIT_WIDTH/32) + 1;
    localparam int BIT_WIDTH_WORD_ADDR = 2; //! Bit width of word address. Typically log2(number of registers)
    // --------------------

    // ---------- internal signal and storage ----------
    typedef struct {
        logic [AXI4_LITE_ADDR_BIT_WIDTH-1:0] awaddr;
        logic awready;
        logic wready;
        logic [1:0] bresp;
        logic bvalid;
        logic [AXI4_LITE_ADDR_BIT_WIDTH-1:0] araddr;
        logic arready;
        logic [AXI4_LITE_DATA_BIT_WIDTH-1:0] rdata;
        logic [1:0] rresp;
        logic rvalid;
    } axi4_lite_sigs_t;
    var axi4_lite_sigs_t r_axi4_lite_sigs; //! AXI4-Lite signals

    var logic [AXI4_LITE_DATA_BIT_WIDTH-1:0] r_slv_reg0; //! register 0
    var logic [AXI4_LITE_DATA_BIT_WIDTH-1:0] r_slv_reg1; //! register 1
    var logic [AXI4_LITE_DATA_BIT_WIDTH-1:0] r_slv_reg2; //! register 2
    var logic [AXI4_LITE_DATA_BIT_WIDTH-1:0] r_slv_reg3; //! register 3

    wire g_latch_awaddr; //! AWADDR latch timing signal.
    wire [BIT_WIDTH_WORD_ADDR-1:0] g_wr_word_addr; //! write word address
    wire [BIT_WIDTH_WORD_ADDR-1:0] g_rd_word_addr; //! read word address
    var logic g_rd_addr_is_in_range; //! Indicates that the read address is in valid range.
    var logic g_wr_addr_is_in_range; //! Indicates that the write address is in valid range.
    wire g_slv_reg_rd_en; //! register read enable
    wire g_slv_reg_wr_en; //! register write enable
    var logic [AXI4_LITE_DATA_BIT_WIDTH-1:0] g_reg_data_out; //! data in selected register
    wire g_curr_bvalid_accepted; //! Indicates the current BVALID signal is accepted by the master.
    var logic r_listen_to_wr_req; //! Indicates that there is no in-progress write transaction, and the slave listen to the next write request.

    assign g_latch_awaddr = ~r_axi4_lite_sigs.awready && if_s_axi4_lite.awvalid && if_s_axi4_lite.wvalid && r_listen_to_wr_req;
    assign g_wr_word_addr = r_axi4_lite_sigs.awaddr[AXI4_LITE_ADDR_LSB +: BIT_WIDTH_WORD_ADDR];
    assign g_rd_word_addr = r_axi4_lite_sigs.araddr[AXI4_LITE_ADDR_LSB +: BIT_WIDTH_WORD_ADDR];
    assign g_slv_reg_rd_en = r_axi4_lite_sigs.arready && if_s_axi4_lite.arvalid && ~r_axi4_lite_sigs.rvalid;
    assign g_slv_reg_wr_en = r_axi4_lite_sigs.wready && if_s_axi4_lite.wvalid && r_axi4_lite_sigs.awready && if_s_axi4_lite.awvalid;
    assign g_curr_bvalid_accepted = if_s_axi4_lite.bready && r_axi4_lite_sigs.bvalid;
    // --------------------

    // ---------- Drives output signals. ----------
    // Drive the AXI4-Lite slave output signals.
    // Note that all of them are registered.
    assign if_s_axi4_lite.awready = r_axi4_lite_sigs.awready;
    assign if_s_axi4_lite.wready = r_axi4_lite_sigs.wready;
    assign if_s_axi4_lite.bresp = r_axi4_lite_sigs.bresp;
    assign if_s_axi4_lite.bvalid = r_axi4_lite_sigs.bvalid;
    assign if_s_axi4_lite.arready = r_axi4_lite_sigs.arready;
    assign if_s_axi4_lite.rdata = r_axi4_lite_sigs.rdata;
    assign if_s_axi4_lite.rresp = r_axi4_lite_sigs.rresp;
    assign if_s_axi4_lite.rvalid = r_axi4_lite_sigs.rvalid;
    // --------------------

    //! Manage write request mask.
    always_ff @(posedge i_clk) begin: wr_req_mask
        if (i_sync_rst) begin
            r_listen_to_wr_req <= 1'b1;
        end else begin
            if (g_latch_awaddr) begin
                r_listen_to_wr_req <= 1'b0;
            end else if (g_curr_bvalid_accepted) begin
                r_listen_to_wr_req <= 1'b1;
            end
        end
    end

    //! Implement AWREADY generation.
    //! AWREADY is asserted for **one** AXI4-Lite clock cycle when both AWVALID and WVALID are asserted.
    //! AWREADY is de-asserted when reset is high.
    always_ff @(posedge i_clk) begin: gen_awready
        if (i_sync_rst) begin
            r_axi4_lite_sigs.awready <= 1'b0;
        end else begin
            if (g_latch_awaddr) begin
                // Slave is ready to accept write address when there is a valid write address and write data on the write address and data bus.
                // This design expects no outstanding transactions.
                r_axi4_lite_sigs.awready <= 1'b1;
            end else begin
                r_axi4_lite_sigs.awready <= 1'b0;
            end
        end
    end

    //! Implement AWADDR latching.
    //! This process is used to latch the address when both AWVALID and WVALID are valid.
    always_ff @(posedge i_clk) begin: latch_awaddr
        if (i_sync_rst) begin
            r_axi4_lite_sigs.awaddr <= '0;
        end else begin
            if (g_latch_awaddr) begin
                // Write Address latching
                r_axi4_lite_sigs.awaddr <= if_s_axi4_lite.awaddr;
            end
        end
    end

    //! Implement WREADY generation.
    //! WREADY is asserted for **one** AXI4-Lite clock cycle when both AWVALID and WVALID are asserted.
    //! WREADY is de-asserted when reset is high.
    always_ff @(posedge i_clk) begin: gen_wready
        if (i_sync_rst) begin
            r_axi4_lite_sigs.wready <= 1'b0;
        end else begin
            if (~r_axi4_lite_sigs.wready && if_s_axi4_lite.wvalid && if_s_axi4_lite.awvalid && r_listen_to_wr_req) begin
                // Slave is ready to accept write data when there is a valid write address and write data on the write address and data bus.
                // This design expects no outstanding transactions.
                r_axi4_lite_sigs.wready <= 1'b1;
            end else begin
                r_axi4_lite_sigs.wready <= 1'b0;
            end
        end
    end

    //! Check if the write address is in valid range.
    always_comb begin: check_wr_addr
        g_wr_addr_is_in_range = 1'b1;
        if (g_slv_reg_wr_en) begin
            case (g_wr_word_addr)
                BIT_WIDTH_WORD_ADDR'('h0):;
                BIT_WIDTH_WORD_ADDR'('h1):;
                BIT_WIDTH_WORD_ADDR'('h2):;
                BIT_WIDTH_WORD_ADDR'('h3):;
                default: begin
                    g_wr_addr_is_in_range = 1'b0;
                end
            endcase
        end
    end

    //! Implement memory mapped register select and write logic generation.
    //! The write data is accepted and written to memory mapped registers when AWREADY, WVALID, WREADY and WVALID are asserted.
    //! Write strobes are used to select byte enables of slave registers while writing.
    //! These registers are cleared when reset (active high) is applied.
    //! Slave register write enable is asserted when valid address and data are available and the slave is ready to accept the write address and write data.
    always_ff @(posedge i_clk) begin: write_reg
        if (i_sync_rst) begin
            r_slv_reg0 <= '0;
            r_slv_reg1 <= '0;
            r_slv_reg2 <= '0;
            r_slv_reg3 <= '0;
        end else begin
            if (g_slv_reg_wr_en) begin
                case (g_wr_word_addr)
                    BIT_WIDTH_WORD_ADDR'('h0): begin
                        for (int byte_index = 0; byte_index <= (AXI4_LITE_DATA_BIT_WIDTH/8)-1; byte_index += 1) begin
                            if (if_s_axi4_lite.wstrb[byte_index]) begin
                                // Respective byte enables are asserted as per write strobes.
                                // Slave register 0
                                r_slv_reg0[(byte_index*8) +: 8] <= if_s_axi4_lite.wdata[(byte_index*8) +: 8];
                            end
                        end
                    end
                    BIT_WIDTH_WORD_ADDR'('h1): begin
                        for (int byte_index = 0; byte_index <= (AXI4_LITE_DATA_BIT_WIDTH/8)-1; byte_index += 1) begin
                            if (if_s_axi4_lite.wstrb[byte_index]) begin
                                // Respective byte enables are asserted as per write strobes.
                                // Slave register 1
                                r_slv_reg1[(byte_index*8) +: 8] <= if_s_axi4_lite.wdata[(byte_index*8) +: 8];
                            end
                        end
                    end
                    BIT_WIDTH_WORD_ADDR'('h2): begin
                        for (int byte_index = 0; byte_index <= (AXI4_LITE_DATA_BIT_WIDTH/8)-1; byte_index += 1) begin
                            if (if_s_axi4_lite.wstrb[byte_index]) begin
                                // Respective byte enables are asserted as per write strobes.
                                // Slave register 2
                                r_slv_reg2[(byte_index*8) +: 8] <= if_s_axi4_lite.wdata[(byte_index*8) +: 8];
                            end
                        end
                    end
                    BIT_WIDTH_WORD_ADDR'('h3): begin
                        for (int byte_index = 0; byte_index <= (AXI4_LITE_DATA_BIT_WIDTH/8)-1; byte_index += 1) begin
                            if (if_s_axi4_lite.wstrb[byte_index]) begin
                                // Respective byte enables are asserted as per write strobes.
                                // Slave register 3
                                r_slv_reg3[(byte_index*8) +: 8] <= if_s_axi4_lite.wdata[(byte_index*8) +: 8];
                            end
                        end
                    end
                    default: begin
                        // r_slv_reg0 <= r_slv_reg0;
                        // r_slv_reg1 <= r_slv_reg1;
                        // r_slv_reg2 <= r_slv_reg2;
                        // r_slv_reg3 <= r_slv_reg3;
                    end
                endcase
            end
        end
    end

    //! Implement write response logic generation.
    //! The write response and response valid signals are asserted by the slave when WREADY, WVALID, AWREADY and AWVALID are asserted.
    //! This marks the acceptance of address and indicates the status of write transaction.
    always_ff @(posedge i_clk) begin: gen_bresp
        if (i_sync_rst) begin
            r_axi4_lite_sigs.bvalid <= 1'b0;
            r_axi4_lite_sigs.bresp <= '0;
        end else begin
            if (g_slv_reg_wr_en && ~r_axi4_lite_sigs.bvalid) begin
                // Indicates a valid write response is available.
                r_axi4_lite_sigs.bvalid <= 1'b1;
                r_axi4_lite_sigs.bresp <= g_wr_addr_is_in_range ? axi4_lite_if_pkg::AXI4_RESP_OKAY : axi4_lite_if_pkg::AXI4_RESP_SLVERR;
                // Work error responses in future.
            end else if (g_curr_bvalid_accepted) begin // Check if BREADY is asserted while BVALID is high (there is a possibility that BREADY is always asserted high).
                r_axi4_lite_sigs.bvalid <= 1'b0;
            end
        end
    end

    //! Implement ARREADY generation.
    //! ARREADY is asserted for **one** AXI4-Lite clock cycle when ARVALID is asserted. r_axi4_lite_sigs.awready is de-asserted when reset (active high) is asserted.
    //! The read address is also latched when ARVALID is asserted.
    //! ARADDR is reset to zero on reset assertion.
    always_ff @(posedge i_clk) begin: gen_arready
        if (i_sync_rst) begin
            r_axi4_lite_sigs.arready <= 1'b0;
            r_axi4_lite_sigs.araddr <= '0;
        end else begin
            if (~r_axi4_lite_sigs.arready && if_s_axi4_lite.arvalid) begin
                // Indicates that the slave has accepted the valid read address.
                r_axi4_lite_sigs.arready <= 1'b1;
                // read address latching
                r_axi4_lite_sigs.araddr <= if_s_axi4_lite.araddr;
            end else begin
                r_axi4_lite_sigs.arready <= 1'b0;
            end
        end
    end

    //! Implement RVALID generation.
    //! RVALID is asserted for **one** AXI4-Lite clock cycle when both ARVALID and ARREADY are asserted.
    //! The slave registers data are available on the RDATA bus at this instance.
    //! The assertion of RVALID marks the validity of read data on the bus and RRESP indicates the status of read transaction.
    //! RVALID is de-asserted on reset (active high).
    //! RRESP and RDATA are cleared to zero on reset (active high).
    always_ff @(posedge i_clk) begin: gen_rvalid
        if (i_sync_rst) begin
            r_axi4_lite_sigs.rvalid <= 1'b0;
            r_axi4_lite_sigs.rresp <= 2'b0;
        end else begin
            if (g_slv_reg_rd_en) begin
                // Valid read data is available at the read data bus.
                r_axi4_lite_sigs.rvalid <= 1'b1;
                r_axi4_lite_sigs.rresp <= g_rd_addr_is_in_range ? axi4_lite_if_pkg::AXI4_RESP_OKAY : axi4_lite_if_pkg::AXI4_RESP_SLVERR;
            end else if (r_axi4_lite_sigs.rvalid && if_s_axi4_lite.rready) begin
                // Read data is accepted by the master
                r_axi4_lite_sigs.rvalid <= 1'b0;
            end
        end
    end

    //! Implement memory mapped register select and read logic generation.
    //! Slave register read enable is asserted when valid address is available and the slave is ready to accept the read address.
    always_comb begin: dec_rd_addr
        // address decoding for reading registers
        g_rd_addr_is_in_range = 1'b1;
        case (g_rd_word_addr)
            BIT_WIDTH_WORD_ADDR'('h0): g_reg_data_out = r_slv_reg0;
            BIT_WIDTH_WORD_ADDR'('h1): g_reg_data_out = r_slv_reg1;
            BIT_WIDTH_WORD_ADDR'('h2): g_reg_data_out = r_slv_reg2;
            BIT_WIDTH_WORD_ADDR'('h3): g_reg_data_out = r_slv_reg3;
            default: begin
                g_rd_addr_is_in_range = 1'b0;
                g_reg_data_out = '0;
            end
        endcase
    end

    //! Output register read data.
    always_ff @(posedge i_clk) begin: out_rd_data
        if (i_sync_rst) begin
            r_axi4_lite_sigs.rdata <= '0;
        end else begin
            // When there is a valid read address (ARVALID) with acceptance of read address by the slave (ARREADY), output the read dada.
            if (g_slv_reg_rd_en) begin
                r_axi4_lite_sigs.rdata <= g_reg_data_out; // register read data
            end
        end
    end

    // Add user logic here.

    // User logic ends.
endmodule

`default_nettype wire
