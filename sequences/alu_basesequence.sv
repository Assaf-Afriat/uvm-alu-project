
// UVM Sequence Library
// Contains all sequences for the ALU.

class alu_basesequence extends uvm_sequence #(alu_item);
    `uvm_object_utils(alu_basesequence)
    
    function new(string name = "alu_basesequence");
        super.new(name);
    endfunction
    
    task body();
        alu_item item;
        
        `uvm_info("SEQ", "Starting Base Sequence (50 items)", UVM_LOW)

        repeat(50) begin
            item = alu_item::type_id::create("item");
            start_item(item);
            if(!item.randomize()) `uvm_error("SEQ", "Randomization failed")
            finish_item(item);
        end
        
        `uvm_info("SEQ", "Base Sequence Finished", UVM_LOW)
    endtask
endclass
