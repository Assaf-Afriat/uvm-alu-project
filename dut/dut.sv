
// Simple ALU DUT with Output FIFO
// Features:
// - Valid/Ready on inputs and outputs
// - Variable latency execution (Blocking input while busy)
// - Output FIFO of depth 4
// - Supports backpressure from output to input

module alu_dut (
    input  logic        clk,
    input  logic        rst_n,

    // Request Interface
    input  logic        req_valid,
    output logic        req_ready,
    input  logic [2:0]  req_op,
    input  logic [7:0]  req_op1,
    input  logic [7:0]  req_op2,

    // Response Interface
    output logic        resp_valid,
    input  logic        resp_ready,
    output logic [15:0] resp_result
);

    // Opcodes
    localparam OP_ADD = 3'b000;
    localparam OP_SUB = 3'b001;
    localparam OP_MUL = 3'b010;
    localparam OP_AND = 3'b011;
    localparam OP_XOR = 3'b100;
    localparam OP_SLL = 3'b101;
    localparam OP_SRL = 3'b110;
    localparam OP_DIV = 3'b111;

    // Latency
    // ADD/SUB/AND/XOR/SLL/SRL = 2 cycles
    // MUL = 4 cycles
    // DIV = 8 cycles

    // Internal Signals
    logic [15:0] computed_result;
    logic [3:0]  latency_counter;
    logic        busy;
    logic        fifo_push;
    logic [15:0] fifo_wdata;
    logic        fifo_full;
    logic        fifo_empty;
    logic        internal_ready;

    // Execution Logic
    // Using a state machine or simple counter for blocking execution
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            busy            <= 1'b0;
            latency_counter <= 4'd0;
            fifo_push       <= 1'b0;
            fifo_wdata      <= 16'd0;
            computed_result <= 16'd0;
        end else begin
            fifo_push <= 1'b0; // Default

            if (busy) begin
                if (latency_counter > 0) begin
                    latency_counter <= latency_counter - 1;
                end else begin
                    // Execution done, try to push to FIFO
                    if (!fifo_full) begin
                        fifo_push  <= 1'b1;
                        fifo_wdata <= computed_result;
                        busy       <= 1'b0;
                    end
                    // If FIFO full, stay busy and wait (backpressure)
                end
            end else if (req_valid && req_ready) begin
                busy <= 1'b1;
                // Calculate result
                case (req_op)
                    OP_ADD: begin computed_result <= req_op1 + req_op2; latency_counter <= 4'd2 - 1; end
                    OP_SUB: begin computed_result <= req_op1 - req_op2; latency_counter <= 4'd2 - 1; end
                    OP_MUL: begin computed_result <= req_op1 * req_op2; latency_counter <= 4'd4 - 1; end
                    OP_AND: begin computed_result <= {8'b0, req_op1 & req_op2}; latency_counter <= 4'd2 - 1; end
                    OP_XOR: begin computed_result <= {8'b0, req_op1 ^ req_op2}; latency_counter <= 4'd2 - 1; end
                    OP_SLL: begin computed_result <= {8'b0, req_op1 << req_op2[2:0]}; latency_counter <= 4'd2 - 1; end
                    OP_SRL: begin computed_result <= {8'b0, req_op1 >> req_op2[2:0]}; latency_counter <= 4'd2 - 1; end
                    OP_DIV: begin
                        if (req_op2 != 0) computed_result <= {8'b0, req_op1 / req_op2};
                        else              computed_result <= 16'hFFFF; // Error value
                        latency_counter <= 4'd8 - 1;
                    end
                    default: begin computed_result <= 16'd0; latency_counter <= 4'd1; end
                endcase
            end
        end
    end

    // Input Ready Logic
    // Ready if not busy.
    // Note: If FIFO is full, we eventually stay busy, so req_ready is low.
    assign req_ready = !busy; // Simple blocking

    // Output FIFO Instance
    fifo_4_deep u_fifo (
        .clk        (clk),
        .rst_n      (rst_n),
        .push       (fifo_push),
        .wdata      (fifo_wdata),
        .full       (fifo_full),
        .pop        (resp_ready & resp_valid),
        .rdata      (resp_result),
        .empty      (fifo_empty)
    );

    assign resp_valid = !fifo_empty;

endmodule

// Simple 4-deep FIFO
module fifo_4_deep (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        push,
    input  logic [15:0] wdata,
    output logic        full,
    input  logic        pop,
    output logic [15:0] rdata,
    output logic        empty
);
    logic [15:0] mem [3:0];
    logic [1:0]  wptr, rptr;
    logic [2:0]  count; // extra bit for full/empty distinction

    assign full  = (count == 3'd4);
    assign empty = (count == 3'd0);
    assign rdata = mem[rptr];

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wptr  <= 2'd0;
            rptr  <= 2'd0;
            count <= 3'd0;
        end else begin
            if (push && !full) begin
                mem[wptr] <= wdata;
                wptr      <= wptr + 1;
            end

            if (pop && !empty) begin
                rptr <= rptr + 1;
            end

            if (push && !full && !(pop && !empty))
                count <= count + 1;
            else if (pop && !empty && !(push && !full))
                count <= count - 1;
        end
    end
endmodule
