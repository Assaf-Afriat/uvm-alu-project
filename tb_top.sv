
// Top Level Testbench
// Instantiates DUT, Interface, Assertions, and starts UVM.
// Includes random backpressure generation on response interface.

`include "uvm_macros.svh"
`include "alu_pkg.sv"

module tb_top;
    import uvm_pkg::*;
    import alu_pkg::*;

    // Clock and Reset
    logic clk;
    logic rst_n;

    // Interface
    alu_if vif(clk, rst_n);

    // ========================================================================
    // BACKPRESSURE CONFIGURATION
    // ========================================================================
    // Control backpressure behavior via plusargs:
    //   +BACKPRESSURE_EN=1     : Enable random backpressure (default: 1)
    //   +BACKPRESSURE_PCT=30   : Percentage of cycles with backpressure (default: 30)
    // ========================================================================
    
    int backpressure_en = 1;      // Enable backpressure (1=on, 0=off)
    int backpressure_pct = 30;    // Percentage of cycles to apply backpressure (0-100)
    
    // Internal signals for backpressure
    logic resp_ready_internal;
    logic backpressure_active;
    int   rand_val;

    // Read plusargs for configuration
    initial begin
        if ($value$plusargs("BACKPRESSURE_EN=%d", backpressure_en)) begin
            $display("[TB_TOP] Backpressure Enable: %0d", backpressure_en);
        end
        if ($value$plusargs("BACKPRESSURE_PCT=%d", backpressure_pct)) begin
            $display("[TB_TOP] Backpressure Percentage: %0d%%", backpressure_pct);
        end
        
        if (backpressure_en) begin
            $display("[TB_TOP] Random backpressure ENABLED (%0d%% of cycles)", backpressure_pct);
        end else begin
            $display("[TB_TOP] Random backpressure DISABLED");
        end
    end

    // Random backpressure generation
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            backpressure_active <= 1'b0;
            resp_ready_internal <= 1'b1;
        end else begin
            if (backpressure_en) begin
                // Generate random value 0-99
                rand_val = $urandom_range(0, 99);
                
                // Apply backpressure based on percentage
                if (rand_val < backpressure_pct) begin
                    backpressure_active <= 1'b1;
                    resp_ready_internal <= 1'b0;
                end else begin
                    backpressure_active <= 1'b0;
                    resp_ready_internal <= 1'b1;
                end
            end else begin
                backpressure_active <= 1'b0;
                resp_ready_internal <= 1'b1;
            end
        end
    end

    // Connect backpressure to interface
    assign vif.resp_ready = resp_ready_internal;

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

    // SVA Assertions Instance
    alu_assertions u_assertions (
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
        run_test("alu_test");
    end

    // Dump Waves (Optional - for VCD format)
    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, tb_top);
    end

    // ========================================================================
    // BACKPRESSURE STATISTICS
    // ========================================================================
    int unsigned bp_cycles = 0;
    int unsigned total_cycles = 0;
    
    always_ff @(posedge clk) begin
        if (rst_n) begin
            total_cycles <= total_cycles + 1;
            if (backpressure_active) begin
                bp_cycles <= bp_cycles + 1;
            end
        end
    end

    final begin
        $display("");
        $display("############################################################");
        $display("                 BACKPRESSURE STATISTICS                    ");
        $display("############################################################");
        $display("  Backpressure Enabled   : %s", backpressure_en ? "YES" : "NO");
        $display("  Target Percentage      : %0d%%", backpressure_pct);
        $display("  Total Cycles           : %0d", total_cycles);
        $display("  Backpressure Cycles    : %0d", bp_cycles);
        if (total_cycles > 0) begin
            $display("  Actual Percentage      : %.2f%%", (real'(bp_cycles) / real'(total_cycles)) * 100.0);
        end
        $display("############################################################");
        $display("");
    end

endmodule
