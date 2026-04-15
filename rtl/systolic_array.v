// Systolic Array Module for Matrix Multiplication
module systolic_array #(parameter DATAWIDTH = 16, parameter N_SIZE = 5)( 
  input clk, rst_n, valid_in, 
  input [(N_SIZE * DATAWIDTH)-1 : 0] matrix_a_in, matrix_b_in, 
  output [(N_SIZE * 2 * DATAWIDTH)-1 : 0] matrix_c_out, 
  output valid_out 
  ); 
   
  // Internal buses for unpacked A and B inputs
  wire [DATAWIDTH - 1 : 0] A_internal [1 : N_SIZE]; 
  wire [DATAWIDTH - 1 : 0] B_internal [1 : N_SIZE]; 

  // Internal outputs of all PEs
  wire [(2 * DATAWIDTH) - 1 : 0] C_internal [1 : N_SIZE][1 : N_SIZE]; 

  // Inter-PE connections for A and B values
  wire [DATAWIDTH - 1 : 0] PE_a_connection[1 : N_SIZE][1 : N_SIZE]; 
  wire [DATAWIDTH - 1 : 0] PE_b_connection[1 : N_SIZE][1 : N_SIZE]; 

  // Pipeline registers to delay A and B
  reg [DATAWIDTH-1 : 0] pipeline_a_regs [1 : (N_SIZE * N_SIZE - N_SIZE) / 2]; 
  reg [DATAWIDTH-1 : 0] pipeline_b_regs [1 : (N_SIZE * N_SIZE - N_SIZE) / 2]; 

  // Counter for controlling output validity
  reg [N_SIZE : 0] counter; 

  // Unpacking input A and B matrices
  genvar i, j; 
  generate 
    for (i = 1; i <= N_SIZE; i = i + 1) begin : unpack_inputs 
      assign A_internal[i] = valid_in ? matrix_a_in[(i * DATAWIDTH) - 1:(i - 1) * DATAWIDTH]: {DATAWIDTH{1'b0}}; 
      assign B_internal[i] = valid_in ? matrix_b_in[(i * DATAWIDTH) - 1:(i - 1) * DATAWIDTH]: {DATAWIDTH{1'b0}}; 
    end 
  endgenerate 

  // Shifting data through pipeline registers
  integer k,l,m; 
  always @(posedge clk or negedge rst_n) begin 
    if (rst_n == 1'b0) begin 
      for (k = 1; k <= (N_SIZE * N_SIZE - N_SIZE) / 2; k = k + 1) begin 
        pipeline_a_regs[k] <= 0; 
        pipeline_b_regs[k] <= 0; 
      end 
    end else begin 
      m = N_SIZE - 2; 
      for (k = 1; k <= N_SIZE - 1; k = k + 1) begin 
        if (valid_in) begin 
          pipeline_a_regs[k] <= A_internal[k + 1]; 
          pipeline_b_regs[k] <= B_internal[k + 1]; 
        end else begin
          pipeline_a_regs[k] <= 0; 
          pipeline_b_regs[k] <= 0;
        end
      end 
      for (k = N_SIZE; k <= (N_SIZE * N_SIZE - N_SIZE) / 2; k = k + m + 1) begin 
        for (l = k; l <= k + m - 1; l = l + 1) begin 
          pipeline_a_regs[l] <= pipeline_a_regs[l - m]; 
          pipeline_b_regs[l] <= pipeline_b_regs[l - m]; 
        end 
        m = m - 1; 
      end 
    end 
  end 

  // First PE instance (top-left)
  PE #(.DATAWIDTH(DATAWIDTH)) pe1 ( 
        .clk(clk), 
        .rst(rst_n), 
        .A(A_internal[1]), 
        .B(B_internal[1]), 
        .C(C_internal[1][1]), 
        .A_out(PE_a_connection[1][1]), 
        .B_out(PE_b_connection[1][1]) 
      ); 

  // First row PEs (except the first one)
  generate 
    for (i = 2; i <= N_SIZE; i = i + 1) begin :a
      PE #(.DATAWIDTH(DATAWIDTH)) pe2 ( 
        .clk(clk), 
        .rst(rst_n), 
        .A(pipeline_a_regs[N_SIZE * (i - 2) - (((i - 1) * (i - 2)) / 2 - 1)]), 
        .B(PE_b_connection[1][i-1]), 
        .C(C_internal[1][i]), 
        .A_out(PE_a_connection[1][i]), 
        .B_out(PE_b_connection[1][i]) 
      ); 
    end 
  endgenerate 

  // First column PEs (except the first one)
  generate 
    for (i = 2; i <= N_SIZE; i = i + 1) begin :b
      PE #(.DATAWIDTH(DATAWIDTH)) pe3 ( 
        .clk(clk), 
        .rst(rst_n), 
        .A(PE_a_connection[i-1][1]), 
        .B(pipeline_b_regs[N_SIZE * (i - 2) - (((i - 1) * (i - 2)) / 2 - 1)]), 
        .C(C_internal[i][1]), 
        .A_out(PE_a_connection[i][1]), 
        .B_out(PE_b_connection[i][1]) 
      ); 
    end 
  endgenerate 

  // Internal PEs (i > 1 and j > 1)
  generate 
    for (i = 2; i <= N_SIZE; i = i + 1) begin :d
      for (j = 2; j <= N_SIZE; j = j + 1) begin :c
        PE #(.DATAWIDTH(DATAWIDTH)) pe4 ( 
              .clk(clk), 
              .rst(rst_n), 
              .A(PE_a_connection[i-1][j]), 
              .B(PE_b_connection[i][j-1]), 
              .C(C_internal[i][j]), 
              .A_out(PE_a_connection[i][j]), 
              .B_out(PE_b_connection[i][j]) 
            ); 
      end 
    end 
  endgenerate 

  // Counter for output control
  always @(posedge clk or negedge rst_n) begin 
    if (rst_n == 1'b0) begin 
      counter <= 0; 
    end else begin 
      if (counter == (3 * N_SIZE - 1)) begin 
        counter <= 0; 
      end else begin 
        counter <= counter + 1; 
      end 
    end 
  end 

  // Assigning output from last active row based on counter
  generate 
    for (i = 1; i <= N_SIZE; i = i + 1) begin  :e
      assign matrix_c_out[(i * 2 * DATAWIDTH) - 1:(i - 1) * 2 * DATAWIDTH] = valid_out ? C_internal[counter - (2 * N_SIZE - 1)][i]: 0; 
    end 
  endgenerate 

  // Output valid only after sufficient latency
  assign valid_out = (counter >= (2 * N_SIZE)) ? 1 : 0; 

endmodule
