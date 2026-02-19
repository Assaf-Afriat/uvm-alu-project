
// UVM Driver
// Drives transactions from the Sequencer to the DUT interface.

class alu_driver extends uvm_driver #(alu_item);
    `uvm_component_utils(alu_driver)

    virtual alu_if vif;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        // Get interface from Config DB
        if (!uvm_config_db#(virtual alu_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal("NOVIF", {"Virtual interface not set for: ", get_full_name(), ".vif"});
        end
    endfunction

    task run_phase(uvm_phase phase);
        // Reset signals
        vif.req_valid  <= 0;
        vif.resp_ready <= 1; // Always ready to accept responses (simple driver)

        // Wait for Reset
        wait(vif.rst_n === 0);
        wait(vif.rst_n === 1);

        forever begin
            // Get next transaction from Sequencer
            seq_item_port.get_next_item(req);

            // Drive Transaction
            drive_item(req);

            // Signal completion
            seq_item_port.item_done();
        end
    endtask

    task drive_item(alu_item item);
        // Wait for clock edge
        @ (posedge vif.clk);
        
        // Assert Request
        vif.req_valid <= 1;
        vif.req_op    <= item.op;
        vif.req_op1   <= item.op1;
        vif.req_op2   <= item.op2;

        // Wait for Ready (Handshake)
        do begin
            @ (posedge vif.clk);
        end while (vif.req_ready !== 1);

        // Deassert data after handshake check
        vif.req_valid <= 0;
    endtask

endclass
