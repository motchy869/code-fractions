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

    ---------- functions ----------
    --------------------

    ---------- signals and variables ----------
    signal r_clk: std_logic := '0'; --! clock signal
    signal r_sync_rst: std_logic; --! synchronous reset signal

    --! interface to DUT
    type dut_if_t is record
        ready_to_us: std_logic; --! ready signal to upstream side
        input_valid: std_logic; --! valid signal from upstream side
        in_val: signed(N-1 downto 0); --! input value to DUT

        ready_from_ds: std_logic; --! ready signal from downstream side
        output_valid: std_logic; --! output valid signal to downstream side
        out_val: signed(N-N_F-1 downto 0); --! output value from DUT
    end record;

    signal dut_if_0: dut_if_t; --! interface to DUT
    --------------------
begin
    ---------- procedures ----------
    --------------------

    ---------- processes ----------
    --! Drives clock signal.
    prc_drv_clk: process is begin
        r_clk <= not r_clk; wait for CLK_PERIOD_NS / 2;
    end process;

    --! Manages timeout for simulation.
    prc_term_sim: process is begin
        wait for SIM_TIME_LIMIT_NS;
        assert false report "Simulation timeout." severity failure;
    end process;
    --------------------
end architecture;
