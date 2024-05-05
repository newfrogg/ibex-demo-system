//`timescale 1ns / 1ps
////////////////////////////////////////////////////////////////////////////////////
//// Company: 
//// Engineer: 
//// 
//// Create Date: 04/10/2024 08:57:24 AM
//// Design Name: 
//// Module Name: lstm_layer
//// Project Name: 
//// Target Devices: 
//// Tool Versions: 
//// Description: 
//// 
//// Dependencies: 
//// 
//// Revision:
//// Revision 0.01 - File Created
//// Additional Comments:
//// 
////////////////////////////////////////////////////////////////////////////////////


//module lstm_layer #(parameter NO_UNITS = 32)(
//                    input                   clk,
//                    input                   rstn,
//                    input                   en,
//                    input                   is_last_input,
//                    input                   is_last_data_gate,
//                    input                   is_continued,
//                    input                   is_load_bias,
//                    input                   is_load_cell,
//                    input  [1:0]            type_gate,
//                    input  [31:0]           weight,
//                    input  [31:0]           data_in,
//                    input  [31:0]           bias,
//                    output logic            is_waiting,
//                    output logic            done,
//                    output logic [31:0]     out
//    );
    
//    localparam
//        BUFFER_SIZE         = 32,
        
//        STATE_IDLE          = 3'b000,
//        STATE_ALLOCATE_DATA = 3'b001,
//        STATE_RUN           = 3'b010,
//        STATE_WAIT          = 3'b011,
//        STATE_WBACK         = 3'b100,
//        STATE_FINISH        = 3'b101,
        
//        W_BITWIDTH              = 8,
//        IN_BITWIDTH             = 8,
//        OUT_BITWIDTH            = 32,
//        B_BITWIDTH              = 32,
//        N_WEIGHTS               = 4,
//        N_BIASES                = 4,
//        N_INPUTS                = 1,
        
//        INPUT_GATE          = 2'b00,
//        FORGET_GATE         = 2'b01,
//        CELL_UPDATE         = 2'b10,
//        OUTPUT_GATE         = 2'b11,
        
//        LATENCY             = 1;
        
//    logic   [2:0]           state;
//    logic   [7:0]           index_units;
    
//    logic                                   data_receive_done;
//    logic                                   data_load_done;
//    logic                                   run_done;
//    logic                                   finish_done;
    
//    logic                                   lstm_is_waiting;
//    logic                                   read_bias;
//    // Signals for lstm unit
    
//    logic   [W_BITWIDTH*3-1:0]              weight_bf   [0:N_WEIGHTS-1];
//    logic   [W_BITWIDTH*3-1:0]              input_bf    ;
//    logic   [B_BITWIDTH-1:0]                bias_bf     [0:N_BIASES-1];
    
//    logic   [3:0]                           current_buffer_index;
//    logic   [3:0]                           current_weight_index;
//    logic   [3:0]                           current_input_index;
//    logic   [3:0]                           current_bias_index;  
    
////    logic   [1:0]                           type_read;
    
//    logic                                   lstm_unit_en;
//    logic  [W_BITWIDTH-1:0]                 weights_0_bf    [0:NO_UNITS-1];
//    logic  [W_BITWIDTH-1:0]                 weights_1_bf; 
//    logic  [W_BITWIDTH-1:0]                 weights_2_bf;  
//    logic  [IN_BITWIDTH-1:0]                data_in_0_bf;
//    logic  [IN_BITWIDTH-1:0]                data_in_1_bf;
//    logic  [IN_BITWIDTH-1:0]                data_in_2_bf;
//    logic  [OUT_BITWIDTH-1:0]               pre_sum_bf;
//    logic                                   lstm_unit_done;
//    logic  [OUT_BITWIDTH-1:0]               lstm_unit_result [0:3];
    
//    genvar i;
//    generate
//        for (i = 0; i < NO_UNITS; i = i + 1) begin
//            lstm_unit #(.W_BITWIDTH(W_BITWIDTH), .OUT_BITWIDTH(OUT_BITWIDTH)) u_lstm_unit (
//                .clk(clk),
//                .rstn(rstn),
//                .en(lstm_unit_en),
//                .is_last_input(is_last_input),
//                .is_last_data_gate(is_last_data_gate),
//                .is_continued(is_continued),
//                .is_load_bias(is_load_bias),
//                .is_load_cell(is_load_cell),
//                .type_gate(type_gate),
//                .weights_0(weights_0_bf),
//                .weights_1(weights_1_bf),
//                .weights_2(weights_2_bf),
//                .data_in_0(data_in_0_bf),
//                .data_in_1(data_in_1_bf),
//                .data_in_2(data_in_2_bf),
//                .pre_sum(pre_sum_bf),
//                .is_waiting(lstm_is_waiting),
//                .done(lstm_unit_done),
//                .out(lstm_unit_result)
//            );
//        end
//    endgenerate
    
//    always @(posedge clk or negedge rstn) begin
//        if (!rstn) begin
//            state               <= STATE_IDLE;
            
//            data_receive_done   <= 1'b0;
//            run_done            <= 1'b0;
//            finish_done         <= 1'b0;
//            counter             <= 2'b0;
            
//            weights_0_bf           <= {W_BITWIDTH{1'b0}};
//            weights_1_bf           <= {W_BITWIDTH{1'b0}};
//            weights_2_bf           <= {W_BITWIDTH{1'b0}};
//            data_in_0_bf           <= {IN_BITWIDTH{1'b0}};
//            data_in_1_bf           <= {IN_BITWIDTH{1'b0}};
//            data_in_2_bf           <= {IN_BITWIDTH{1'b0}};
//            pre_sum_bf             <= {OUT_BITWIDTH{1'b0}};
//        end
//    end
    
//endmodule