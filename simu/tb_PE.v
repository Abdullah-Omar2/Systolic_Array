`timescale 1ns / 1ps

//tb for testing the behavior of one PE
module tb_PE;

  parameter DATAWIDTH = 16;

  reg clk, rst;
  reg [DATAWIDTH-1:0] A, B;
  wire [(2*DATAWIDTH)-1:0] C;
  wire [DATAWIDTH-1:0] A_out, B_out;

  PE #(DATAWIDTH) uut (
    .clk(clk),
    .rst(rst),
    .A(A),
    .B(B),
    .C(C),
    .A_out(A_out),
    .B_out(B_out)
  );

  initial clk = 0;
  always #5 clk = ~clk;

  initial begin
    rst = 0;
    A = 0;
    B = 0;
    #15 rst = 1;

    A = 16'd3;
    B = 16'd5;
    #10;

    A = 16'd4;
    B = 16'd2;
    #10;

    A = 16'd7;
    B = 16'd6;
    #10;

    #50;
    $finish;
  end

  initial begin
    $monitor("Time=%0t | A=%d, B=%d | A_out=%d, B_out=%d | C=%d", $time, A, B, A_out, B_out, C);
  end

endmodule