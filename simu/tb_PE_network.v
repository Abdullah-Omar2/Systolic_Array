`timescale 1ns / 1ps

//tb for testing the behavior of some PEs interacts with each others
module tb_PE_network;

  parameter DATAWIDTH = 16;

  reg clk, rst;
  reg [DATAWIDTH-1:0] A_in, B_in;
  wire [(2*DATAWIDTH)-1:0] C1, C2, C3;
  wire [DATAWIDTH-1:0] A1_out, B1_out;
  wire [DATAWIDTH-1:0] A2_out, B2_out;
  wire [DATAWIDTH-1:0] A3_out, B3_out;

  initial clk = 1;
  always #5 clk = ~clk;

  PE #(DATAWIDTH) PE1 (
    .clk(clk),
    .rst(rst),
    .A(A_in),
    .B(B_in),
    .C(C1),
    .A_out(A1_out),
    .B_out(B1_out)
  );

  PE #(DATAWIDTH) PE2 (
    .clk(clk),
    .rst(rst),
    .A(A_in),
    .B(B1_out),
    .C(C2),
    .A_out(A2_out),
    .B_out(B2_out)
  );

  PE #(DATAWIDTH) PE3 (
    .clk(clk),
    .rst(rst),
    .A(A1_out),
    .B(B_in),
    .C(C3),
    .A_out(A3_out),
    .B_out(B3_out)
  );

  initial begin
    rst = 0;
    A_in = 0;
    B_in = 0;
    #10 rst = 1;

    A_in = 16'd1000;
    B_in = 16'd2000;
    #10;

    A_in = 16'd3000;
    B_in = 16'd4000;
    #10;

    A_in = 16'd5000;
    B_in = 16'd6000;
    #10;

    #50;
    $finish;
  end

  initial begin
    $monitor("T=%0t | A_in=%d B_in=%d || C1=%d C2=%d C3=%d", 
             $time, A_in, B_in, C1, C2, C3);
  end

endmodule