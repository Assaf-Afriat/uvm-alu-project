
// UVM Coverage-Driven Sequence
// Systematically targets all coverage bins to achieve 100% functional coverage.

class alu_coverage_sequence extends alu_basesequence;
    `uvm_object_utils(alu_coverage_sequence)

    function new(string name = "alu_coverage_sequence");
        super.new(name);
    endfunction

    task body();
        `uvm_info("COV_SEQ", "Starting Coverage-Driven Sequence", UVM_LOW)

        // ====================================================================
        // PHASE 1: All Operations x All Corner Case Operands
        // Targets: cg_corner_cases cross coverage
        // ====================================================================
        `uvm_info("COV_SEQ", "Phase 1: Operations x Corner Cases", UVM_LOW)
        
        // Corner values for operands
        begin
            bit [7:0] corner_vals[] = '{8'h00, 8'h01, 8'hFF, 8'h02, 8'h04, 8'h08, 8'h10, 8'h20, 8'h40, 8'h80};
            
            // For each operation
            for (int op = 0; op < 8; op++) begin
                // For each corner value combination
                foreach (corner_vals[i]) begin
                    foreach (corner_vals[j]) begin
                        send_transaction(op[2:0], corner_vals[i], corner_vals[j]);
                    end
                end
            end
        end

        // ====================================================================
        // PHASE 2: Division Coverage - All dividend/divisor combinations
        // Targets: cg_division cross coverage
        // ====================================================================
        `uvm_info("COV_SEQ", "Phase 2: Division Coverage", UVM_LOW)
        
        begin
            // Division ranges: zero, one, small(2-15), medium(16-127), large(128-255)
            bit [7:0] div_vals[] = '{8'h00, 8'h01, 8'h05, 8'h0A, 8'h20, 8'h50, 8'h80, 8'hC0, 8'hFF};
            
            foreach (div_vals[i]) begin
                foreach (div_vals[j]) begin
                    send_transaction(3'b111, div_vals[i], div_vals[j]);  // DIV operation
                end
            end
        end

        // ====================================================================
        // PHASE 3: Shift Coverage - All shift amounts
        // Targets: cg_shift cross coverage
        // ====================================================================
        `uvm_info("COV_SEQ", "Phase 3: Shift Coverage", UVM_LOW)
        
        // SLL (opcode 5) with all shift amounts 0-7
        for (int shift = 0; shift < 8; shift++) begin
            send_transaction(3'b101, 8'hAA, shift[7:0]);  // SLL
            send_transaction(3'b101, 8'h55, shift[7:0]);
            send_transaction(3'b101, 8'hFF, shift[7:0]);
            send_transaction(3'b101, 8'h01, shift[7:0]);
        end
        
        // SRL (opcode 6) with all shift amounts 0-7
        for (int shift = 0; shift < 8; shift++) begin
            send_transaction(3'b110, 8'hAA, shift[7:0]);  // SRL
            send_transaction(3'b110, 8'h55, shift[7:0]);
            send_transaction(3'b110, 8'hFF, shift[7:0]);
            send_transaction(3'b110, 8'h80, shift[7:0]);
        end

        // ====================================================================
        // PHASE 4: Result Range Coverage
        // Targets: cg_result bins (zero, low, mid, high, max)
        // ====================================================================
        `uvm_info("COV_SEQ", "Phase 4: Result Range Coverage", UVM_LOW)
        
        // Zero result
        send_transaction(3'b000, 8'h00, 8'h00);  // ADD 0+0 = 0
        send_transaction(3'b001, 8'h05, 8'h05);  // SUB 5-5 = 0
        send_transaction(3'b010, 8'h00, 8'hFF);  // MUL 0*255 = 0
        send_transaction(3'b011, 8'h0F, 8'hF0);  // AND 0x0F & 0xF0 = 0
        
        // Low results (1-255)
        send_transaction(3'b000, 8'h01, 8'h01);  // ADD 1+1 = 2
        send_transaction(3'b000, 8'h10, 8'h20);  // ADD 16+32 = 48
        send_transaction(3'b000, 8'h7F, 8'h7F);  // ADD 127+127 = 254
        
        // Medium results (256-4095)
        send_transaction(3'b000, 8'h80, 8'h80);  // ADD 128+128 = 256
        send_transaction(3'b010, 8'h10, 8'h10);  // MUL 16*16 = 256
        send_transaction(3'b010, 8'h20, 8'h20);  // MUL 32*32 = 1024
        send_transaction(3'b010, 8'h30, 8'h30);  // MUL 48*48 = 2304
        send_transaction(3'b010, 8'h3F, 8'h3F);  // MUL 63*63 = 3969
        
        // High results (4096-65534)
        send_transaction(3'b010, 8'h40, 8'h40);  // MUL 64*64 = 4096
        send_transaction(3'b010, 8'h50, 8'h50);  // MUL 80*80 = 6400
        send_transaction(3'b010, 8'h80, 8'h80);  // MUL 128*128 = 16384
        send_transaction(3'b010, 8'hA0, 8'hA0);  // MUL 160*160 = 25600
        send_transaction(3'b010, 8'hC0, 8'hC0);  // MUL 192*192 = 36864
        send_transaction(3'b010, 8'hF0, 8'hF0);  // MUL 240*240 = 57600
        send_transaction(3'b010, 8'hFE, 8'hFE);  // MUL 254*254 = 64516
        
        // Max result (65535 / 0xFFFF)
        send_transaction(3'b010, 8'hFF, 8'hFF);  // MUL 255*255 = 65025 (close)
        send_transaction(3'b111, 8'hFF, 8'h00);  // DIV by zero = 0xFFFF

        // ====================================================================
        // PHASE 5: Full Cross Coverage - All ops x operand ranges
        // Targets: cg_full_cross (8 ops x 3 ranges x 3 ranges = 72 bins)
        // ====================================================================
        `uvm_info("COV_SEQ", "Phase 5: Full Cross Coverage", UVM_LOW)
        
        begin
            // Representative values for each range
            // low: 0x00-0x3F, mid: 0x40-0xBF, high: 0xC0-0xFF
            bit [7:0] range_vals[] = '{8'h20, 8'h80, 8'hE0};  // low, mid, high
            
            for (int op = 0; op < 8; op++) begin
                foreach (range_vals[i]) begin
                    foreach (range_vals[j]) begin
                        send_transaction(op[2:0], range_vals[i], range_vals[j]);
                    end
                end
            end
        end

        // ====================================================================
        // PHASE 6: Additional Random Transactions
        // ====================================================================
        `uvm_info("COV_SEQ", "Phase 6: Random Fill", UVM_LOW)
        
        repeat(100) begin
            alu_item item;
            item = alu_item::type_id::create("item");
            start_item(item);
            if (!item.randomize())
                `uvm_error("COV_SEQ", "Randomization failed")
            finish_item(item);
        end

        `uvm_info("COV_SEQ", "Coverage-Driven Sequence Complete!", UVM_LOW)
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
