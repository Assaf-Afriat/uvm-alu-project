
// ALU Functional Coverage
// Tracks coverage of opcodes, operand values, and cross coverage.
// Uses two analysis exports: one for requests, one for responses.

class alu_coverage extends uvm_component;
    `uvm_component_utils(alu_coverage)

    // Analysis exports for requests and responses
    uvm_analysis_export #(alu_item) req_export;
    uvm_analysis_export #(alu_item) resp_export;

    // TLM FIFOs
    uvm_tlm_analysis_fifo #(alu_item) req_fifo;
    uvm_tlm_analysis_fifo #(alu_item) resp_fifo;

    // Sampled items
    alu_item req_item;
    alu_item resp_item;

    // ========================================================================
    // COVERGROUP: Opcode Coverage
    // ========================================================================
    covergroup cg_opcode;
        option.per_instance = 1;
        option.name = "cg_opcode";

        cp_op: coverpoint req_item.op {
            bins ADD = {3'b000};
            bins SUB = {3'b001};
            bins MUL = {3'b010};
            bins AND = {3'b011};
            bins XOR = {3'b100};
            bins SLL = {3'b101};
            bins SRL = {3'b110};
            bins DIV = {3'b111};
        }
    endgroup

    // ========================================================================
    // COVERGROUP: Operand A Coverage
    // ========================================================================
    covergroup cg_operand_a;
        option.per_instance = 1;
        option.name = "cg_operand_a";

        cp_op1: coverpoint req_item.op1 {
            bins zero        = {8'h00};
            bins one         = {8'h01};
            bins low[16]     = {[8'h02:8'h0F]};
            bins mid_low[16] = {[8'h10:8'h7F]};
            bins mid_high[16]= {[8'h80:8'hEF]};
            bins high[15]    = {[8'hF0:8'hFE]};
            bins max         = {8'hFF};
        }
    endgroup

    // ========================================================================
    // COVERGROUP: Operand B Coverage
    // ========================================================================
    covergroup cg_operand_b;
        option.per_instance = 1;
        option.name = "cg_operand_b";

        cp_op2: coverpoint req_item.op2 {
            bins zero        = {8'h00};
            bins one         = {8'h01};
            bins low[16]     = {[8'h02:8'h0F]};
            bins mid_low[16] = {[8'h10:8'h7F]};
            bins mid_high[16]= {[8'h80:8'hEF]};
            bins high[15]    = {[8'hF0:8'hFE]};
            bins max         = {8'hFF};
        }
    endgroup

    // ========================================================================
    // COVERGROUP: Corner Cases
    // ========================================================================
    covergroup cg_corner_cases;
        option.per_instance = 1;
        option.name = "cg_corner_cases";

        cp_op: coverpoint req_item.op {
            bins all_ops[] = {[0:7]};
        }

        cp_op1_corner: coverpoint req_item.op1 {
            bins zero     = {8'h00};
            bins one      = {8'h01};
            bins max      = {8'hFF};
            bins power2[] = {8'h02, 8'h04, 8'h08, 8'h10, 8'h20, 8'h40, 8'h80};
            bins others   = default;
        }

        cp_op2_corner: coverpoint req_item.op2 {
            bins zero     = {8'h00};
            bins one      = {8'h01};
            bins max      = {8'hFF};
            bins power2[] = {8'h02, 8'h04, 8'h08, 8'h10, 8'h20, 8'h40, 8'h80};
            bins others   = default;
        }

        // Cross: Each operation with corner case operands
        cx_op_x_op1: cross cp_op, cp_op1_corner;
        cx_op_x_op2: cross cp_op, cp_op2_corner;
    endgroup

    // ========================================================================
    // COVERGROUP: Shift Amount Coverage (for SLL/SRL)
    // ========================================================================
    covergroup cg_shift;
        option.per_instance = 1;
        option.name = "cg_shift";

        cp_shift_op: coverpoint req_item.op {
            bins SLL = {3'b101};
            bins SRL = {3'b110};
        }

        cp_shift_amt: coverpoint req_item.op2[2:0] {
            bins shift_0 = {3'd0};
            bins shift_1 = {3'd1};
            bins shift_2 = {3'd2};
            bins shift_3 = {3'd3};
            bins shift_4 = {3'd4};
            bins shift_5 = {3'd5};
            bins shift_6 = {3'd6};
            bins shift_7 = {3'd7};
        }

        // Cross: All shift operations with all shift amounts
        cx_shift: cross cp_shift_op, cp_shift_amt;
    endgroup

    // ========================================================================
    // COVERGROUP: Division Special Cases
    // ========================================================================
    covergroup cg_division;
        option.per_instance = 1;
        option.name = "cg_division";

        cp_is_div: coverpoint req_item.op iff (req_item.op == 3'b111) {
            bins DIV = {3'b111};
        }

        cp_divisor: coverpoint req_item.op2 iff (req_item.op == 3'b111) {
            bins div_zero     = {8'h00};
            bins div_one      = {8'h01};
            bins div_lo       = {[8'h02:8'h0F]};
            bins div_mid      = {[8'h10:8'h7F]};
            bins div_hi       = {[8'h80:8'hFF]};
        }

        cp_dividend: coverpoint req_item.op1 iff (req_item.op == 3'b111) {
            bins dnd_zero     = {8'h00};
            bins dnd_one      = {8'h01};
            bins dnd_lo       = {[8'h02:8'h0F]};
            bins dnd_mid      = {[8'h10:8'h7F]};
            bins dnd_hi       = {[8'h80:8'hFF]};
        }

        // Cross: Division with various dividend/divisor combinations
        cx_div_cases: cross cp_dividend, cp_divisor;
    endgroup

    // ========================================================================
    // COVERGROUP: Result Ranges (sampled from responses)
    // ========================================================================
    covergroup cg_result;
        option.per_instance = 1;
        option.name = "cg_result";

        cp_result: coverpoint resp_item.result {
            bins res_zero           = {16'h0000};
            bins res_lo[16]         = {[16'h0001:16'h00FF]};
            bins res_mid[16]        = {[16'h0100:16'h0FFF]};
            bins res_hi[16]         = {[16'h1000:16'hFFFE]};
            bins res_max            = {16'hFFFF};
        }
    endgroup

    // ========================================================================
    // COVERGROUP: Full Cross (Operation x Operand Ranges)
    // ========================================================================
    covergroup cg_full_cross;
        option.per_instance = 1;
        option.name = "cg_full_cross";

        cp_op: coverpoint req_item.op {
            bins ops[] = {[0:7]};
        }

        cp_op1_range: coverpoint req_item.op1 {
            bins low  = {[8'h00:8'h3F]};
            bins mid  = {[8'h40:8'hBF]};
            bins high = {[8'hC0:8'hFF]};
        }

        cp_op2_range: coverpoint req_item.op2 {
            bins low  = {[8'h00:8'h3F]};
            bins mid  = {[8'h40:8'hBF]};
            bins high = {[8'hC0:8'hFF]};
        }

        // Cross: All ops with all operand ranges (8 x 3 x 3 = 72 bins)
        cx_full: cross cp_op, cp_op1_range, cp_op2_range;
    endgroup

    // ========================================================================
    // Constructor
    // ========================================================================
    function new(string name, uvm_component parent);
        super.new(name, parent);
        cg_opcode       = new();
        cg_operand_a    = new();
        cg_operand_b    = new();
        cg_corner_cases = new();
        cg_shift        = new();
        cg_division     = new();
        cg_result       = new();
        cg_full_cross   = new();
    endfunction

    // ========================================================================
    // Build Phase
    // ========================================================================
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        req_export  = new("req_export", this);
        resp_export = new("resp_export", this);
        req_fifo    = new("req_fifo", this);
        resp_fifo   = new("resp_fifo", this);
    endfunction

    // ========================================================================
    // Connect Phase
    // ========================================================================
    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        req_export.connect(req_fifo.analysis_export);
        resp_export.connect(resp_fifo.analysis_export);
    endfunction

    // ========================================================================
    // Run Phase - Sample coverage from both FIFOs
    // ========================================================================
    task run_phase(uvm_phase phase);
        fork
            sample_requests();
            sample_responses();
        join
    endtask

    task sample_requests();
        forever begin
            req_fifo.get(req_item);
            
            // Sample request covergroups
            cg_opcode.sample();
            cg_operand_a.sample();
            cg_operand_b.sample();
            cg_corner_cases.sample();
            cg_shift.sample();
            cg_division.sample();
            cg_full_cross.sample();
        end
    endtask

    task sample_responses();
        forever begin
            resp_fifo.get(resp_item);
            
            // Sample result covergroup
            cg_result.sample();
        end
    endtask

    // ========================================================================
    // Report Phase - Print coverage summary
    // ========================================================================
    function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        
        $display("");
        $display("############################################################");
        $display("              FUNCTIONAL COVERAGE REPORT                    ");
        $display("############################################################");
        $display("  Opcode Coverage       : %.2f%%", cg_opcode.get_coverage());
        $display("  Operand A Coverage    : %.2f%%", cg_operand_a.get_coverage());
        $display("  Operand B Coverage    : %.2f%%", cg_operand_b.get_coverage());
        $display("  Corner Cases Coverage : %.2f%%", cg_corner_cases.get_coverage());
        $display("  Shift Coverage        : %.2f%%", cg_shift.get_coverage());
        $display("  Division Coverage     : %.2f%%", cg_division.get_coverage());
        $display("  Result Coverage       : %.2f%%", cg_result.get_coverage());
        $display("  Full Cross Coverage   : %.2f%%", cg_full_cross.get_coverage());
        $display("############################################################");
        $display("");
    endfunction

endclass
