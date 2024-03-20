module and2 # (
    parameter int Width = 1
) (
    input logic clk,

    input logic start_i,
    input logic [Width-1:0] in0_i,
    input logic [Width-1:0] in1_i,

    output logic [Width-1:0] out_o,
    output logic ready_o

);
    logic [Width-1:0] and_result;

    always_ff @(posedge clk) begin
        // Check if start_i is high
        if (start_i == 1'b1) begin
            // Perform AND operation
            and_result <= in0_i & in1_i;
            // Set ready_o to indicate operation completion
            ready_o <= 1'b1;
        end else begin
            // Reset ready_o if start_i is low
            ready_o <= 1'b0;
        end
    end

    // Assign the result to out_o
    assign out_o = and_result;

endmodule