// Processing Element (PE) module
module PE #(parameter DATAWIDTH)( 
  input clk, rst, 
  input [DATAWIDTH-1 : 0] A, B, 
  output [(2 * DATAWIDTH)-1 : 0] C, 
  output [DATAWIDTH-1 : 0] A_out, B_out 
  ); 
   
  // Internal wires for multiplication and accumulation
  wire [(2 * DATAWIDTH)-1 : 0] MUL; 
  wire [(2 * DATAWIDTH)-1 : 0] SUM; 
  wire [(2 * DATAWIDTH)-1 : 0] C_wire; 
   
  // Registers for internal storage
  reg [(2 * DATAWIDTH)-1 : 0] C_reg; 
  reg [DATAWIDTH-1 : 0] A_reg, B_reg; 
   
  assign MUL = A * B; 
  assign C_wire = C_reg; 
  assign SUM = MUL + C_wire; 
   
  // Accumulator register (C)
  always @(posedge clk or negedge rst) begin 
    if (rst == 1'b0) begin 
      C_reg <= 0; 
    end else begin 
      C_reg <= SUM; 
    end 
  end 
   
  // Register to delay A
  always @(posedge clk or negedge rst) begin 
    if (rst == 1'b0) begin 
      A_reg <= 0; 
    end else begin 
      A_reg <= A; 
    end 
  end 
   
  // Register to delay B
  always @(posedge clk or negedge rst) begin 
    if (rst == 1'b0) begin 
      B_reg <= 0; 
    end else begin 
      B_reg <= B; 
    end 
  end 
   
  assign A_out = A_reg; 
  assign B_out = B_reg; 
  assign C = C_reg; 
   
endmodule