/////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/16/2024 02:19:31 PM
// Design Name: 
// Module Name: tanh_appr_16
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


module tanh_appr_16 #(  parameter IN_BITWIDTH = 16, 
                        parameter OUT_BITWIDTH = 8)(
                        input   logic   [15:0]  data_in,    //  16 bits input
                        output  logic   [7:0]   data_out    // 8 bits output
    );
    
        localparam 

            
            COEF0   = 16'hbf68,
            COEF1   = 16'hbef6,
            COEF2   = 16'hbd50,
            COEF3   = 16'h3d50,
            COEF4   = 16'h3ef6,
            COEF5   = 16'h3f68,

            RANGE1  = 16'hc040,     // -3
            RANGE2  = 16'hbff4,     // -1.91
            RANGE3  = 16'hbf5c,     // -0.86
            RANGE4  = 16'hbe4d,     // -0.2
            RANGE5  = 16'h3e4d,     // 0.2
            RANGE6  = 16'h3f5c,     // 0.86
            RANGE7  = 16'h3ff4,     // 1.91
            RANGE8  = 16'h4040;     // 3
            
     logic  [31:0]  temp;
     always @(*) begin
        if (data_in >= RANGE1) begin
            data_out    = -1;
        end
        else if (data_in >= RANGE2 && data_in < RANGE1) begin
            temp        = data_in >>> 5;
            data_out    = {1'b1, {temp[14:8] + COEF0[14:8]} };
        end
        else if (data_in >= RANGE3 && data_in < RANGE2) begin
            temp        = data_in >>> 2;
            data_out    = {1'b1, {temp[14:8] + COEF1[14:8]} };
        end
        else if (data_in >= RANGE4 && data_in < RANGE3) begin
            temp        = data_in + (data_in >>> 2);
            data_out    = {1'b1, {temp[14:8] + COEF2[14:8]} };
        end
        else if (data_in >= 16'h80_00 && data_in < RANGE4) begin
            data_out    = data_in[15:8];
        end
        else if (data_in >= 16'h00_00 && data_in < RANGE5) begin
            data_out    = data_in[15:8];
        end
        else if (data_in >= RANGE5 && data_in < RANGE6) begin
            temp        = data_in - (data_in >>> 2);
            data_out    = {1'b0, {temp[14:8] + COEF3[14:8]} };
        end
        else if (data_in >= RANGE6 && data_in < RANGE7) begin
            temp        = data_in >>> 2;
            data_out    = {1'b0, {temp[14:8] + COEF4[14:8]} };
        end
        else if (data_in >= RANGE7 && data_in < RANGE8) begin
            temp        = data_in >>> 5;
            data_out    = {1'b1, {temp[14:8] + COEF5[14:8]} };
        end
        else if (data_in >= RANGE8 && data_in < 16'h7f_ff) begin
            data_out    = 1;
        end
    end
    
endmodule
