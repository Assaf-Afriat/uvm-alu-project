
// UVM Monitor
// Observes the DUT interface and broadcasts transactions.
// Handles Pipelined Request/Response independently.

class alu_monitor extends uvm_monitor;
    `uvm_component_utils(alu_monitor)

    virtual alu_if vif;
    
    // Analysis Ports
    uvm_analysis_port #(alu_item) req_port;
    uvm_analysis_port #(alu_item) resp_port;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        req_port  = new("req_port", this);
        resp_port = new("resp_port", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual alu_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal("NOVIF", {"Virtual interface not set for: ", get_full_name(), ".vif"});
        end
    endfunction

    task run_phase(uvm_phase phase);
        // Fork off two threads for pipelined monitoring
        fork
            monitor_request();
            monitor_response();
        join
    endtask

    // Monitor Input (Requests)
    task monitor_request();
        forever begin
            @ (posedge vif.clk);
            // Check for valid handshake (Valid=1 AND Ready=1)
            if (vif.req_valid && vif.req_ready) begin
                alu_item item = alu_item::type_id::create("req_item");
                item.op  = vif.req_op;
                item.op1 = vif.req_op1;
                item.op2 = vif.req_op2;
                
                req_port.write(item);
                
                `uvm_info("MON_REQ", $sformatf("Saw Request: %s", item.convert2string()), UVM_HIGH)
            end
        end
    endtask

    // Monitor Output (Responses)
    task monitor_response();
        forever begin
            @ (posedge vif.clk);
            // Check for valid handshake
            if (vif.resp_valid && vif.resp_ready) begin
                alu_item item = alu_item::type_id::create("resp_item");
                item.result = vif.resp_result;
                
                resp_port.write(item);

                `uvm_info("MON_RESP", $sformatf("Saw Response: Result=%0d", item.result), UVM_HIGH)
            end
        end
    endtask

endclass
