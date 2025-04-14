module UART_tx #(parameter CLKS_PER_BIT = 217)(
    input clk,
    input reset_n,
    input [7:0] i_tx_byte,
    input i_tx_ready,
    output o_tx_done,
    output o_tx_active,
    output o_tx_serial
);

    localparam IDLE  = 3'b000;
    localparam START = 3'b001;
    localparam DATA  = 3'b010;
    localparam STOP  = 3'b011;

    reg [2:0] r_bit_index;
    reg [2:0] c_state, n_state;
    reg [7:0] r_tx_data;
    reg [$clog2(CLKS_PER_BIT):0] r_clk_count;
    reg r_tx_done;
    reg r_tx_active;
    reg r_tx_serial;

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            c_state     <= IDLE;
            r_bit_index <= 3'b000;
            r_tx_done   <= 1'b0;
            r_tx_active <= 1'b0;
            r_tx_serial <= 1'b1;
            r_tx_data   <= 8'h00;
            r_clk_count <= 0;
        end else begin
            c_state <= n_state;

            case (c_state)
                IDLE: begin
                    r_tx_done   <= 1'b0;
                    r_tx_active <= 1'b0;
                    r_tx_serial <= 1'b1;
                    r_bit_index <= 3'b000;
                    r_clk_count <= 0;
                    if (i_tx_ready) begin
                        r_tx_data   <= i_tx_byte;
                        r_tx_active <= 1'b1;
                    end
                end

                START: begin
                    r_tx_serial <= 1'b0;  // start bit
                    if (r_clk_count < CLKS_PER_BIT - 1) begin
                        r_clk_count <= r_clk_count + 1;
                    end
                    else begin
                        r_clk_count <= 0;
                    end
                end

                DATA: begin
                    r_tx_serial <= r_tx_data[r_bit_index];
                    if (r_clk_count < CLKS_PER_BIT - 1) begin
                        r_clk_count <= r_clk_count + 1;
                    end
                    else begin
                        r_clk_count <= 0;
                        if (r_bit_index < 7) begin
                            r_bit_index <= r_bit_index + 1'b1;
                        end
                        else begin
                            r_bit_index <= 0;
                        end
                    end
                end

                STOP: begin
                    r_tx_serial <= 1'b1;
                    if (r_clk_count < CLKS_PER_BIT - 1) begin
                        r_clk_count <= r_clk_count + 1;
                    end
                    else begin
                        r_tx_done   <= 1'b1;
                        r_tx_active <= 1'b0;
                        r_clk_count <= 0; 
                    end
                end

                default: begin
                    r_tx_serial <= 1'b1;
                end
            endcase
        end
    end

    always @(*) begin
        case (c_state)
            IDLE:  n_state = (i_tx_ready) ? START : IDLE;
            START: n_state = (r_clk_count < CLKS_PER_BIT - 1) ? START : DATA;
            DATA:  begin
                if (r_clk_count < CLKS_PER_BIT - 1) begin
                    n_state = DATA;
                end
                else begin
                    if (r_bit_index == 7) begin
                        n_state = STOP;
                    end
                    else begin
                        n_state = DATA;
                    end
                end
            end
            STOP:  n_state = (r_clk_count < CLKS_PER_BIT - 1) ? STOP : IDLE;
            default: n_state = IDLE;
        endcase
    end

    assign o_tx_done   = r_tx_done;
    assign o_tx_active = r_tx_active;
    assign o_tx_serial = r_tx_serial;

endmodule
