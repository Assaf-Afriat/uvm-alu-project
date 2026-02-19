
// UVM Scoreboard
// Verifies the correctness of the ALU using 2 TLM ports.

class alu_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(alu_scoreboard)

    // Exports to connect to Monitor
    uvm_analysis_export #(alu_item) req_export;
    uvm_analysis_export #(alu_item) resp_export;

    // TLM FIFOs to buffer incoming transactions
    uvm_tlm_analysis_fifo #(alu_item) req_fifo;
    uvm_tlm_analysis_fifo #(alu_item) resp_fifo;

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
    endfunction

    function void connect_phase(uvm_phase phase);
        // Connect Exports to FIFOs
        req_export.connect(req_fifo.analysis_export);
        resp_export.connect(resp_fifo.analysis_export);
    endfunction

    task run_phase(uvm_phase phase);
        alu_item req_item;
        alu_item resp_item;
        alu_item expected_item;

        forever begin
            // 1. Get Request (Blocking)
            req_fifo.get(req_item);
            
            // 2. Compute Expected Result
            expected_item = alu_item::type_id::create("expected_item");
            expected_item.copy(req_item);
            
            case (expected_item.op)
                3'b000: expected_item.result = expected_item.op1 + expected_item.op2; // ADD
                3'b001: expected_item.result = expected_item.op1 - expected_item.op2; // SUB
                3'b010: expected_item.result = expected_item.op1 * expected_item.op2; // MUL
                3'b011: expected_item.result = {8'b0, expected_item.op1 & expected_item.op2};
                3'b100: expected_item.result = {8'b0, expected_item.op1 ^ expected_item.op2};
                3'b101: expected_item.result = {8'b0, expected_item.op1 << expected_item.op2[2:0]};
                3'b110: expected_item.result = {8'b0, expected_item.op1 >> expected_item.op2[2:0]};
                3'b111: begin // DIV
                    if (expected_item.op2 != 0) expected_item.result = {8'b0, expected_item.op1 / expected_item.op2};
                    else expected_item.result = 16'hFFFF;
                end
            endcase

            `uvm_info("SCB_PREDICT", $sformatf("Expected: %s", expected_item.convert2string()), UVM_HIGH)

            // 3. Get Response (Blocking)
            // This assumes IN ORDER execution (FIFO).
            resp_fifo.get(resp_item);

            // 4. Compare
            if (resp_item.result !== expected_item.result) begin
                `uvm_error("SCB_FAIL", $sformatf("Mismatch! Op=%0d A=%0d B=%0d | Exp=%0d Act=%0d", 
                    req_item.op, req_item.op1, req_item.op2, expected_item.result, resp_item.result));
            end else begin
                `uvm_info("SCB_PASS", $sformatf("Match! Result=%0d", resp_item.result), UVM_MEDIUM)
            end
        end
    endtask

endclass
