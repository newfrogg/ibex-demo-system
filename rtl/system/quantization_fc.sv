`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/04/2024 09:50:24 AM
// Design Name: 
// Module Name: quantization_fc
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


module quantization_fc(
        input   clk,
        input   rstn,
        input   en,
        input   [31:0]  data_in,
        output logic    done,
        output  [7:0]   data_out
    );
    
    localparam
        Q_STEP        = 32'h00447EE7,
        Q_RSHIFT      = 24,
        Q_ZERO        = 16'hFFFC;
    
    logic signed [63:0]    out_temp;
    logic [1:0] count;
    
    assign data_out = out_temp[7:0];
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            out_temp    <= 0;
            done        <= 0;
            count       <= 0;
        end
        else begin
            if (!en) begin
                out_temp    <= 0;
                done        <= 0;
                count       <= 0;
            end
            else begin
                if (count == 0) out_temp = (data_in + Q_ZERO);
                else if (count == 1) out_temp <= out_temp * Q_STEP;
                else if (count == 2) begin
                    out_temp    <= out_temp >>> 24;
                    done        <= 1'b1;
                end
                else ;
            end    
        end
    end
    
    /*
    assign data_out = out_temp[7:0];
    always @(*) begin
        out_temp = (data_in + Q_ZERO) * Q_STEP;
        out_temp = out_temp >>> 24;
    end
    
    */    
endmodule