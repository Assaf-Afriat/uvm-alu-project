
// ALU Monitor Callbacks
// Implementations for monitor callback hooks.

// ============================================================================
// TRANSACTION STATISTICS CALLBACK - Tracks operation statistics
// ============================================================================
class alu_stats_cb extends alu_callback_base;
    `uvm_object_utils(alu_stats_cb)

    // Per-operation counters
    int unsigned op_count[8];
    int unsigned total_requests = 0;
    int unsigned total_responses = 0;
    
    // Latency tracking
    realtime req_times[$];
    real total_latency = 0;
    real min_latency = 1e9;
    real max_latency = 0;

    function new(string name = "alu_stats_cb");
        super.new(name);
        foreach (op_count[i]) op_count[i] = 0;
    endfunction

    virtual function void post_req_capture(uvm_component mon, alu_item item, ref bit drop);
        total_requests++;
        op_count[item.op]++;
        req_times.push_back($realtime);
        
        `uvm_info("STATS_CB", $sformatf("REQ #%0d: op=%s", 
            total_requests, get_op_name(item.op)), UVM_HIGH)
    endfunction

    virtual function void post_resp_capture(uvm_component mon, alu_item item, ref bit drop);
        real latency;
        realtime req_time;
        
        total_responses++;
        
        // Calculate latency if we have pending requests
        if (req_times.size() > 0) begin
            req_time = req_times.pop_front();
            latency = $realtime - req_time;
            total_latency += latency;
            if (latency < min_latency) min_latency = latency;
            if (latency > max_latency) max_latency = latency;
        end
        
        `uvm_info("STATS_CB", $sformatf("RESP #%0d: result=%0d", 
            total_responses, item.result), UVM_HIGH)
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

    // Call this to print statistics
    function void print_stats();
        $display("");
        $display("############################################################");
        $display("              TRANSACTION STATISTICS                        ");
        $display("############################################################");
        $display("  Total Requests  : %0d", total_requests);
        $display("  Total Responses : %0d", total_responses);
        $display("");
        $display("  Operations Breakdown:");
        $display("    ADD : %0d (%.1f%%)", op_count[0], get_pct(op_count[0]));
        $display("    SUB : %0d (%.1f%%)", op_count[1], get_pct(op_count[1]));
        $display("    MUL : %0d (%.1f%%)", op_count[2], get_pct(op_count[2]));
        $display("    AND : %0d (%.1f%%)", op_count[3], get_pct(op_count[3]));
        $display("    XOR : %0d (%.1f%%)", op_count[4], get_pct(op_count[4]));
        $display("    SLL : %0d (%.1f%%)", op_count[5], get_pct(op_count[5]));
        $display("    SRL : %0d (%.1f%%)", op_count[6], get_pct(op_count[6]));
        $display("    DIV : %0d (%.1f%%)", op_count[7], get_pct(op_count[7]));
        $display("");
        if (total_responses > 0) begin
            $display("  Latency (ns):");
            $display("    Min : %.2f", min_latency);
            $display("    Max : %.2f", max_latency);
            $display("    Avg : %.2f", total_latency / total_responses);
        end
        $display("############################################################");
        $display("");
    endfunction

    function real get_pct(int count);
        if (total_requests == 0) return 0;
        return real'(count) / real'(total_requests) * 100;
    endfunction
endclass

// ============================================================================
// PROTOCOL CHECKER CALLBACK - Checks protocol violations
// ============================================================================
class alu_protocol_check_cb extends alu_callback_base;
    `uvm_object_utils(alu_protocol_check_cb)

    // Track state
    bit last_req_valid = 0;
    bit last_resp_valid = 0;
    int unsigned protocol_errors = 0;

    function new(string name = "alu_protocol_check_cb");
        super.new(name);
    endfunction

    virtual function void post_req_capture(uvm_component mon, alu_item item, ref bit drop);
        // Check for valid transaction
        if (item.op > 7) begin
            protocol_errors++;
            `uvm_error("PROTO_CB", $sformatf("Invalid opcode: %0d", item.op))
        end
    endfunction

    virtual function void post_resp_capture(uvm_component mon, alu_item item, ref bit drop);
        // Response validation could go here
    endfunction
endclass

// ============================================================================
// FILTER CALLBACK - Filters specific transactions
// ============================================================================
class alu_filter_cb extends alu_callback_base;
    `uvm_object_utils(alu_filter_cb)

    // Filter configuration
    bit filter_div = 0;        // Drop DIV operations
    bit filter_zero_ops = 0;   // Drop operations with zero operands
    int unsigned filtered = 0;

    function new(string name = "alu_filter_cb");
        super.new(name);
    endfunction

    virtual function void post_req_capture(uvm_component mon, alu_item item, ref bit drop);
        if (filter_div && item.op == 3'b111) begin
            drop = 1;
            filtered++;
            `uvm_info("FILTER_CB", "Filtering DIV operation", UVM_HIGH)
        end
        
        if (filter_zero_ops && (item.op1 == 0 || item.op2 == 0)) begin
            drop = 1;
            filtered++;
            `uvm_info("FILTER_CB", "Filtering zero operand operation", UVM_HIGH)
        end
    endfunction
endclass
