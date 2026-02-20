
// UVM Scoreboard
// Verifies the correctness of the ALU using 2 TLM ports.
// Prints detailed comparison of expected vs actual results.
// Supports callbacks for pre_compare and post_compare hooks.

class alu_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(alu_scoreboard)
    
    // Register callback type
    `uvm_register_cb(alu_scoreboard, alu_callback_base)

    // Exports to connect to Monitor
    uvm_analysis_export #(alu_item) req_export;
    uvm_analysis_export #(alu_item) resp_export;

    // TLM FIFOs to buffer incoming transactions
    uvm_tlm_analysis_fifo #(alu_item) req_fifo;
    uvm_tlm_analysis_fifo #(alu_item) resp_fifo;

    // Statistics
    int unsigned pass_count;
    int unsigned fail_count;
    int unsigned total_count;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        // Create Ports
        req_export  = new("req_export", this);
        resp_export = new("resp_export", this);

        // Create FIFOs
        req_fifo    = new("req_fifo", this);
        resp_fifo   = new("resp_fifo", this);

        // Initialize counters
        pass_count = 0;
        fail_count = 0;
        total_count = 0;
    endfunction

    function void connect_phase(uvm_phase phase);
        // Connect Exports to FIFOs
        req_export.connect(req_fifo.analysis_export);
        resp_export.connect(resp_fifo.analysis_export);
    endfunction

    // Get operation name string
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

    task run_phase(uvm_phase phase);
        alu_item req_item;
        alu_item resp_item;
        logic [15:0] expected_result;
        string op_name;
        bit passed;

        forever begin
            // 1. Get Request from Monitor (Blocking)
            req_fifo.get(req_item);
            
            // 2. Compute Expected Result based on operands from bus
            op_name = get_op_name(req_item.op);
            
            case (req_item.op)
                3'b000: expected_result = req_item.op1 + req_item.op2;                      // ADD
                3'b001: expected_result = req_item.op1 - req_item.op2;                      // SUB
                3'b010: expected_result = req_item.op1 * req_item.op2;                      // MUL
                3'b011: expected_result = {8'b0, req_item.op1 & req_item.op2};              // AND
                3'b100: expected_result = {8'b0, req_item.op1 ^ req_item.op2};              // XOR
                3'b101: expected_result = {8'b0, req_item.op1 << req_item.op2[2:0]};        // SLL
                3'b110: expected_result = {8'b0, req_item.op1 >> req_item.op2[2:0]};        // SRL
                3'b111: begin                                                               // DIV
                    if (req_item.op2 != 0) 
                        expected_result = {8'b0, req_item.op1 / req_item.op2};
                    else 
                        expected_result = 16'hFFFF;
                end
                default: expected_result = 16'd0;
            endcase

            // 3. Get Response from Monitor (Blocking)
            resp_fifo.get(resp_item);

            // 4. Increment transaction count
            total_count++;

            // 5. Pre-compare callback - can modify expected result
            `uvm_do_callbacks(alu_scoreboard, alu_callback_base, 
                pre_compare(this, req_item, resp_item, expected_result))

            // 6. Print transaction details
            $display("============================================================");
            $display("  Transaction #%0d", total_count);
            $display("============================================================");
            $display("  OPERANDS (from Monitor/Bus):");
            $display("    Operation : %s (opcode=%0d)", op_name, req_item.op);
            $display("    Operand A : %0d (0x%02h)", req_item.op1, req_item.op1);
            $display("    Operand B : %0d (0x%02h)", req_item.op2, req_item.op2);
            $display("------------------------------------------------------------");
            $display("  RESULTS:");
            $display("    Expected  : %0d (0x%04h)", expected_result, expected_result);
            $display("    Actual    : %0d (0x%04h)", resp_item.result, resp_item.result);
            $display("------------------------------------------------------------");

            // 7. Compare and report status
            passed = (resp_item.result === expected_result);
            
            if (!passed) begin
                fail_count++;
                $display("  STATUS: *** MISMATCH ***");
                `uvm_error("SCB_FAIL", $sformatf("%s(%0d, %0d) => Expected: %0d, Got: %0d",
                    op_name, req_item.op1, req_item.op2, expected_result, resp_item.result))
            end else begin
                pass_count++;
                $display("  STATUS: PASS");
                `uvm_info("SCB_PASS", $sformatf("%s(%0d, %0d) = %0d", 
                    op_name, req_item.op1, req_item.op2, resp_item.result), UVM_MEDIUM)
            end
            $display("============================================================\n");

            // 8. Post-compare callback - notify result
            `uvm_do_callbacks(alu_scoreboard, alu_callback_base, 
                post_compare(this, req_item, resp_item, expected_result, passed))
        end
    endtask

    // Report Phase - Print Summary
    function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        
        $display("");
        $display("############################################################");
        $display("                   SCOREBOARD SUMMARY                       ");
        $display("############################################################");
        $display("  Total Transactions : %0d", total_count);
        $display("  Passed             : %0d", pass_count);
        $display("  Failed             : %0d", fail_count);
        $display("############################################################");
        $display("");

        if (fail_count > 0) begin
            `uvm_error("SCB_REPORT", $sformatf("TEST FAILED with %0d errors!", fail_count))
        end else if (total_count > 0) begin
            `uvm_info("SCB_REPORT", "TEST PASSED - All transactions matched!", UVM_NONE)
        end else begin
            `uvm_warning("SCB_REPORT", "No transactions were checked!")
        end
    endfunction

endclass
