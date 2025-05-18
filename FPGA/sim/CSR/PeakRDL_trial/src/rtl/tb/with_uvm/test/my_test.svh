// Verible directive
// verilog_lint: waive-start line-length
// verilog_lint: waive-start parameter-name-style

//! Some techniques used in this file are based on the following source:
//! - [UVM Register Model Example](https://www.chipverify.com/uvm/uvm-register-model-example)

`ifndef INCLUDED_FROM_MY_VERIF_PKG
    $fatal(2, "include \"my_verif_pkg.svh\" instead of including this file");
    nonexistent_module_to_throw_a_custom_error_message_for_invalid_inclusion inst();
`endif

class my_test extends my_base_test;
    `uvm_component_utils(my_test)

    localparam int SIM_TIME_LIMIT_NS = 1500; //! simulation time limit in ns

    function new(string name = "my_test", uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
    endfunction

    virtual function void end_of_elaboration_phase(uvm_phase phase);
        super.end_of_elaboration_phase(phase);
        uvm_factory::get().print();
        uvm_root::get().print_topology();
    endfunction

    virtual function void start_of_simulation_phase(uvm_phase phase);
        super.start_of_simulation_phase(phase);
        uvm_root::get().set_timeout(SIM_TIME_LIMIT_NS, 0);
    endfunction

    //! Note that `main_phase` comes after `reset_phase` in the UVM sequence of phases
    extern virtual task main_phase(uvm_phase phase);
endclass

task my_test::main_phase(uvm_phase phase);
    my_mod_csr_uvm_reg_model_pkg::my_mod_csr reg_model;
    uvm_status_e reg_acc_status;
    bit [AXI4_LITE_DATA_BIT_WIDTH-1:0] read_back_data;

    phase.raise_objection(this);
    if (!uvm_config_db#(my_mod_csr_uvm_reg_model_pkg::my_mod_csr)::get(null, "uvm_test_top", "g_reg_model", reg_model)) begin
        `uvm_fatal("NO-REG_MODEL", {"register model must be set for: ", "uvm_test_top", ".g_reg_model"})
    end

    begin // MY_MOD_VERSION
        const bit [AXI4_LITE_DATA_BIT_WIDTH-1:0] expected_rd_data = AXI4_LITE_DATA_BIT_WIDTH'('h01234567);
        reg_model.MY_MOD_VERSION.read(reg_acc_status, read_back_data);
        assert(read_back_data == expected_rd_data) else begin
            $fatal(2, "MY_MOD_VERSION: read data mismatch.");
        end
    end

    begin // PROTECTED_REG
        const bit [AXI4_LITE_DATA_BIT_WIDTH-1:0] unlock_key = '1;
        const bit [AXI4_LITE_DATA_BIT_WIDTH-1:0] expected_rd_data_0 = AXI4_LITE_DATA_BIT_WIDTH'('h0); // expected read data before unlock
        const bit [AXI4_LITE_DATA_BIT_WIDTH-1:0] expected_rd_data_1 = AXI4_LITE_DATA_BIT_WIDTH'('hC001C0DE); // expected read data after unlock

        // before unlock
        reg_model.PROTECTED_REG.write(reg_acc_status, AXI4_LITE_DATA_BIT_WIDTH'('hBADCACA0));
        reg_model.PROTECTED_REG.read(reg_acc_status, read_back_data);

        assert(read_back_data == expected_rd_data_0) else begin
            $fatal(2, "PROTECTED_REG: read data mismatch.");
        end

        // unlock
        reg_model.UNLOCK_PROTECTED_REG.write(reg_acc_status, unlock_key);

        // after unlock
        reg_model.PROTECTED_REG.write(reg_acc_status, expected_rd_data_1);
        reg_model.PROTECTED_REG.read(reg_acc_status, read_back_data);

        assert(read_back_data == expected_rd_data_1) else begin
            $fatal(2, "PROTECTED_REG: read data mismatch.");
        end
    end

    begin // SINGLE_PULSE
        const bit [AXI4_LITE_DATA_BIT_WIDTH-1:0] expected_rd_data = AXI4_LITE_DATA_BIT_WIDTH'('h0);

        reg_model.SINGLE_PULSE.write(reg_acc_status, AXI4_LITE_DATA_BIT_WIDTH'('h1));
        reg_model.SINGLE_PULSE.read(reg_acc_status, read_back_data);

        assert(read_back_data == expected_rd_data) else begin
            $fatal(2, "SINGLE_PULSE: read data mismatch.");
        end
    end

    begin // WRITE_ONCE
        const bit [AXI4_LITE_DATA_BIT_WIDTH-1:0] expected_rd_data = AXI4_LITE_DATA_BIT_WIDTH'('hC001FACE);
        const bit [AXI4_LITE_DATA_BIT_WIDTH-1:0] wr_data_2nd = AXI4_LITE_DATA_BIT_WIDTH'('hCAFEBABE);

        // 1 st write
        reg_model.WRITE_ONCE.write(reg_acc_status, expected_rd_data);
        reg_model.WRITE_ONCE.read(reg_acc_status, read_back_data);

        assert(read_back_data == expected_rd_data) else begin
            $fatal(2, "WRITE_ONCE: read data mismatch.");
        end

        // 2nd write
        reg_model.WRITE_ONCE.write(reg_acc_status, wr_data_2nd);
        reg_model.WRITE_ONCE.read(reg_acc_status, read_back_data);

        assert(read_back_data == expected_rd_data) else begin
            //$fatal(2, "WRITE_ONCE: read data mismatch."); // `w1` and `rw1` has not been supported yet.
        end
    end

    begin // SIMPLE_MEM
        const int ram_depth = reg_model.SIMPLE_MEM.m_mem.get_size();
        `uvm_info("INFO", $sformatf("SIMPLE_MEM: ram_depth=%0d", ram_depth), UVM_DEBUG)
        // write
        for (int i=0; i<ram_depth; ++i) begin
            /* const */ bit [AXI4_LITE_ADDR_BIT_WIDTH-1:0] offset_byte_addr = AXI4_LITE_ADDR_BIT_WIDTH'(i*AXI4_LITE_DATA_BIT_WIDTH/8); // `const` gets compilation stuck.

            // Vivado 2023.2 crashes in `write` method.
            //reg_model.SIMPLE_MEM.m_mem.write(reg_acc_status, offset_byte_addr, AXI4_LITE_DATA_BIT_WIDTH'(i));
        end

        // read
        for (int i=0; i<ram_depth; ++i) begin
            /* const */ bit [AXI4_LITE_ADDR_BIT_WIDTH-1:0] offset_byte_addr = AXI4_LITE_ADDR_BIT_WIDTH'(i*AXI4_LITE_DATA_BIT_WIDTH/8);

            // Vivado 2023.2 crashes in `read` method.
            // reg_model.SIMPLE_MEM.m_mem.read(reg_acc_status, offset_byte_addr, read_back_data);

            // assert(read_back_data == AXI4_LITE_DATA_BIT_WIDTH'(i)) else begin
            //     $fatal(2, "SIMPLE_MEM: read data mismatch.");
            // end
        end
    end

    phase.drop_objection(this);
endtask
