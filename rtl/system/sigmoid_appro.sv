//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/16/2024 09:33:05 AM
// Design Name: 
// Module Name: sigmoid_appro
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module sigmoid_appro (
                    input                   clk,
                    input                   rstn,
                    input                   en,
                    input   logic   [31:0]  data_in,    
                    output  logic           done,
                    output  logic   [31:0]  data_out  
    );
    
            // IEEE
        localparam 

            COEF2   = 32'h00002523,     // 0.375
            COEF3   = 32'h00002C4F,     // 0.5
            COEF4   = 32'h00003762,     // 0.625
            // COEF5   = 32'h00004AC5,     // 0.8375

            RANGE2  = 32'hFFFF2D8B,             // -2.375
            RANGE3  = 32'hFFFFA763,             // -1
            RANGE4  = 32'h0000589D,             // 1
            RANGE5  = 32'h0000D275;             // 2.375

        
        logic signed [31:0] temp;
        logic [1:0]         count;
                // verilator lint_off CMPCONST
        
        always @ (posedge clk or negedge rstn) begin
            if (!rstn) begin
                data_out    <= 32'h0;
                count       <= 0;
                done        <= 0;
            end
            else begin
                if (!en) begin
                    count       <= 0;
                    done        <= 0;
                end
                else begin
                    count <= count + 1'b1;
                    if (data_in >= 32'h80000000 && data_in < RANGE2) begin
                        if (count == 0) begin 
                            data_out  <= 0;
                            done <= 1'b1;
                        end 
                        else ;
                    end
                    else if (data_in >= RANGE2 && data_in < RANGE3) begin                    
                        if (count == 0) temp <= data_in >>> 3;
                        else if (count == 2'b01) temp <= temp + COEF2; 
                        else if (count == 2'b10) begin
                            data_out <= {{8'h00}, temp[23:0]};
                            done        <= 1'b1;
                        end
                        else ;
                    end
                    // verilator lint_off UNSIGNED
                    else if (data_in >= RANGE3 && data_in <= 32'hffffffff) begin
                        if (count == 0) temp <= data_in >>> 2;
                        else if (count == 2'b01) temp    <= temp + COEF3;
                        else if (count == 2'b10) begin
                            data_out <= {{8'h00}, temp[23:0]};
                            done        <= 1'b1;
                        end
                        else ;
                    end
                    // verilator lint_off UNSIGNED
                    else if (data_in >= 32'h0 && data_in < RANGE4) begin
                        if (count == 0) temp <= data_in >>> 2;
                        else if (count == 2'b01) temp    <= temp + COEF3;
                        else if (count == 2'b10) begin
                            data_out    <= {{8'h00}, temp[23:0]};
                            done        <= 1'b1;
                        end
                        else ;
                    end
                    else if (data_in >= RANGE4 && data_in < RANGE5) begin
                        if (count == 0) temp <= data_in >>> 3;
                        else if (count == 2'b01) temp    <= temp + COEF4;
                        else if (count == 2'b10) begin
                            data_out    <= {{8'h00}, temp[23:0]};
                            done        <= 1'b1;
                        end
                        else ;
                    end
                    // verilator lint_off UNSIGNED
                    else if (data_in >= RANGE5 && data_in <= 32'h7f_ff_ff_ff) begin
                        if (count == 0) begin
                            data_out    <= data_in;
                            done        <= 1'b1;
                        end
                        else ;
                    end
                end
            end
         end

endmodule
