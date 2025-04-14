module UART_RX #(parameter CLKS_PER_BIT = 217) (
	input clk,
	input reset_n,
	input i_rx_serial,
	output o_rx_done,
	output reg [7:0] o_rx_byte
);

localparam IDLE = 3'b000;
localparam START = 3'b001;
localparam DATA = 3'b010;
localparam STOP = 3'b011;

reg [2:0] c_state, n_state;
reg [2:0] r_bit_index;
reg r_rx_done;
reg [$clog2(CLKS_PER_BIT) - 1:0] r_clk_count;

always @(posedge clk or negedge reset_n) begin
	if (!reset_n) begin
		c_state <= IDLE;
		r_bit_index <= 3'b000;
		r_rx_done <= 1'b0;
		r_clk_count <= 0;
	end else begin
		c_state <= n_state;
		case (c_state)
			IDLE : begin
				r_bit_index <= 3'b000;
				r_rx_done <= 1'b0;
				r_clk_count <= 0;
			end
			START: begin
				if (r_clk_count == (CLKS_PER_BIT - 1)/2) begin
					if (i_rx_serial == 0) begin
					r_clk_count <= 0;
					end
				end else begin
					r_clk_count <= r_clk_count + 1;
				end
			end
			DATA : begin
				if (r_clk_count < CLKS_PER_BIT - 1) r_clk_count <= r_clk_count + 1;
				else begin
					o_rx_byte[r_bit_index] <= i_rx_serial;
					r_clk_count <= 0;
					if (r_bit_index < 7) r_bit_index <= r_bit_index + 1;
					else r_bit_index <= 3'b000;					
				end
			end
			STOP : begin
				if (r_clk_count < CLKS_PER_BIT - 1) r_clk_count <= r_clk_count + 1;
				else begin
					if (i_rx_serial) begin
						r_rx_done <= 1'b1;
					end
					else begin
						r_rx_done <= 1'b0;
					end
					r_clk_count <= 0;
				end
			end
			default: begin
    			r_bit_index <= 3'b000;
    			r_rx_done   <= 1'b0;
    			r_clk_count <= 0;
			end
		endcase
	end
end

always @(*) begin
	case (c_state)
		IDLE: n_state = (i_rx_serial == 0) ? START : IDLE;
		START: begin
			if (r_clk_count == (CLKS_PER_BIT - 1)/2) begin
				if (i_rx_serial == 0) n_state = DATA;
				else n_state = IDLE;
			end else n_state = START;
		end
		DATA: begin
			if (r_clk_count < CLKS_PER_BIT - 1) n_state = DATA;
			else begin
				if (r_bit_index < 7) n_state = DATA;
				else n_state = STOP;
			end
		end
		STOP: begin
			if (r_clk_count < CLKS_PER_BIT - 1) n_state = STOP;
			else n_state = IDLE;
		end					
		default: n_state = IDLE;
	endcase
end

assign o_rx_done = r_rx_done;

endmodule