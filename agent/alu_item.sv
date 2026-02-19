
// UVM Transaction Item
// Represents a single ALU operation.

class alu_item extends uvm_sequence_item;
    
    // Randomizable fields
    rand bit [2:0]  op;
    rand bit [7:0]  op1;
    rand bit [7:0]  op2;

    // Output fields (not randomized)
    bit [15:0] result;

    // Utility macros
    `uvm_object_utils_begin(alu_item)
        `uvm_field_int(op, UVM_ALL_ON)
        `uvm_field_int(op1, UVM_ALL_ON)
        `uvm_field_int(op2, UVM_ALL_ON)
        `uvm_field_int(result, UVM_ALL_ON)
    `uvm_object_utils_end

    // Constraints
    constraint op_c { op inside {[0:7]}; }

    // Constructor
    function new(string name = "alu_item");
        super.new(name);
    endfunction

    // Optional: Print helper
    function string convert2string();
        return $sformatf("OP=%0d, A=%0d, B=%0d, RES=%0d", op, op1, op2, result);
    endfunction

endclass
