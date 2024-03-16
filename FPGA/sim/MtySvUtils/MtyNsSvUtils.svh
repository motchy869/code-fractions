/* motchy Non-Synthesizable SystemVerilog utilities */
package MtyNsSvUtils;
    /* ## description
     *
     * Schedule a blocking assignment with delay.
     *
     * ## usage
     *
     * ```sv
     * localparam int CLK_PERIOD_NS = 8;
     * var bit a;
     * ScheduleBlkAsg#(bit)::main(a, 1'b0, 2*CLK_PERIOD_NS);
     * ```
     */
    class ScheduleBlkAsg#(type T);
        local static task automatic inner_task(ref T x, input T val, input realtime delay);
            #delay x = val;
        endtask

        static function main(ref T x, input T val, input realtime delay);
            fork inner_task(x, val, delay); join_none
        endfunction
    endclass
endpackage
