library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--! An example naive adder and subtractor module.
--! There is **NO** handshake function, so a parent module must handle the flow control.

entity example_add_sub is
    generic (
        BW_IN: positive := 8; --! input bit width
        BW_OUT: positive := 9 --! output bit width
    );
    port (
        --! @virtualbus cont_if @dir in control interface
        i_clk: in std_ulogic; --! input clock, used only when ```EN_OUT_REG``` is ```true```.
        i_sync_rst: in std_ulogic; --! input reset signal synchronous to the input clock, used only when ```EN_OUT_REG``` is ```true```.
        i_freeze: in std_ulogic; --! Freeze directive, which stops all state transitions except for the reset. this signal can be used to flow control by the parent module.
        --! @end

        --! @virtualbus us_side_if @dir in upstream-side interface
        --! input operand a
        i_a: in unresolved_signed(BW_IN-1 downto 0);
        i_b: in unresolved_signed(BW_IN-1 downto 0); --! input operand b
        --! @end

        --! @virtualbus ds_side_if @dir out downstream-side interface
        --! Signal indicating that the output vector is valid. This is **ONLY** for initial garbage data skipping, **NOT** for flow control.
        o_out_vld: out std_ulogic;
        o_sum: out unresolved_signed(BW_OUT-1 downto 0); --! output sum
        o_diff: out unresolved_signed(BW_OUT-1 downto 0) --! output difference
        --! @end
    );
end;

architecture rtl of example_add_sub is
    ---------- constants ----------
    --------------------

    ---------- constants validation ----------
    --------------------

    ---------- functions ----------
    --------------------

    ---------- signals and variables ----------
    --------------------
begin
    ---------- instances ----------
    --------------------

    ---------- processes ----------
    prc_add: process(i_clk) is begin
        if rising_edge(i_clk) then
            if i_sync_rst = '1' then
                o_out_vld <= '0';
                o_sum <= (others => '0');
                o_diff <= (others => '0');
            elsif i_freeze = '0' then
                o_out_vld <= '1';
                o_sum <= resize(i_a + i_b, BW_OUT);
                o_diff <= resize(i_a - i_b, BW_OUT);
            end if;
        end if;
    end process;
    --------------------
end;
