
// UVM Test
// Instantiates the environment and starts sequences.

class alu_test extends uvm_test;
    `uvm_component_utils(alu_test)

    alu_env env;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = alu_env::type_id::create("env", this);
    endfunction

    function void end_of_elaboration_phase(uvm_phase phase);
        // Print topology
        uvm_top.print_topology();
    endfunction
    
    task run_phase(uvm_phase phase);
        alu_basesequence seq;
        
        phase.raise_objection(this);
        
        seq = alu_basesequence::type_id::create("seq");
        
        `uvm_info("TEST", "Starting Sequence", UVM_LOW)
        seq.start(env.agent.sequencer);
        `uvm_info("TEST", "Sequence Complete", UVM_LOW)
        
        // Drain time for pending responses
        #100ns;
        
        phase.drop_objection(this);
    endtask

endclass

// Basic Sequence moved to alu_sequence_lib.sv
