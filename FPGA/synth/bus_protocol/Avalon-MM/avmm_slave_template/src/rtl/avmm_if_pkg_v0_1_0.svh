`ifdef AVMM_IF_PKG_SVH_INCLUDED
`define AVMM_IF_PKG_SVH_INCLUDED

// Verible directive
// verilog_lint: waive-start parameter-name-style
// verilog_lint: waive-start line-length

`include "avmm_if_v_0_1_0.svh"

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
            typedef virtual interface avmm_if_v_0_1_0 #(
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

            // Waits preceding read transaction to complete.
            static task automatic wait_read_txn(
                vif_t vif, // virtual interface to DUT
                input int unsigned timeout_cyc = 32, //! timeout in clock cycles
                output bit is_timeout, //! 1 if timeout occurs, otherwise 0
                output int unsigned time_cnt //! time counter
            );
                time_cnt = 0;
                is_timeout = 1'b0;

                forever begin
                    forever begin
                        if (vif.readdatavalid) begin
                            break;
                        end
                        @(posedge vif.i_clk);
                        ++time_cnt;
                        if (time_cnt >= timeout_cyc) begin
                            is_timeout = 1'b1;
                            break;
                        end
                    end
                    if (is_timeout) begin
                        break;
                    end
                    if (!vif.read) begin
                        break;
                    end
                    @(posedge vif.i_clk);
                    ++time_cnt;
                    if (time_cnt >= timeout_cyc) begin
                        is_timeout = 1'b1;
                        break;
                    end
                end

                if (is_timeout) begin
                    const string msg = "Timeout occurs while waiting for the read data to be valid.";
                    `ifdef uvm_info
                        `uvm_info("INFO", msg, UVM_MEDIUM);
                    `else
                        $info(msg);
                    `endif
                end
            endtask

            // Waits preceding write transaction to complete.
            static task automatic wait_write_txn(
                vif_t vif, // virtual interface to DUT
                input int unsigned timeout_cyc = 32, //! timeout in clock cycles
                output bit is_timeout, //! 1 if timeout occurs, otherwise 0
                output int unsigned time_cnt //! time counter
            );
                time_cnt = 0;
                is_timeout = 1'b0;

                forever begin
                    forever begin
                        if (vif.writeresponsevalid) begin
                            break;
                        end
                        @(posedge vif.i_clk);
                        ++time_cnt;
                        if (time_cnt >= timeout_cyc) begin
                            is_timeout = 1'b1;
                            break;
                        end
                    end
                    if (is_timeout) begin
                        break;
                    end
                    if (!vif.write) begin
                        break;
                    end
                    @(posedge vif.i_clk);
                    ++time_cnt;
                    if (time_cnt >= timeout_cyc) begin
                        is_timeout = 1'b1;
                        break;
                    end
                end

                if (is_timeout) begin
                    const string msg = "Timeout occurs while waiting for the write response to be valid.";
                    `ifdef uvm_info
                        `uvm_info("INFO", msg, UVM_MEDIUM);
                    `else
                        $info(msg);
                    `endif
                end
            endtask

            // Checks and waits preceding transaction.
            static task automatic chk_and_wait_prec_txn(
                vif_t vif, // virtual interface to DUT
                input int unsigned timeout_cyc = 32, //! timeout in clock cycles
                output bit is_timeout, //! 1 if timeout occurs, otherwise 0
                output int unsigned time_cnt //! time counter
            );
                string msg;
                bit prec_txn_is_read;

                if (vif.read || vif.readdatavalid || vif.write || vif.writeresponsevalid) begin
                    if (vif.read || vif.readdatavalid) begin
                        msg = "There is a preceding read transaction in progress. Waiting for it to complete.";
                        prec_txn_is_read = 1'b1;
                    end else if (vif.write || vif.writeresponsevalid) begin
                        msg = "There is a preceding write transaction in progress. Waiting for it to complete.";
                        prec_txn_is_read = 1'b0;
                    end
                    `ifdef uvm_info
                        `uvm_info("INFO", msg, UVM_MEDIUM);
                    `else
                        $info(msg);
                    `endif
                    if (prec_txn_is_read) begin
                        wait_read_txn(vif, timeout_cyc, is_timeout, time_cnt);
                    end else begin
                        wait_write_txn(vif, timeout_cyc, is_timeout, time_cnt);
                    end
                end
            endtask

            // Performs read transaction.
            static task automatic read(
                vif_t vif, // virtual interface to DUT
                input bit [AVMM_ADDR_BIT_WIDTH-1:0] addr, // address
                output bit [AVMM_DATA_BIT_WIDTH-1:0] data, // storage for read data
                output avmm_resp_t resp, // storage for response
                input int unsigned timeout_cyc = 32, //! timeout in clock cycles
                output bit is_timeout, //! 1 if timeout occurs, otherwise 0
                output int unsigned time_cnt //! time counter
            );
                time_cnt = 0;
                is_timeout = 1'b0;

                // Waits for preceding transaction if exists.
                chk_and_wait_prec_txn(vif, timeout_cyc, is_timeout, time_cnt);
                if (is_timeout) begin
                    return;
                end

                // Issues a read request.
                @(posedge vif.i_clk);
                vif.read <= 1'b1;
                vif.write <= 1'b0;
                vif.address <= addr;

                // Waits until the read data is valid.
                forever begin
                    if (!vif.waitrequest && vif.readdatavalid) begin
                        break;
                    end
                    @(posedge vif.i_clk);
                    ++time_cnt;
                    if (time_cnt >= timeout_cyc) begin
                        is_timeout = 1'b1;
                        break;
                    end
                end

                if (is_timeout) begin
                    const string msg = "Timeout occurs while waiting for the read data to be valid.";
                    `ifdef uvm_info
                        `uvm_info("INFO", msg, UVM_MEDIUM);
                    `else
                        $info(msg);
                    `endif

                    @(posedge vif.i_clk);
                    vif.read <= 1'b0;
                    vif.write <= 1'b0;
                    return;
                end

                data = vif.readdata;
                resp = vif.response;
            endtask

            // Performs write transaction.
            static task automatic write(
                vif_t vif, // virtual interface to DUT
                input bit [AVMM_ADDR_BIT_WIDTH-1:0] addr, // address
                input bit [AVMM_DATA_BIT_WIDTH-1:0] data, // data to write
                input bit [AVMM_DATA_BIT_WIDTH/8-1:0] byte_en, // byte enable
                output avmm_resp_t resp, // storage for response
                input int unsigned timeout_cyc = 32, //! timeout in clock cycles
                output bit is_timeout, //! 1 if timeout occurs, otherwise 0
                output int unsigned time_cnt //! time counter
            );
                time_cnt = 0;
                is_timeout = 1'b0;

                // Waits for preceding transaction if exists.
                chk_and_wait_prec_txn(vif, timeout_cyc, is_timeout, time_cnt);
                if (is_timeout) begin
                    return;
                end

                // Issues a write request.
                @(posedge vif.i_clk);
                vif.read <= 1'b0;
                vif.write <= 1'b1;
                vif.address <= addr;

                // Waits until the write response is valid.
                forever begin
                    if (!vif.waitrequest && vif.writeresponsevalid) begin
                        break;
                    end
                    @(posedge vif.i_clk);
                    ++time_cnt;
                    if (time_cnt >= timeout_cyc) begin
                        is_timeout = 1'b1;
                        break;
                    end
                end

                if (is_timeout) begin
                    const string msg = "Timeout occurs while waiting for the write response to be valid.";
                    `ifdef uvm_info
                        `uvm_info("INFO", msg, UVM_MEDIUM);
                    `else
                        $info(msg);
                    `endif

                    @(posedge vif.i_clk);
                    vif.read <= 1'b0;
                    vif.write <= 1'b0;
                    return;
                end

                resp = vif.response;
            endtask
        endclass
    `endif
endpackage

`endif // AVMM_IF_PKG_SVH_INCLUDED
