
// UVM Sequencer
// Connects sequences to the driver.

class alu_sequencer extends uvm_sequencer #(alu_item);
    `uvm_component_utils(alu_sequencer)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

endclass
