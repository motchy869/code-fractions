library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity test_bench is
end entity;

architecture behavioral of test_bench is
    ---------- constants ----------
    constant CLK_PERIOD_NS: time := 8 ns; --! clock period in ns
    constant SIM_TIME_LIMIT_NS: time := 300 ns; --! simulation time limit in ns
    constant RST_DURATION_CYCLE: positive := 1; -- ! reset duration in cycles

    constant N: positive := 8; --! bit width
    constant N_F: positive := 2; --! bit width of fractional part
    constant EN_OUT_REG: boolean := true; --! enables output register
    --------------------

    ---------- types ----------
    --! interface to DUT
    type dut_if_t is record
        ready_to_us: std_logic; --! ready signal to upstream side
        input_valid: std_logic; --! valid signal from upstream side
        in_val: signed(N-1 downto 0); --! input value to DUT

        ready_from_ds: std_logic; --! ready signal from downstream side
        output_valid: std_logic; --! output valid signal to downstream side
        out_val: signed(N-N_F-1 downto 0); --! output value from DUT
    end record;
    --------------------

    ---------- functions ----------
    --------------------

    ---------- procedures ----------
    -- --! Resets bench-driven signals.
    -- procedure rst_bench_drv_sig(
    --     signal dut_if: out dut_if_t
    -- ) is begin
    --     dut_if.input_valid <= '0';
    --     dut_if.in_val <= (others => '0');
    --     dut_if.ready_from_ds <= '0';
    -- end procedure;

    -- --! Drives the reset signal.
    -- procedure drv_rst(
    --     signal clk: in std_logic;
    --     signal sync_rst: out std_logic;
    --     signal dut_if: inout dut_if_t
    -- ) is begin
    --     wait until rising_edge(clk);
    --     sync_rst <= '1';
    --     rst_bench_drv_sig(dut_if);
    --     for i in 0 to RST_DURATION_CYCLE-1 loop
    --         wait until rising_edge(clk);
    --     end loop;
    --     sync_rst <= '0';
    -- end procedure;
    --------------------

    ---------- signals and variables ----------
    signal w_clk: std_logic := '0'; --! clock signal
    signal w_sync_rst: std_logic := '1'; --! synchronous reset signal

    --! interface to DUT
    signal dut_if_0: dut_if_t := (
        ready_to_us => '0',
        input_valid => '0',
        in_val => (others => '0'),

        ready_from_ds => '0',
        output_valid => '0',
        out_val => (others => '0')
    );
    signal w_do_init_rst: boolean := false; --! signal to do initial reset
    signal w_init_rst_done: boolean := false; --! signal to indicate that initial reset is done
    signal w_run_test_cases: boolean := false; --! signal to run test cases
    --------------------

begin
    ---------- instances ----------
    dut_0: entity work.round_hf2evn_v2_1_1 generic map (
        N => N, N_F => N_F, EN_OUT_REG => EN_OUT_REG
    ) port map (
        i_clk => w_clk,
        i_sync_rst => w_sync_rst,

        o_ready => dut_if_0.ready_to_us,
        i_input_valid => dut_if_0.input_valid,
        i_val => dut_if_0.in_val,

        i_ds_ready => dut_if_0.ready_from_ds,
        o_output_valid => dut_if_0.output_valid,
        o_val => dut_if_0.out_val
    );
    --------------------

    ---------- processes ----------
    --! Drives clock signal.
    prc_drv_clk: process is begin
        w_clk <= not w_clk; wait for CLK_PERIOD_NS / 2;
    end process;

    --! Controls simulation phase.
    prc_ctrl_sim_phase: process is begin
        w_do_init_rst <= true;
        wait until w_init_rst_done;
        w_run_test_cases <= true;
        wait for SIM_TIME_LIMIT_NS;
        assert false report "Simulation timeout." severity failure;
    end process;

    --! initial reset
    prc_init_rst: process is
        procedure rst_bench_drv_sig is begin
            dut_if_0.input_valid <= '0';
            dut_if_0.in_val <= (others => '0');
            dut_if_0.ready_from_ds <= '0';
        end procedure;
    begin
        wait until rising_edge(w_clk) and w_do_init_rst;
        w_sync_rst <= '1';
        rst_bench_drv_sig;
        report "Reset bench-driven signal." severity note;
        for i in 0 to RST_DURATION_CYCLE-1 loop
            wait until rising_edge(w_clk);
        end loop;
        w_sync_rst <= '0';
        w_init_rst_done <= true;
        report "Initial reset done." severity note;
        report "dut_if_0.input_valid = " & std_logic'image(dut_if_0.input_valid) severity note;
        wait;
    end process;

    --! Runs test cases.
    prc_test_cases: process is
        constant NUM_TEST_CASES: positive := 21; -- number of values to test
        type test_case_t is record
            in_val: signed(N-1 downto 0); -- input value
            expected_out_val: signed(N-N_F-1 downto 0); -- expected output value
        end record;
        type test_cases_t is array(0 to NUM_TEST_CASES-1) of test_case_t;
        constant test_cases: test_cases_t := (
            (in_val => b"1111_0110", expected_out_val => b"1111_10"),
            (in_val => b"1111_0111", expected_out_val => b"1111_10"),
            (in_val => b"1111_1000", expected_out_val => b"1111_10"),
            (in_val => b"1111_1001", expected_out_val => b"1111_10"),
            (in_val => b"1111_1010", expected_out_val => b"1111_10"),
            (in_val => b"1111_1011", expected_out_val => b"1111_11"),
            (in_val => b"1111_1100", expected_out_val => b"1111_11"),
            (in_val => b"1111_1101", expected_out_val => b"1111_11"),
            (in_val => b"1111_1110", expected_out_val => b"0000_00"),
            (in_val => b"1111_1111", expected_out_val => b"0000_00"),
            (in_val => b"0000_0000", expected_out_val => b"0000_00"),
            (in_val => b"0000_0001", expected_out_val => b"0000_00"),
            (in_val => b"0000_0010", expected_out_val => b"0000_00"),
            (in_val => b"0000_0011", expected_out_val => b"0000_01"),
            (in_val => b"0000_0100", expected_out_val => b"0000_01"),
            (in_val => b"0000_0101", expected_out_val => b"0000_01"),
            (in_val => b"0000_0110", expected_out_val => b"0000_10"),
            (in_val => b"0000_0111", expected_out_val => b"0000_10"),
            (in_val => b"0000_1000", expected_out_val => b"0000_10"),
            (in_val => b"0000_1001", expected_out_val => b"0000_10"),
            (in_val => b"0000_1010", expected_out_val => b"0000_10")
        );
        variable is_error: boolean := false;
        variable cnt_input: natural := 0;
        variable cnt_output: natural := 0;
    begin
        wait until w_run_test_cases;
        report "Starting test case." severity note;
        while (cnt_output < NUM_TEST_CASES) loop
            wait until rising_edge(w_clk);
            if (dut_if_0.output_valid = '1') then
                if (dut_if_0.out_val /= test_cases(cnt_output).expected_out_val) then
                    is_error := true;
                    report "Test case " & integer'image(cnt_output) & " failed. Expected: " & to_hstring(test_cases(cnt_output).expected_out_val) severity error;
                end if;
                cnt_output := cnt_output + 1;
            end if;
            if (cnt_input < NUM_TEST_CASES) then
                dut_if_0.input_valid <= '1';
                dut_if_0.in_val <= test_cases(cnt_input).in_val;
                cnt_input := cnt_input + 1;
            else
                dut_if_0.input_valid <= '0';
                dut_if_0.in_val <= (others => '0');
            end if;
            dut_if_0.ready_from_ds <= '1';
        end loop;

        wait until rising_edge(w_clk);
        dut_if_0.ready_from_ds <= '0';

        if (not is_error) then
            report "All test cases passed." severity note;
        end if;
        wait;
    end process;
    --------------------
end architecture;
