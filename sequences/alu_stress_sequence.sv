
// UVM Stress Sequence
// Extends base sequence with high-volume, corner-case testing.

class alu_stress_sequence extends alu_basesequence;
    `uvm_object_utils(alu_stress_sequence)

    // Configuration
    int unsigned num_transactions = 500;
    bit test_corner_cases = 1;
    bit test_back_to_back = 1;
    bit test_all_ops = 1;

    function new(string name = "alu_stress_sequence");
        super.new(name);
    endfunction

    task body();
        alu_item item;
        int phase_num = 0;

        `uvm_info("STRESS_SEQ", $sformatf("Starting Stress Sequence (%0d transactions)", num_transactions), UVM_LOW)

        // ====================================================================
        // PHASE 1: Corner Cases (boundary values)
        // ====================================================================
        if (test_corner_cases) begin
            phase_num++;
            `uvm_info("STRESS_SEQ", $sformatf("Phase %0d: Corner Cases", phase_num), UVM_LOW)

            // Test all operations with boundary values
            for (int op = 0; op < 8; op++) begin
                // Min-Min
                send_transaction(op, 8'h00, 8'h00);
                // Max-Max
                send_transaction(op, 8'hFF, 8'hFF);
                // Min-Max
                send_transaction(op, 8'h00, 8'hFF);
                // Max-Min
                send_transaction(op, 8'hFF, 8'h00);
                // One-One
                send_transaction(op, 8'h01, 8'h01);
                // Power of 2
                send_transaction(op, 8'h80, 8'h40);
            end

            // Division by zero for all operands
            for (int i = 0; i < 10; i++) begin
                item = alu_item::type_id::create("item");
                start_item(item);
                item.op = 3'b111;  // DIV
                item.op1 = $urandom_range(1, 255);
                item.op2 = 8'h00;  // Divide by zero
                finish_item(item);
            end
        end

        // ====================================================================
        // PHASE 2: Back-to-Back Same Operation
        // ====================================================================
        if (test_back_to_back) begin
            phase_num++;
            `uvm_info("STRESS_SEQ", $sformatf("Phase %0d: Back-to-Back Operations", phase_num), UVM_LOW)

            // Burst of same operation to stress pipeline
            for (int op = 0; op < 8; op++) begin
                repeat(20) begin
                    item = alu_item::type_id::create("item");
                    start_item(item);
                    if (!item.randomize() with { item.op == op; })
                        `uvm_error("STRESS_SEQ", "Randomization failed")
                    finish_item(item);
                end
            end
        end

        // ====================================================================
        // PHASE 3: Rapid Operation Switching
        // ====================================================================
        phase_num++;
        `uvm_info("STRESS_SEQ", $sformatf("Phase %0d: Rapid Operation Switching", phase_num), UVM_LOW)

        repeat(100) begin
            item = alu_item::type_id::create("item");
            start_item(item);
            if (!item.randomize())
                `uvm_error("STRESS_SEQ", "Randomization failed")
            finish_item(item);
        end

        // ====================================================================
        // PHASE 4: Long Latency Operations (MUL/DIV heavy)
        // ====================================================================
        phase_num++;
        `uvm_info("STRESS_SEQ", $sformatf("Phase %0d: Long Latency Operations (MUL/DIV)", phase_num), UVM_LOW)

        repeat(50) begin
            item = alu_item::type_id::create("item");
            start_item(item);
            if (!item.randomize() with { item.op inside {3'b010, 3'b111}; })  // MUL or DIV
                `uvm_error("STRESS_SEQ", "Randomization failed")
            finish_item(item);
        end

        // ====================================================================
        // PHASE 5: Mixed Random Transactions
        // ====================================================================
        phase_num++;
        `uvm_info("STRESS_SEQ", $sformatf("Phase %0d: Random Transactions (%0d)", phase_num, num_transactions), UVM_LOW)

        repeat(num_transactions) begin
            item = alu_item::type_id::create("item");
            start_item(item);
            if (!item.randomize())
                `uvm_error("STRESS_SEQ", "Randomization failed")
            finish_item(item);
        end

        `uvm_info("STRESS_SEQ", "Stress Sequence Complete!", UVM_LOW)
    endtask

    // Helper task to send a specific transaction
    task send_transaction(bit [2:0] op_val, bit [7:0] op1_val, bit [7:0] op2_val);
        alu_item item;
        item = alu_item::type_id::create("item");
        start_item(item);
        item.op  = op_val;
        item.op1 = op1_val;
        item.op2 = op2_val;
        finish_item(item);
    endtask

endclass
