module and_gate # (
    parameter int DataWidth = 1
) (
    input logic clk,

    input logic enable_i,
    input logic [DataWidth-1:0] a_i,
    input logic [DataWidth-1:0] b_i,

    output logic [DataWidth-1:0] out_o,
    output logic valid_o

);
    logic [DataWidth-1:0] result;

    always_ff @(posedge clk) begin
        // Check if start_i is high
        if (enable_i == 1'b1) begin
            // Perform AND operation
            result <= a_i & b_i;
            // Set ready_o to indicate operation completion
            valid_o <= 1'b1;
        end else begin
            // Reset ready_o if start_i is low
            valid_o <= 1'b0;
        end
    end

    // Assign the result to out_o
    assign out_o = result;

endmodule
