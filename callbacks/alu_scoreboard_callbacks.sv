
// ALU Scoreboard Callbacks
// Implementations for scoreboard callback hooks.

// ============================================================================
// COMPARISON LOGGER CALLBACK - Detailed logging of comparisons
// ============================================================================
class alu_compare_log_cb extends alu_callback_base;
    `uvm_object_utils(alu_compare_log_cb)

    int unsigned pass_count = 0;
    int unsigned fail_count = 0;
    bit log_passes = 1;
    bit log_fails = 1;

    function new(string name = "alu_compare_log_cb");
        super.new(name);
    endfunction

    virtual function void pre_compare(uvm_component scb, alu_item req, alu_item resp,
                                       ref logic [15:0] expected_result);
        `uvm_info("SCB_CB", $sformatf("PRE_COMPARE: op=%0d(%0d,%0d) expected=%0d actual=%0d",
            req.op, req.op1, req.op2, expected_result, resp.result), UVM_HIGH)
    endfunction

    virtual function void post_compare(uvm_component scb, alu_item req, alu_item resp,
                                        logic [15:0] expected_result, bit passed);
        if (passed) begin
            pass_count++;
            if (log_passes) begin
                `uvm_info("SCB_CB", $sformatf("PASS: %s(%0d,%0d) = %0d",
                    get_op_name(req.op), req.op1, req.op2, resp.result), UVM_HIGH)
            end
        end else begin
            fail_count++;
            if (log_fails) begin
                `uvm_error("SCB_CB", $sformatf("FAIL: %s(%0d,%0d) expected=%0d got=%0d",
                    get_op_name(req.op), req.op1, req.op2, expected_result, resp.result))
            end
        end
    endfunction

    function string get_op_name(bit [2:0] op);
        case (op)
            3'b000: return "ADD";
            3'b001: return "SUB";
            3'b010: return "MUL";
            3'b011: return "AND";
            3'b100: return "XOR";
            3'b101: return "SLL";
            3'b110: return "SRL";
            3'b111: return "DIV";
            default: return "???";
        endcase
    endfunction

    function void print_summary();
        $display("");
        $display("############################################################");
        $display("           SCOREBOARD CALLBACK SUMMARY                      ");
        $display("############################################################");
        $display("  Passed : %0d", pass_count);
        $display("  Failed : %0d", fail_count);
        $display("  Total  : %0d", pass_count + fail_count);
        $display("############################################################");
        $display("");
    endfunction
endclass

// ============================================================================
// ERROR INJECTION DETECTION CALLBACK - Detects injected errors
// ============================================================================
class alu_error_detect_cb extends alu_callback_base;
    `uvm_object_utils(alu_error_detect_cb)

    // Track expected errors (from error injection)
    int unsigned expected_errors = 0;
    int unsigned detected_errors = 0;
    bit suppress_expected_errors = 0;

    function new(string name = "alu_error_detect_cb");
        super.new(name);
    endfunction

    virtual function void post_compare(uvm_component scb, alu_item req, alu_item resp,
                                        logic [15:0] expected_result, bit passed);
        if (!passed) begin
            detected_errors++;
            if (suppress_expected_errors && detected_errors <= expected_errors) begin
                `uvm_info("ERR_DET", $sformatf("Expected error detected (%0d/%0d)",
                    detected_errors, expected_errors), UVM_MEDIUM)
            end
        end
    endfunction
endclass

// ============================================================================
// RESULT MODIFIER CALLBACK - Modifies expected result (for testing)
// ============================================================================
class alu_result_modifier_cb extends alu_callback_base;
    `uvm_object_utils(alu_result_modifier_cb)

    // Configuration
    bit enable_modification = 0;
    int unsigned modify_rate = 5;  // Percentage
    int unsigned modified_count = 0;

    function new(string name = "alu_result_modifier_cb");
        super.new(name);
    endfunction

    virtual function void pre_compare(uvm_component scb, alu_item req, alu_item resp,
                                       ref logic [15:0] expected_result);
        if (enable_modification && $urandom_range(0, 99) < modify_rate) begin
            modified_count++;
            `uvm_info("MOD_CB", $sformatf("Modifying expected: %0d -> %0d",
                expected_result, expected_result + 1), UVM_MEDIUM)
            expected_result = expected_result + 1;  // Force mismatch
        end
    endfunction
endclass

// ============================================================================
// OPERATION TRACKER CALLBACK - Tracks pass/fail per operation type
// ============================================================================
class alu_op_tracker_cb extends alu_callback_base;
    `uvm_object_utils(alu_op_tracker_cb)

    int unsigned op_pass[8];
    int unsigned op_fail[8];

    function new(string name = "alu_op_tracker_cb");
        super.new(name);
        foreach (op_pass[i]) begin
            op_pass[i] = 0;
            op_fail[i] = 0;
        end
    endfunction

    virtual function void post_compare(uvm_component scb, alu_item req, alu_item resp,
                                        logic [15:0] expected_result, bit passed);
        if (passed)
            op_pass[req.op]++;
        else
            op_fail[req.op]++;
    endfunction

    function void print_stats();
        string op_names[8] = '{"ADD", "SUB", "MUL", "AND", "XOR", "SLL", "SRL", "DIV"};
        
        $display("");
        $display("############################################################");
        $display("           PER-OPERATION PASS/FAIL STATS                    ");
        $display("############################################################");
        $display("  +------+--------+--------+--------+");
        $display("  |  OP  |  PASS  |  FAIL  | TOTAL  |");
        $display("  +------+--------+--------+--------+");
        for (int i = 0; i < 8; i++) begin
            $display("  | %s |  %5d |  %5d |  %5d |",
                op_names[i], op_pass[i], op_fail[i], op_pass[i] + op_fail[i]);
        end
        $display("  +------+--------+--------+--------+");
        $display("############################################################");
        $display("");
    endfunction
endclass
