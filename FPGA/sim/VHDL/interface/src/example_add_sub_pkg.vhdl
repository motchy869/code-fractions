library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--! a package for `example_add_sub`
package example_add_sub_pkg is
    generic (
        BW_IN: positive := 8; --! input bit width
        BW_OUT: positive := 9 --! output bit width
    );

    --! record for upstream-side interface
    type us_side_bus_t is record
        a: unresolved_signed(BW_IN-1 downto 0); --! input operand a
        b: unresolved_signed(BW_IN-1 downto 0); --! input operand b
    end record;

    --! record for downstream-side interface
    type ds_side_bus_t is record
        out_vld: std_ulogic; --! Signal indicating that the output value is valid. This is **ONLY** for initial garbage data skipping, **NOT** for flow control.
        sum: unresolved_signed(BW_OUT-1 downto 0); --! output sum
        diff: unresolved_signed(BW_OUT-1 downto 0); --! output difference
    end record;

    view us_side_master of us_side_bus_t is
        a: out;
        b: out;
    end view;

    alias us_side_slave is us_side_master'converse;

    view ds_side_master of ds_side_bus_t is
        out_vld: out;
        sum: out;
        diff: out;
    end view;

    alias ds_side_slave is ds_side_master'converse;
end;
