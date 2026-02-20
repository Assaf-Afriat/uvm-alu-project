
// ALU Driver Callbacks
// Implementations for driver callback hooks.

// ============================================================================
// LOGGING CALLBACK - Logs all driven transactions
// ============================================================================
class alu_driver_log_cb extends alu_callback_base;
    `uvm_object_utils(alu_driver_log_cb)

    int unsigned tx_count = 0;

    function new(string name = "alu_driver_log_cb");
        super.new(name);
    endfunction

    virtual function void pre_drive(uvm_component drv, alu_item item, ref bit drop);
        tx_count++;
        `uvm_info("DRV_CB", $sformatf("[TX #%0d] PRE_DRIVE: op=%0d op1=%0d op2=%0d",
            tx_count, item.op, item.op1, item.op2), UVM_HIGH)
    endfunction

    virtual function void post_drive(uvm_component drv, alu_item item);
        `uvm_info("DRV_CB", $sformatf("[TX #%0d] POST_DRIVE: Complete", tx_count), UVM_HIGH)
    endfunction
endclass

// ============================================================================
// ERROR INJECTION CALLBACK - Randomly corrupts transactions
// ============================================================================
class alu_error_inject_cb extends alu_callback_base;
    `uvm_object_utils(alu_error_inject_cb)

    // Configuration
    int unsigned error_rate = 5;  // Percentage of transactions to corrupt (0-100)
    bit inject_op_errors  = 1;    // Corrupt opcode
    bit inject_op1_errors = 1;    // Corrupt operand 1
    bit inject_op2_errors = 1;    // Corrupt operand 2

    // Statistics
    int unsigned total_tx = 0;
    int unsigned injected_errors = 0;

    function new(string name = "alu_error_inject_cb");
        super.new(name);
    endfunction

    virtual function void pre_drive(uvm_component drv, alu_item item, ref bit drop);
        int rand_val;
        
        total_tx++;
        rand_val = $urandom_range(0, 99);
        
        if (rand_val < error_rate) begin
            injected_errors++;
            
            // Randomly choose what to corrupt
            case ($urandom_range(0, 2))
                0: if (inject_op_errors) begin
                    `uvm_info("ERR_INJ", $sformatf("Corrupting OP: %0d -> %0d", 
                        item.op, item.op ^ 3'b111), UVM_MEDIUM)
                    item.op = item.op ^ 3'b111;
                end
                1: if (inject_op1_errors) begin
                    `uvm_info("ERR_INJ", $sformatf("Corrupting OP1: %0d -> %0d", 
                        item.op1, ~item.op1), UVM_MEDIUM)
                    item.op1 = ~item.op1;
                end
                2: if (inject_op2_errors) begin
                    `uvm_info("ERR_INJ", $sformatf("Corrupting OP2: %0d -> %0d", 
                        item.op2, ~item.op2), UVM_MEDIUM)
                    item.op2 = ~item.op2;
                end
            endcase
        end
    endfunction

    virtual function void post_drive(uvm_component drv, alu_item item);
        // Report statistics periodically
        if (total_tx % 100 == 0) begin
            `uvm_info("ERR_INJ", $sformatf("Error Injection Stats: %0d/%0d (%.1f%%)",
                injected_errors, total_tx, real'(injected_errors)/real'(total_tx)*100), UVM_LOW)
        end
    endfunction
endclass

// ============================================================================
// DELAY INJECTION CALLBACK - Adds random delays between transactions
// ============================================================================
class alu_delay_inject_cb extends alu_callback_base;
    `uvm_object_utils(alu_delay_inject_cb)

    int unsigned min_delay = 0;   // Minimum cycles delay
    int unsigned max_delay = 5;   // Maximum cycles delay
    int unsigned delay_pct = 30;  // Percentage of transactions to delay

    function new(string name = "alu_delay_inject_cb");
        super.new(name);
    endfunction

    // Note: Delays would need to be implemented in driver's run_phase
    // This callback just flags that a delay should occur
    virtual function void pre_drive(uvm_component drv, alu_item item, ref bit drop);
        if ($urandom_range(0, 99) < delay_pct) begin
            int delay_cycles = $urandom_range(min_delay, max_delay);
            `uvm_info("DELAY_CB", $sformatf("Requesting %0d cycle delay", delay_cycles), UVM_HIGH)
        end
    endfunction
endclass

// ============================================================================
// DROP TRANSACTION CALLBACK - Randomly drops transactions
// ============================================================================
class alu_drop_tx_cb extends alu_callback_base;
    `uvm_object_utils(alu_drop_tx_cb)

    int unsigned drop_rate = 2;  // Percentage of transactions to drop
    int unsigned dropped = 0;
    int unsigned total = 0;

    function new(string name = "alu_drop_tx_cb");
        super.new(name);
    endfunction

    virtual function void pre_drive(uvm_component drv, alu_item item, ref bit drop);
        total++;
        if ($urandom_range(0, 99) < drop_rate) begin
            drop = 1;
            dropped++;
            `uvm_info("DROP_CB", $sformatf("Dropping transaction #%0d (op=%0d)", 
                total, item.op), UVM_MEDIUM)
        end
    endfunction
endclass
