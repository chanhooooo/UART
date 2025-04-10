module UART_tx (
    input clk,
    input reset_n,
    input [7:0] i_tx_byte,
    input i_tx_ready,
    output o_tx_done,
    output o_tx_active,
    output o_tx_data
);

localparam IDLE = 3'b000;
localparam START = 3'b001;
localparam DATA = 3'b010;
localparam STOP = 3'b011;

reg [2:0] r_bit_index;
reg [2:0] c_state, n_state;
reg r_tx_done;
reg r_tx_active;
reg r_tx_data;

// Sequential logic - state and bit index update
always @(posedge clk, negedge reset_n) begin
    if (!reset_n) begin
        c_state <= IDLE;
        r_bit_index <= 3'b0;
        r_tx_done <= 1'b0;
        r_tx_active <= 1'b0;
        r_tx_data <= 1'b1;
    end else begin
        c_state <= n_state;
        
        // Update outputs based on next state
        case (n_state)
            IDLE: begin
                r_tx_done <= 1'b0;
                r_tx_active <= (i_tx_ready) ? 1'b1 : 1'b0;
                r_tx_data <= 1'b1;
            end
            
            START: begin
                r_tx_data <= 1'b0; // Start bit is always 0
                r_bit_index <= 3'b000;
                r_tx_active <= 1'b1;
            end
            
            DATA: begin
                r_tx_data <= i_tx_byte[r_bit_index];
                if (r_bit_index < 7)
                    r_bit_index <= r_bit_index + 1'b1;
            end
            
            STOP: begin
                r_tx_data <= 1'b1; // Stop bit is always 1
                r_tx_done <= 1'b1;
                r_tx_active <= 1'b0;
            end
            
            default: begin
                r_tx_data <= 1'b1;
            end
        endcase
    end
end

// Combinational logic - next state determination
always @(*) begin
    case (c_state)
        IDLE:
            n_state = (i_tx_ready) ? START : IDLE;
        
        START:
            n_state = DATA;
        
        DATA:
            n_state = (r_bit_index == 3'b111) ? STOP : DATA;
        
        STOP:
            n_state = IDLE;
        
        default:
            n_state = IDLE;
    endcase
end

// Output assignments
assign o_tx_done = r_tx_done;
assign o_tx_active = r_tx_active;
assign o_tx_data = r_tx_data;

endmodule