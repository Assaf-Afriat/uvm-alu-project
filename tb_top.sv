
// Top Level Testbench
// Instantiates DUT, Interface, and starts UVM.

`include "uvm_macros.svh"
// Include the package (if not compiling separately)
// Ideally, we compile the package, then import it.
// For single-file compilation flow, we might include it here or rely on file list.
`include "alu_pkg.sv"

module tb_top;
    import uvm_pkg::*;
    import alu_pkg::*;

    // Clock and Reset
    logic clk;
    logic rst_n;

    // Interface
    alu_if vif(clk, rst_n);

    // DUT Instance
    alu_dut dut (
        .clk(clk),
        .rst_n(rst_n),
        .req_valid(vif.req_valid),
        .req_ready(vif.req_ready),
        .req_op(vif.req_op),
        .req_op1(vif.req_op1),
        .req_op2(vif.req_op2),
        .resp_valid(vif.resp_valid),
        .resp_ready(vif.resp_ready),
        .resp_result(vif.resp_result)
    );

    // Clock Generation (10ns period -> 100MHz)
    initial begin
        clk = 0;
        forever #5ns clk = ~clk;
    end

    // Reset Generation
    initial begin
        rst_n = 0;
        #20ns;
        rst_n = 1;
    end

    // UVM Start
    initial begin
        // Set Virtual Interface in Config DB
        uvm_config_db#(virtual alu_if)::set(null, "*", "vif", vif);
        
        // Run Test
        // We can pass test name via +UVM_TESTNAME arg or default here
        run_test("alu_test");
    end

    // Dump Waves (Optional)
    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, tb_top);
    end

endmodule
