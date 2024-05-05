`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/15/2024 11:06:46 PM
// Design Name: 
// Module Name: tanh_appr
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


module tanh_appr (  
                    input                   clk,
                    input                   rstn,
                    input                   en,
                    input   logic   [31:0]  data_in,    
                    output  logic           done,
                    output  logic   [31:0]  data_out    
        );
                    
            // (1, 7, 24)
        localparam 
//            COEF0   = 32'h80_e8_00_00,  // -0.90625
//            COEF1   = 32'h80_7b_00_00,  // -0.48046875
//            COEF2   = 32'h80_0d_00_00,  // -0.05078125
//            COEF3   = 32'h00_0d_00_00,  // 0.05078125
//            COEF4   = 32'h00_7b_00_00,  // 0.48046875
//            COEF5   = 32'h00_e8_00_00,  // 0.90625
            
            COEF0   = 32'hFFFFA4B9, // -1
            COEF1   = 32'hFFFFAD48, // -0.90625
            COEF2   = 32'hFFFFD425, // -0.48046875
            COEF3   = 32'hFFFFFB5E, // -0.05078125
            COEF4   = 32'h000004A2, // 0.05078125
            COEF5   = 32'h00002BDB, // 0.48046875
            COEF6   = 32'h000052B8, // 0.90625
            COEF7   = 32'h00005B47, // 1
     // (8, 24)
//            RANGE1  = 32'h83_00_00_00,      // -3
//            RANGE2  = 32'h81_E8_F5_C2,      // -1.91
//            RANGE3  = 32'h80_DC_28_F5,      // -0.86
//            RANGE4  = 32'h80_33_33_33,      // -0.2
//            RANGE5  = 32'h00_18_00_00,      // 0.2
//            RANGE6  = 32'h00_DC_28_F5,      // 0.86
//            RANGE7  = 32'h01_E8_F5_C2,      // 1.91
//            RANGE8  = 32'h03_00_00_00;      // 3

            RANGE1  = 32'hFFFEEE2B,     // -3
            RANGE2  = 32'hFFFF51A9,     // -1.91
            RANGE3  = 32'hFFFFB181,     // -0.86
            RANGE4  = 32'hFFFFEDBF,     // -0.2
            RANGE5  = 32'h00001241,     // 0.2
            RANGE6  = 32'h00004E7F,     // 0.86
            RANGE7  = 32'h0000AE57,     // 1.91
            RANGE8  = 32'h000111D5;     // 3
            
     logic signed [31:0]    temp;
     logic [1:0]            count;
     
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
                count <= count + 1;
                if (data_in >= 32'h80000000 && data_in < RANGE1) begin
                    if (count == 0) data_out <= -1;
                    else if (count == 1) done <= 1'b1;
                    else ;
                end
                else if (data_in >= RANGE1 && data_in < RANGE2) begin       
                    if (count == 0) temp <= data_in >>> 5;
                    else if (count == 1) begin
                        data_out    <= temp + COEF1;
                        done        <= 1;
                    end
                    else ;
                end
                else if (data_in >= RANGE2 && data_in < RANGE3) begin
                    if (count == 0) temp <= data_in >>> 2;
                    else if (count == 1) begin
                        data_out    <= temp + COEF2;
                        done        <= 1;
                    end
                    else ;
                end
                else if (data_in >= RANGE3 && data_in < RANGE4) begin
                    if (count == 0) temp <= (data_in >>> 2);
                    if (count == 2'b01) temp <= data_in - temp;
                    else if (count == 2'b10)begin
                        data_out    <= temp + COEF3;
                        done        <= 1;
                    end
                    else ;
                end
                else if (data_in >= RANGE4 && data_in <= 32'hFFFFFFFF) begin
                    if (count == 0) data_out <= data_in;
                    else if (count == 1) begin
                        done        <= 1;
                    end
                    else ;
                end
                else if (data_in >= 32'h00_00_00_00 && data_in < RANGE5) begin
                    if (count == 0) data_out <= data_in;
                    else if (count == 1) begin
                        done        <= 1;
                    end
                    else ;
                end
                else if (data_in >= RANGE5 && data_in < RANGE6) begin
                    if (count == 0) temp <= (data_in >>> 2);
                    else if (count == 2'b01) temp <= data_in - temp;
                    else if (count == 2'b10) begin
                        data_out    <= temp + COEF4;
                        done        <= 1;
                    end
                    else ;
                end
                else if (data_in >= RANGE6 && data_in < RANGE7) begin
                    if (count == 0) temp <= data_in >>> 2;
                    else if (count == 1) begin
                        data_out    <= temp + COEF5;
                        done        <= 1;
                    end
                    else ;
                end
                else if (data_in >= RANGE7 && data_in < RANGE8) begin
                    if (count == 0) temp <= data_in >>> 5;
                    else if (count == 1) begin
                        data_out    <= temp + COEF6;
                        done        <= 1;
                    end
                    else ;
                end
                else if (data_in >= RANGE8 && data_in < 32'h7f_ff_ff_ff) begin
                    if (count == 0) data_out    <= 1;
                    else if (count == 1) done <= 1;
                    else ;
                end
            end
        end
     end
     
//     always @(*) begin
//        if (data_in >= 32'h80000000 && data_in < RANGE1) begin
//            data_out    = -1;
//        end
//        else if (data_in >= RANGE1 && data_in < RANGE2) begin
//            temp        = data_in >>> 5;
//            data_out    = temp + COEF1;
//        end
//        else if (data_in >= RANGE2 && data_in < RANGE3) begin
//            temp        = data_in >>> 2;
//            data_out    = temp + COEF2;
//        end
//        else if (data_in >= RANGE3 && data_in < RANGE4) begin
//            temp        = data_in - (data_in >>> 2);
//            data_out    = temp + COEF3;
//        end
//        else if (data_in >= RANGE4 && data_in <= 32'hFFFFFFFF) begin
//            data_out    = data_in;
//        end
//        else if (data_in >= 32'h00_00_00_00 && data_in < RANGE5) begin
//            data_out    = data_in;
//        end
//        else if (data_in >= RANGE5 && data_in < RANGE6) begin
//            temp        = data_in - (data_in >>> 2);
//            data_out    = temp + COEF4;
//        end
//        else if (data_in >= RANGE6 && data_in < RANGE7) begin
//            temp        = data_in >>> 2;
//            data_out    = temp + COEF5;
//        end
//        else if (data_in >= RANGE7 && data_in < RANGE8) begin
//            temp        = data_in >>> 5;
//            data_out    = temp + COEF6;
//        end
//        else if (data_in >= RANGE8 && data_in < 32'h7f_ff_ff_ff) begin
//            data_out    = 1;
//        end
//     end
endmodule