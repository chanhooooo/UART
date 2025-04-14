`include "uart_tx.v"
`include "UART_RX.v"
`timescale 1ns/10ps

module UART_TB ();

  // Testbench uses a 25 MHz clock
  // 25000000 / 115200 = 217 Clocks Per Bit.
  parameter c_CLOCK_PERIOD_NS = 40;
  parameter c_CLKS_PER_BIT    = 217;

  reg r_Clock = 0;
  reg r_Reset_n = 0;

  // TX side signals
  reg r_TX_Ready = 0;
  reg [7:0] r_TX_Byte = 0;
  wire w_TX_Done;
  wire w_TX_Active;
  wire w_TX_Serial;

  // RX side signals
  wire w_RX_Done;
  wire [7:0] w_RX_Byte;

  // Instantiate TX
  UART_tx #(.CLKS_PER_BIT(c_CLKS_PER_BIT)) UART_TX_Inst (
    .clk(r_Clock),
    .reset_n(r_Reset_n),
    .i_tx_ready(r_TX_Ready),
    .i_tx_byte(r_TX_Byte),
    .o_tx_done(w_TX_Done),
    .o_tx_active(w_TX_Active),
    .o_tx_serial(w_TX_Serial)
  );

  // Instantiate RX
  UART_RX #(.CLKS_PER_BIT(c_CLKS_PER_BIT)) UART_RX_Inst (
    .clk(r_Clock),
    .reset_n(r_Reset_n),
    .i_rx_serial(w_UART_Line),
    .o_rx_done(w_RX_Done),
    .o_rx_byte(w_RX_Byte)
  );

  // TX -> RX 연결: TX active일 때는 시리얼 출력 사용, 아니면 1 유지
  wire w_UART_Line = w_TX_Active ? w_TX_Serial : 1'b1;

  // Clock 생성
  always #(c_CLOCK_PERIOD_NS/2) r_Clock <= ~r_Clock;

  // Test sequence
  initial begin
    // 초기화 및 리셋
    r_Reset_n <= 0;
    @(posedge r_Clock);
    @(posedge r_Clock);
    r_Reset_n <= 1;

    // TX 시작
    @(posedge r_Clock);
    r_TX_Byte <= 8'h3F;
    r_TX_Ready <= 1;
    @(posedge r_Clock);
    r_TX_Ready <= 0;

    // RX 완료 대기
    wait(w_RX_Done);

    // 결과 확인
    if (w_RX_Byte == 8'h3F)
      $display("Test Passed - Correct Byte Received: %h", w_RX_Byte);
    else
      $display("Test Failed - Incorrect Byte Received: %h", w_RX_Byte);

    $finish;
  end

  // 시뮬레이션 waveform dump
  initial begin
    $dumpfile("uart_tb.vcd");
    $dumpvars(0, UART_TB);
  end

endmodule
