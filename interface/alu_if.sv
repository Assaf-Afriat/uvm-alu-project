
// UVM Interface
// Bundles signals and defines clocking blocks for driver/monitor.

interface alu_if (input logic clk, input logic rst_n);
    
    // Signals
    logic        req_valid;
    logic        req_ready;
    logic [2:0]  req_op;
    logic [7:0]  req_op1;
    logic [7:0]  req_op2;

    logic        resp_valid;
    logic        resp_ready;
    logic [15:0] resp_result;

    // Clocking blocks removed for Icarus Verilog compatibility.
    // Driver and Monitor will use @(posedge clk) directly.

    // Modports removed for Icarus compatibility
    // Drivers should use vif.drv_cb and Monitors vif.mon_cb directly.

endinterface
