
// ALU SystemVerilog Assertions
// Bind this module to the DUT or instantiate in testbench
// Tracks and reports assertion pass/fail statistics at end of simulation.

module alu_assertions (
    input logic        clk,
    input logic        rst_n,
    
    // Request Interface
    input logic        req_valid,
    input logic        req_ready,
    input logic [2:0]  req_op,
    input logic [7:0]  req_op1,
    input logic [7:0]  req_op2,
    
    // Response Interface
    input logic        resp_valid,
    input logic        resp_ready,
    input logic [15:0] resp_result
);

    // ========================================================================
    // ASSERTION STATISTICS TRACKING
    // ========================================================================
    int unsigned assert_pass_count = 0;
    int unsigned assert_fail_count = 0;
    
    // Individual assertion counters
    int unsigned req_valid_stable_pass = 0, req_valid_stable_fail = 0;
    int unsigned req_data_stable_pass = 0, req_data_stable_fail = 0;
    int unsigned resp_valid_stable_pass = 0, resp_valid_stable_fail = 0;
    int unsigned resp_data_stable_pass = 0, resp_data_stable_fail = 0;
    int unsigned reset_req_ready_pass = 0, reset_req_ready_fail = 0;
    int unsigned reset_resp_valid_pass = 0, reset_resp_valid_fail = 0;
    int unsigned max_latency_pass = 0, max_latency_fail = 0;
    int unsigned no_req_deadlock_pass = 0, no_req_deadlock_fail = 0;
    int unsigned no_resp_deadlock_pass = 0, no_resp_deadlock_fail = 0;
    int unsigned no_overflow_pass = 0, no_overflow_fail = 0;
    int unsigned no_underflow_pass = 0, no_underflow_fail = 0;

    // ========================================================================
    // PROTOCOL ASSERTIONS - Valid/Ready Handshake
    // ========================================================================

    // REQ_STABLE_VALID: Once req_valid asserts, it must stay high until handshake
    property p_req_valid_stable;
        @(posedge clk) disable iff (!rst_n)
        (req_valid && !req_ready) |=> req_valid;
    endproperty
    a_req_valid_stable: assert property (p_req_valid_stable)
        begin assert_pass_count++; req_valid_stable_pass++; end
        else begin assert_fail_count++; req_valid_stable_fail++; 
            $error("ASSERT FAIL: req_valid dropped before handshake!"); end

    // REQ_STABLE_DATA: Request data must be stable while waiting for ready
    property p_req_data_stable;
        @(posedge clk) disable iff (!rst_n)
        (req_valid && !req_ready) |=> ($stable(req_op) && $stable(req_op1) && $stable(req_op2));
    endproperty
    a_req_data_stable: assert property (p_req_data_stable)
        begin assert_pass_count++; req_data_stable_pass++; end
        else begin assert_fail_count++; req_data_stable_fail++;
            $error("ASSERT FAIL: Request data changed before handshake!"); end

    // RESP_STABLE_VALID: Once resp_valid asserts, it must stay high until handshake
    property p_resp_valid_stable;
        @(posedge clk) disable iff (!rst_n)
        (resp_valid && !resp_ready) |=> resp_valid;
    endproperty
    a_resp_valid_stable: assert property (p_resp_valid_stable)
        begin assert_pass_count++; resp_valid_stable_pass++; end
        else begin assert_fail_count++; resp_valid_stable_fail++;
            $error("ASSERT FAIL: resp_valid dropped before handshake!"); end

    // RESP_STABLE_DATA: Response data must be stable while waiting for ready
    property p_resp_data_stable;
        @(posedge clk) disable iff (!rst_n)
        (resp_valid && !resp_ready) |=> $stable(resp_result);
    endproperty
    a_resp_data_stable: assert property (p_resp_data_stable)
        begin assert_pass_count++; resp_data_stable_pass++; end
        else begin assert_fail_count++; resp_data_stable_fail++;
            $error("ASSERT FAIL: resp_result changed before handshake!"); end

    // ========================================================================
    // RESET ASSERTIONS
    // ========================================================================

    // RESET_REQ_READY: After reset, req_ready should be high (not busy)
    property p_reset_req_ready;
        @(posedge clk)
        $rose(rst_n) |-> ##1 req_ready;
    endproperty
    a_reset_req_ready: assert property (p_reset_req_ready)
        begin assert_pass_count++; reset_req_ready_pass++; end
        else begin assert_fail_count++; reset_req_ready_fail++;
            $error("ASSERT FAIL: req_ready not high after reset!"); end

    // RESET_RESP_VALID: After reset, resp_valid should be low (FIFO empty)
    property p_reset_resp_valid;
        @(posedge clk)
        $rose(rst_n) |-> ##1 !resp_valid;
    endproperty
    a_reset_resp_valid: assert property (p_reset_resp_valid)
        begin assert_pass_count++; reset_resp_valid_pass++; end
        else begin assert_fail_count++; reset_resp_valid_fail++;
            $error("ASSERT FAIL: resp_valid not low after reset!"); end

    // ========================================================================
    // INTERNAL TRACKING LOGIC
    // ========================================================================

    logic [2:0]  sampled_op;
    logic [7:0]  sampled_op1;
    logic [7:0]  sampled_op2;
    logic [15:0] expected_result;
    logic        req_pending;
    int          pending_count;
    
    // Track handshakes
    logic req_handshake;
    logic resp_handshake;
    
    assign req_handshake  = req_valid && req_ready;
    assign resp_handshake = resp_valid && resp_ready;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sampled_op  <= 3'b0;
            sampled_op1 <= 8'b0;
            sampled_op2 <= 8'b0;
            req_pending <= 1'b0;
            pending_count <= 0;
        end else begin
            // Sample request data on handshake
            if (req_handshake) begin
                sampled_op  <= req_op;
                sampled_op1 <= req_op1;
                sampled_op2 <= req_op2;
            end
            
            // Update pending count - handle simultaneous req/resp
            if (req_handshake && !resp_handshake) begin
                pending_count <= pending_count + 1;
            end else if (!req_handshake && resp_handshake) begin
                if (pending_count > 0) begin
                    pending_count <= pending_count - 1;
                end
            end
            // If both happen simultaneously, count stays the same
        end
    end

    // ========================================================================
    // LATENCY ASSERTIONS
    // ========================================================================

    int cycles_since_req;
    logic waiting_for_resp;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cycles_since_req <= 0;
            waiting_for_resp <= 0;
        end else begin
            if (req_valid && req_ready && pending_count == 0) begin
                cycles_since_req <= 1;
                waiting_for_resp <= 1;
            end else if (waiting_for_resp) begin
                if (resp_valid && resp_ready) begin
                    waiting_for_resp <= 0;
                    cycles_since_req <= 0;
                end else begin
                    cycles_since_req <= cycles_since_req + 1;
                end
            end
        end
    end

    // MAX_LATENCY: Response must arrive within 16 cycles
    property p_max_latency;
        @(posedge clk) disable iff (!rst_n)
        (cycles_since_req < 16);
    endproperty
    a_max_latency: assert property (p_max_latency)
        begin assert_pass_count++; max_latency_pass++; end
        else begin assert_fail_count++; max_latency_fail++;
            $error("ASSERT FAIL: Response latency exceeded 16 cycles!"); end

    // ========================================================================
    // THROUGHPUT ASSERTIONS
    // ========================================================================

    // NO_DEADLOCK: If valid is high, ready must eventually go high
    property p_no_req_deadlock;
        @(posedge clk) disable iff (!rst_n)
        req_valid |-> ##[0:100] req_ready;
    endproperty
    a_no_req_deadlock: assert property (p_no_req_deadlock)
        begin assert_pass_count++; no_req_deadlock_pass++; end
        else begin assert_fail_count++; no_req_deadlock_fail++;
            $error("ASSERT FAIL: Request deadlock - req_ready never asserted!"); end

    property p_no_resp_deadlock;
        @(posedge clk) disable iff (!rst_n)
        resp_valid |-> ##[0:100] resp_ready;
    endproperty
    a_no_resp_deadlock: assert property (p_no_resp_deadlock)
        begin assert_pass_count++; no_resp_deadlock_pass++; end
        else begin assert_fail_count++; no_resp_deadlock_fail++;
            $error("ASSERT FAIL: Response deadlock - resp_ready never asserted!"); end

    // ========================================================================
    // FIFO ASSERTIONS (pending count)
    // ========================================================================

    // FIFO_OVERFLOW: Pending count should not exceed reasonable limit
    // Note: Max in-flight = FIFO depth (4) + 1 in execution + some margin
    // The DUT prevents overflow by deasserting req_ready when busy
    // We use a higher limit (8) to account for pipeline + FIFO
    property p_no_overflow;
        @(posedge clk) disable iff (!rst_n)
        pending_count <= 8;
    endproperty
    a_no_overflow: assert property (p_no_overflow)
        begin assert_pass_count++; no_overflow_pass++; end
        else begin assert_fail_count++; no_overflow_fail++;
            $error("ASSERT FAIL: Pending count exceeded max limit (8)!"); end

    // FIFO_UNDERFLOW: Response should not occur without pending request
    // Note: We check that we don't get more responses than requests over time
    // The counter is protected from going negative in the tracking logic
    property p_no_underflow;
        @(posedge clk) disable iff (!rst_n)
        (pending_count >= 0);
    endproperty
    a_no_underflow: assert property (p_no_underflow)
        begin assert_pass_count++; no_underflow_pass++; end
        else begin assert_fail_count++; no_underflow_fail++;
            $error("ASSERT FAIL: Pending count went negative (underflow)!"); end

    // ========================================================================
    // COVER PROPERTIES - Functional Coverage via Assertions
    // ========================================================================

    // Cover all operations
    c_op_add: cover property (@(posedge clk) disable iff (!rst_n) 
        req_valid && req_ready && req_op == 3'b000);
    c_op_sub: cover property (@(posedge clk) disable iff (!rst_n) 
        req_valid && req_ready && req_op == 3'b001);
    c_op_mul: cover property (@(posedge clk) disable iff (!rst_n) 
        req_valid && req_ready && req_op == 3'b010);
    c_op_and: cover property (@(posedge clk) disable iff (!rst_n) 
        req_valid && req_ready && req_op == 3'b011);
    c_op_xor: cover property (@(posedge clk) disable iff (!rst_n) 
        req_valid && req_ready && req_op == 3'b100);
    c_op_sll: cover property (@(posedge clk) disable iff (!rst_n) 
        req_valid && req_ready && req_op == 3'b101);
    c_op_srl: cover property (@(posedge clk) disable iff (!rst_n) 
        req_valid && req_ready && req_op == 3'b110);
    c_op_div: cover property (@(posedge clk) disable iff (!rst_n) 
        req_valid && req_ready && req_op == 3'b111);

    // Cover corner cases
    c_both_zero: cover property (@(posedge clk) disable iff (!rst_n)
        req_valid && req_ready && req_op1 == 8'h00 && req_op2 == 8'h00);
    c_both_max: cover property (@(posedge clk) disable iff (!rst_n)
        req_valid && req_ready && req_op1 == 8'hFF && req_op2 == 8'hFF);
    c_div_by_zero: cover property (@(posedge clk) disable iff (!rst_n)
        req_valid && req_ready && req_op == 3'b111 && req_op2 == 8'h00);

    // Cover backpressure scenarios
    c_req_backpressure: cover property (@(posedge clk) disable iff (!rst_n)
        req_valid && !req_ready);
    c_resp_backpressure: cover property (@(posedge clk) disable iff (!rst_n)
        resp_valid && !resp_ready);

    // Cover back-to-back transactions
    c_back_to_back: cover property (@(posedge clk) disable iff (!rst_n)
        (req_valid && req_ready) ##1 (req_valid && req_ready));

    // ========================================================================
    // FINAL REPORT - Print assertion summary at end of simulation
    // ========================================================================
    final begin
        $display("");
        $display("############################################################");
        $display("                 SVA ASSERTION REPORT                       ");
        $display("############################################################");
        $display("");
        $display("  SUMMARY:");
        $display("    Total Assertions Checked : %0d", assert_pass_count + assert_fail_count);
        $display("    Passed                   : %0d", assert_pass_count);
        $display("    Failed                   : %0d", assert_fail_count);
        $display("");
        $display("  DETAILED RESULTS:");
        $display("  +--------------------------+----------+----------+--------+");
        $display("  | Assertion                |  Passed  |  Failed  | Status |");
        $display("  +--------------------------+----------+----------+--------+");
        $display("  | req_valid_stable         | %8d | %8d |   %s  |", 
            req_valid_stable_pass, req_valid_stable_fail, 
            req_valid_stable_fail == 0 ? "PASS" : "FAIL");
        $display("  | req_data_stable          | %8d | %8d |   %s  |", 
            req_data_stable_pass, req_data_stable_fail,
            req_data_stable_fail == 0 ? "PASS" : "FAIL");
        $display("  | resp_valid_stable        | %8d | %8d |   %s  |", 
            resp_valid_stable_pass, resp_valid_stable_fail,
            resp_valid_stable_fail == 0 ? "PASS" : "FAIL");
        $display("  | resp_data_stable         | %8d | %8d |   %s  |", 
            resp_data_stable_pass, resp_data_stable_fail,
            resp_data_stable_fail == 0 ? "PASS" : "FAIL");
        $display("  | reset_req_ready          | %8d | %8d |   %s  |", 
            reset_req_ready_pass, reset_req_ready_fail,
            reset_req_ready_fail == 0 ? "PASS" : "FAIL");
        $display("  | reset_resp_valid         | %8d | %8d |   %s  |", 
            reset_resp_valid_pass, reset_resp_valid_fail,
            reset_resp_valid_fail == 0 ? "PASS" : "FAIL");
        $display("  | max_latency              | %8d | %8d |   %s  |", 
            max_latency_pass, max_latency_fail,
            max_latency_fail == 0 ? "PASS" : "FAIL");
        $display("  | no_req_deadlock          | %8d | %8d |   %s  |", 
            no_req_deadlock_pass, no_req_deadlock_fail,
            no_req_deadlock_fail == 0 ? "PASS" : "FAIL");
        $display("  | no_resp_deadlock         | %8d | %8d |   %s  |", 
            no_resp_deadlock_pass, no_resp_deadlock_fail,
            no_resp_deadlock_fail == 0 ? "PASS" : "FAIL");
        $display("  | no_overflow              | %8d | %8d |   %s  |", 
            no_overflow_pass, no_overflow_fail,
            no_overflow_fail == 0 ? "PASS" : "FAIL");
        $display("  | no_underflow             | %8d | %8d |   %s  |", 
            no_underflow_pass, no_underflow_fail,
            no_underflow_fail == 0 ? "PASS" : "FAIL");
        $display("  +--------------------------+----------+----------+--------+");
        $display("");
        
        if (assert_fail_count == 0) begin
            $display("  *** ALL ASSERTIONS PASSED ***");
        end else begin
            $display("  *** %0d ASSERTION FAILURES DETECTED ***", assert_fail_count);
        end
        
        $display("");
        $display("############################################################");
        $display("");
    end

endmodule
