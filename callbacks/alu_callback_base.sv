
// ALU Callback Base Class
// All ALU callbacks extend from this base class.
// Uses uvm_component as parameter type to avoid forward declaration issues.

class alu_callback_base extends uvm_callback;
    `uvm_object_utils(alu_callback_base)

    function new(string name = "alu_callback_base");
        super.new(name);
    endfunction

    // ========================================================================
    // DRIVER CALLBACKS
    // ========================================================================
    
    // Called before driving a transaction to the DUT
    // Can modify the transaction or skip it entirely
    virtual function void pre_drive(uvm_component drv, alu_item item, ref bit drop);
    endfunction

    // Called after driving a transaction to the DUT
    virtual function void post_drive(uvm_component drv, alu_item item);
    endfunction

    // ========================================================================
    // MONITOR CALLBACKS
    // ========================================================================
    
    // Called after capturing a request transaction
    virtual function void post_req_capture(uvm_component mon, alu_item item, ref bit drop);
    endfunction

    // Called after capturing a response transaction
    virtual function void post_resp_capture(uvm_component mon, alu_item item, ref bit drop);
    endfunction

    // ========================================================================
    // SCOREBOARD CALLBACKS
    // ========================================================================
    
    // Called before comparing expected vs actual
    virtual function void pre_compare(uvm_component scb, alu_item req, alu_item resp, 
                                       ref logic [15:0] expected_result);
    endfunction

    // Called after comparison (with result)
    virtual function void post_compare(uvm_component scb, alu_item req, alu_item resp,
                                        logic [15:0] expected_result, bit passed);
    endfunction

endclass
