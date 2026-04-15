`timescale 1ns/1ps

module systolic_array_tb;

  parameter DATAWIDTH = 16;
  parameter N_SIZE = 5;

  reg clk, rst_n, valid_in;
  reg [(N_SIZE * DATAWIDTH)-1 : 0] matrix_a_in, matrix_b_in;
  wire [(N_SIZE * 2 * DATAWIDTH)-1 : 0] matrix_c_out;
  wire valid_out;

  integer log_file; // File handle for logging (used to store results in file instead of console)

  // Store full matrices for final print
  reg [DATAWIDTH-1:0] matrix_a_mem [0:N_SIZE-1][0:N_SIZE-1];
  reg [DATAWIDTH-1:0] matrix_b_mem [0:N_SIZE-1][0:N_SIZE-1];
  reg [(2*DATAWIDTH)-1:0] matrix_c_mem [0:N_SIZE-1][0:N_SIZE-1];
  reg [(2*DATAWIDTH)-1:0] expected_c_mem [0:N_SIZE-1][0:N_SIZE-1]; // <== Expected result

  // DUT
  systolic_array #(DATAWIDTH, N_SIZE) dut (
    .clk(clk),
    .rst_n(rst_n),
    .valid_in(valid_in),
    .matrix_a_in(matrix_a_in),
    .matrix_b_in(matrix_b_in),
    .matrix_c_out(matrix_c_out),
    .valid_out(valid_out)
  );

  // Clock generation
  always begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  // Monitor inputs and outputs with formatted decimal values
  integer i, j, k;
  always @(posedge clk) begin
    if (valid_in || valid_out) begin
      $fdisplay(log_file, "\n[Time %0t] valid_in = %b | valid_out = %b", $time, valid_in, valid_out);
      $fwrite(log_file, "matrix_a_in: ");
      for (i = 0; i < N_SIZE; i = i + 1) begin
        $fwrite(log_file, "%0d ", matrix_a_in[i*DATAWIDTH +: DATAWIDTH]);
      end
      $fwrite(log_file, "\nmatrix_b_in: ");
      for (i = 0; i < N_SIZE; i = i + 1) begin
        $fwrite(log_file, "%0d ", matrix_b_in[i*DATAWIDTH +: DATAWIDTH]);
      end
      $fwrite(log_file, "\nmatrix_c_out: ");
      for (i = 0; i < N_SIZE; i = i + 1) begin
        $fwrite(log_file, "%0d ", matrix_c_out[i*2*DATAWIDTH +: 2*DATAWIDTH]);
      end
      $fwrite(log_file, "\n----------------------------------------\n");
    end
  end

  // Save output into memory once valid_out is asserted
  integer row;
  always @(posedge clk) begin
    if (valid_out) begin
      for (i = 0; i < N_SIZE; i = i + 1) begin
        matrix_c_mem[row][i] <= matrix_c_out[i*2*DATAWIDTH +: 2*DATAWIDTH];
      end
      row = row + 1;
    end
  end

  // Separate always block for storing A and B on-the-fly from matrix_a_in/matrix_b_in
  integer input_row;
  always @(posedge clk) begin
    if (valid_in) begin
      for (j = 0; j < N_SIZE; j = j + 1) begin
        matrix_a_mem[j][input_row] <= matrix_a_in[j*DATAWIDTH +: DATAWIDTH];
        matrix_b_mem[input_row][j] <= matrix_b_in[j*DATAWIDTH +: DATAWIDTH];
      end
      input_row = input_row + 1;
    end
  end

  // Task to apply matrix stimulus
  task apply_stimulus;
    begin
      row = 0;
      input_row = 0;
      rst_n = 1;
      valid_in = 0;
      #10;
      rst_n = 0;
      #10;
      rst_n = 1;
      #10;
      valid_in = 1;

      matrix_a_in = {16'd1,16'd2,16'd3,16'd4,16'd5};
      matrix_b_in = {16'd1,16'd2,16'd3,16'd4,16'd5};
      #10;
      matrix_a_in = {16'd6,16'd7,16'd8,16'd9,16'd10};
      matrix_b_in = {16'd6,16'd7,16'd8,16'd9,16'd10};
      #10;
      matrix_a_in = {16'd11,16'd12,16'd13,16'd14,16'd15};
      matrix_b_in = {16'd11,16'd12,16'd13,16'd14,16'd15};
      #10;
      matrix_a_in = {16'd16,16'd17,16'd18,16'd19,16'd20};
      matrix_b_in = {16'd16,16'd17,16'd18,16'd19,16'd20};
      #10;
      matrix_a_in = {16'd21,16'd22,16'd23,16'd24,16'd25};
      matrix_b_in = {16'd21,16'd22,16'd23,16'd24,16'd25};
      #10;
      valid_in = 0;
      #100;
    end
  endtask

  // Task to calculate expected results and print all matrices and mismatches
  task calculate_and_print_results;
    begin
      for (i = 0; i < N_SIZE; i = i + 1) begin
        for (j = 0; j < N_SIZE; j = j + 1) begin
          expected_c_mem[i][j] = 0;
          for (k = 0; k < N_SIZE; k = k + 1) begin
            expected_c_mem[i][j] = expected_c_mem[i][j] + matrix_a_mem[j][k] * matrix_b_mem[k][i];
          end
        end
      end

      $fdisplay(log_file, "\n================ Final Matrix A ================");
      for (i = 0; i < N_SIZE; i = i + 1) begin
        $fwrite(log_file, "Row %0d: ", i);
        for (j = 0; j < N_SIZE; j = j + 1) begin
          $fwrite(log_file, "%0d ", matrix_a_mem[i][j]);
        end
        $fwrite(log_file, "\n");
      end

      $fdisplay(log_file, "\n================ Final Matrix B ================");
      for (i = 0; i < N_SIZE; i = i + 1) begin
        $fwrite(log_file, "Row %0d: ", i);
        for (j = 0; j < N_SIZE; j = j + 1) begin
          $fwrite(log_file, "%0d ", matrix_b_mem[i][j]);
        end
        $fwrite(log_file, "\n");
      end

      $fdisplay(log_file, "\n================ Final Matrix C ================");
      for (i = 0; i < N_SIZE; i = i + 1) begin
        $fwrite(log_file, "Row %0d: ", i);
        for (j = 0; j < N_SIZE; j = j + 1) begin
          $fwrite(log_file, "%0d ", matrix_c_mem[i][j]);
        end
        $fwrite(log_file, "\n");
      end

      $fdisplay(log_file, "\n================ Checking Results ================");
      for (i = 0; i < N_SIZE; i = i + 1) begin
        for (j = 0; j < N_SIZE; j = j + 1) begin
          if (matrix_c_mem[i][j] !== expected_c_mem[i][j]) begin
            $fdisplay(log_file, "Mismatch at C[%0d][%0d]: Got %0d, Expected %0d", i, j, matrix_c_mem[i][j], expected_c_mem[i][j]);
          end
        end
      end
      $fdisplay(log_file, "Check complete.");
    end
  endtask

  // Initial block: starts simulation, opens log file, applies stimuli, calculates results, closes file
  initial begin
    log_file = $fopen("output_logs.log", "w");
    apply_stimulus();
    calculate_and_print_results();
    $fclose(log_file);
    $stop;
  end

endmodule
