`ifndef TREE_ADDER_TYP_A_V0_2_0_PKG_DEFINED
`define TREE_ADDER_TYP_A_V0_2_0_PKG_DEFINED

//! package for tree_adder_typ_a_v0_2_0
package tree_adder_typ_a_v0_2_0_pkg;
    //! Calculates the tree height based on the number of input elements.
    function automatic int unsigned calc_tree_height(
        input int unsigned N_IN_ELEMS
    );
        return $clog2(N_IN_ELEMS);
    endfunction

    //! Calculates the output bit width based on the number of input elements and the bit width of each element.
    function automatic int unsigned calc_out_bit_width(
        input int unsigned BW_IN_ELEM,
        input int unsigned N_IN_ELEMS
    );
        return (BW_IN_ELEM-1) + $clog2(N_IN_ELEMS+1) + 1;
    endfunction
endpackage

`endif // TREE_ADDER_TYP_A_V0_2_0_PKG_DEFINED
