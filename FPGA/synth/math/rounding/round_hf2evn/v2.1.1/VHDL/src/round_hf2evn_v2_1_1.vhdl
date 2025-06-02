--! This is a VHDL version of `round_hf2evn_v2_1_1`.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity round_hf2evn_v2_1_1 is
    generic (
        N: positive := 24; --! bit width of input
        N_F: positive := 8; --! bit width of fractional part, must be less than N
        EN_OUT_REG: boolean := false --! Enables output register.
    );
    port (
        i_clk: in std_ulogic; --! input clock, used only when ```EN_OUT_REG``` is ```true```.
        i_sync_rst: in std_ulogic; --! input reset signal synchronous to the input clock, used only when ```EN_OUT_REG``` is ```true```.

        --! @virtualbus us_side_if @dir in upstream side interface
        o_ready: out std_ulogic; --! Ready signal to upstream side which indicates that the upstream side is allowed to update input data (to this module) right AFTER the next rising edge of the clock. When ```EN_OUT_REG``` is ```false```, this is set to constant 1.
        i_input_valid: in std_ulogic; --! valid signal from upstream side, used only when ```EN_OUT_REG``` is ```true```.
        i_val: in unresolved_signed(N-1 downto 0); --! input value
        --! @end

        --! @virtualbus ds_side_if @dir out downstream side interface
        --! Ready signal from downstream side which indicates that this module is allowed to update output data (to downstream side) right AFTER the next rising edge of the clock. This is used only when ```EN_OUT_REG``` is ```true```.
        i_ds_ready: in std_ulogic;
        o_output_valid: out std_ulogic; --! Output valid signal. When ```EN_OUT_REG``` is ```false```, this is set to constant 1.
        o_val: out unresolved_signed(N-N_F-1 downto 0) --! output value (integer part only)
        --! @end
    );
end entity;

architecture rtl of round_hf2evn_v2_1_1 is
    ---------- constants ----------
    constant N_I: positive := N-N_F; --! bit width of integer part
    constant FRAC_PART_ZP5: unresolved_unsigned(N_F-1 downto 0) := (N_F-1 => '1', others => '0'); --! 0.5 in fractional part
    constant INT_PART_MAX: unresolved_signed(N_I-1 downto 0) := '0' & (N_I-2 downto 0 => '1'); --! max value of integer part
    --------------------

    ---------- constants validation ----------
    --------------------

    ---------- functions ----------
    --------------------

    ---------- signals and variables ----------
    signal w_int_part: signed(N_I-1 downto 0); --! integer part of input value
    signal w_frac_part: unsigned(N_F-1 downto 0); --! fractional part of input value
    signal g_int_part_is_max: std_ulogic; --! flag indicating that the integer part is max value
    signal g_frac_part_is_0: std_ulogic; --! flag indicating that the fractional part is zero
    signal g_frac_part_is_0p5: std_ulogic; --! flag indicating that the fractional part is 0.5
    signal g_post_round_val: signed(N_I-1 downto 0); --! post-rounding value
    --------------------
begin
    ---------- processes ----------
    --! Assigns values to signals.
    prc_asgn: process(all) is begin
        w_int_part <= i_val(N-1 downto N_F);
        w_frac_part <= unsigned(i_val(N_F-1 downto 0));
        g_int_part_is_max <= w_int_part ?= INT_PART_MAX;
        g_frac_part_is_0 <= w_frac_part ?= (N_F-1 downto 0 => '0');
        g_frac_part_is_0p5 <= w_frac_part ?= FRAC_PART_ZP5;
    end process;

    --! Calculates post-rounding value.
    prc_calc_post_round_val: process(all) is begin
        if g_frac_part_is_0 then
            g_post_round_val <= w_int_part;
        elsif g_frac_part_is_0p5 then
            -- Note that the sign doesn't matter (except for clipping).
            -- For example, val = -2.3, the integer and fractional parts obtained from bit slice are -3 and 0.7 respectively.
            -- The fractional part always fall into the range [0, 1).
            g_post_round_val <= w_int_part + ((not g_int_part_is_max) and w_int_part(0));
        else
            -- Note that at this point the fractional part is neither 0 nor 0.5.
            g_post_round_val <= w_int_part + ((not g_int_part_is_max) and w_frac_part(N_F-1));
        end if;
    end process;

    gen_out_reg: if EN_OUT_REG generate
        blk_out_reg: block
            signal r_vld_dly_line: std_ulogic := '0'; --! delay line for the output valid signal
            signal g_can_adv_pip_ln: std_ulogic;-- := (not r_vld_dly_line) and i_ds_ready; --! signal indicating that the pipeline can advance
            signal g_adv_pip_ln: std_ulogic;-- := i_input_valid and g_can_adv_pip_ln; --! signal indicating that the pipeline should advance
            signal r_post_round_val: signed(N_I-1 downto 0) := (others => '0'); --! register for post-rounding value
        begin
            --! Assigns values to signals.
            prc_asgn: process(all) is begin
                g_can_adv_pip_ln <= (not r_vld_dly_line) or i_ds_ready;
                g_adv_pip_ln <= i_input_valid and g_can_adv_pip_ln;
            end process;

            --! Updates valid delay line.
            prc_update_vld_dly_line: process(i_clk) is begin
                if rising_edge(i_clk) then
                    if (i_sync_rst = '1') then
                        r_vld_dly_line <= '0';
                    elsif g_adv_pip_ln then
                        r_vld_dly_line <= '1';
                    end if;
                end if;
            end process;

            --! Updates output register.
            prc_update_update_out_reg: process(i_clk) is begin
                if rising_edge(i_clk) then
                    if (i_sync_rst = '1') then
                        r_post_round_val <= (others =>'0');
                    elsif g_adv_pip_ln then
                        r_post_round_val <= g_post_round_val;
                    end if;
                end if;
            end process;

            --! Assigns output values.
            prc_asgn_output: process(all) is begin
                o_ready <= g_can_adv_pip_ln;
                o_output_valid <= r_vld_dly_line;
                o_val <= r_post_round_val;
                -- report "Updates output values. o_output_valid = " & to_string(o_output_valid) severity note;
            end process;
        end block;
    else generate
        --! Assigns output values.
        prc_asgn_output: process(all) is begin
            -- report "Updates output values." severity note;
            o_ready <= '1';
            o_output_valid <= '1';
            o_val <= g_post_round_val;
        end process;
    end generate;
    --------------------
end architecture;
