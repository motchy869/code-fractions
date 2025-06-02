library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.finish;

entity test_bench is
end;

architecture behavioral of test_bench is
    ---------- constants ----------
    constant CLK_PERIOD_NS: time := 8 ns; --! clock period in ns
    constant SIM_TIME_LIMIT_NS: time := 100 ns; --! simulation time limit in ns
    constant RST_DURATION_CYCLE: positive := 1; -- ! reset duration in cycles

    constant BW_IN: positive := 8; --! input bit width
    constant BW_OUT: positive := 9; --! output bit width
    --------------------

    ---------- types ----------
    --! record for DUT interface
    type dut_if_rcd_t is record
        freeze: std_ulogic;

        a: unresolved_signed(BW_IN-1 downto 0);
        b: unresolved_signed(BW_IN-1 downto 0);

        out_vld: std_ulogic;
        sum: signed(BW_OUT-1 downto 0);
        diff: signed(BW_OUT-1 downto 0);
    end record;

    view dut_if_dut_side_view of dut_if_rcd_t is
        freeze, a, b: in;
        out_vld, sum, diff: out;
    end view;

    alias dut_if_bench_side_view is dut_if_dut_side_view'converse;
    --------------------

    ---------- functions ----------
    --------------------

    ---------- procedures ----------
    --! Resets bench-driven signals.
    procedure rst_bench_drv_sig(
        signal dut_if: view dut_if_bench_side_view
    ) is begin
        dut_if.freeze <= '0';
        dut_if.a <= (others => '0');
        dut_if.b <= (others => '0');
    end procedure;

    --! Drives the reset signal.
    procedure drv_rst(
        signal clk: in std_ulogic;
        signal sync_rst: out std_ulogic;
        signal dut_if: view dut_if_bench_side_view
    ) is begin
        wait until rising_edge(clk);
        sync_rst <= '1';
        rst_bench_drv_sig(dut_if);
        for i in 0 to RST_DURATION_CYCLE-1 loop
            wait until rising_edge(clk);
        end loop;
        sync_rst <= '0';
    end procedure;

    --! Runs test cases.
    procedure run_test_cases(
        signal clk: in std_ulogic;
        signal dut_if: view dut_if_bench_side_view
    ) is
        constant NUM_TEST_CASES: positive := 10;
        type test_case_t is record
            a: unresolved_signed(BW_IN-1 downto 0);
            b: unresolved_signed(BW_IN-1 downto 0);
            expected_sum: unresolved_signed(BW_OUT-1 downto 0);
            expected_diff: unresolved_signed(BW_OUT-1 downto 0);
        end record;
        type test_cases_t is array(0 to NUM_TEST_CASES-1) of test_case_t;
        constant test_cases: test_cases_t := (
            (to_signed(1, BW_IN), to_signed(2, BW_IN), to_signed(3, BW_OUT), to_signed(-1, BW_OUT)),
            (to_signed(5, BW_IN), to_signed(3, BW_IN), to_signed(8, BW_OUT), to_signed(2, BW_OUT)),
            (to_signed(-4, BW_IN), to_signed(-6, BW_IN), to_signed(-10, BW_OUT), to_signed(2, BW_OUT)),
            (to_signed(0, BW_IN), to_signed(0, BW_IN), to_signed(0, BW_OUT), to_signed(0, BW_OUT)),
            (to_signed(-1, BW_IN), to_signed(-1, BW_IN), to_signed(-2, BW_OUT), to_signed(0, BW_OUT)),
            (to_signed(127, BW_IN), to_signed(1, BW_IN), to_signed(128, BW_OUT), to_signed(126, BW_OUT)),
            (to_signed(-128, BW_IN), to_signed(-1, BW_IN), to_signed(-129, BW_OUT), to_signed(-127, BW_OUT)),
            (to_signed(100, BW_IN), to_signed(50, BW_IN), to_signed(150, BW_OUT), to_signed(50, BW_OUT)),
            (to_signed(-100, BW_IN), to_signed(-50, BW_IN), to_signed(-150, BW_OUT), to_signed(-50, BW_OUT)),
            (to_signed(255,BW_IN) ,to_signed(1,BW_IN) ,to_signed(256,BW_OUT) ,to_signed(254,BW_OUT))
        );
        variable is_error: boolean := false;
        variable cnt_input: natural := 0;
        variable cnt_output: natural := 0;
    begin
        wait until rising_edge(clk);
        dut_if.freeze <= '0';
        while (cnt_output < NUM_TEST_CASES) loop
            wait until rising_edge(clk);
            if (dut_if.out_vld = '1') then
                cnt_output := cnt_output + 1;
            end if;
            if (cnt_input < NUM_TEST_CASES) then
                dut_if.a <= test_cases(cnt_input).a;
                dut_if.b <= test_cases(cnt_input).b;
                cnt_input := cnt_input + 1;
            else
                dut_if.a <= (others => '0');
                dut_if.b <= (others => '0');
            end if;
        end loop;
        if (not is_error) then
            report "All test cases passed." severity note;
        end if;
        finish;
    end procedure;
    --------------------

    ---------- signals and variables ----------
    signal w_clk: std_ulogic := '0'; --! clock signal
    signal w_sync_rst: std_ulogic := '1'; --! synchronous reset signal

    signal dut_if_0: dut_if_rcd_t;
    --------------------
begin
    ---------- instances ----------
    dut_0: entity work.example_add_sub generic map (
        BW_IN => BW_IN, BW_OUT => BW_OUT
    ) port map (
        i_clk => w_clk,
        i_sync_rst => w_sync_rst,
        i_freeze => dut_if_0.freeze,

        i_a => dut_if_0.a,
        i_b => dut_if_0.b,

        o_out_vld => dut_if_0.out_vld,
        o_sum => dut_if_0.sum,
        o_diff => dut_if_0.diff
    );
    --------------------

    ---------- processes ----------
    --! Drives clock signal.
    w_clk <= not w_clk after CLK_PERIOD_NS / 2;

    --! Manages simulation time limit.
    prc_tim_lim: process is begin
        wait for SIM_TIME_LIMIT_NS;
        assert false report "Simulation timeout." severity failure;
    end process;

    --! simulation main part
    prc_main: process is
    begin
        drv_rst(w_clk, w_sync_rst, dut_if_0);
        run_test_cases(w_clk, dut_if_0);
        wait;
    end process;
    --------------------
end;