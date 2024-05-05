`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/05/2024 03:54:04 PM
// Design Name: 
// Module Name: controller
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


module controller(
    input               clk,
    input               rstn,
    input               r_valid,
    input               is_last_data_gate,
    input [31:0]        data_in,
    output logic        r_data,
    output logic        w_valid,
    output logic        t_valid,
    output logic [31:0] out_data
//    output logic [2:0]  o_state,
//    output logic [2:0]  o_lstm_state,
//    output logic        o_lstm_finish_step,
//    output logic        o_lstm_is_continued,
//    output logic        o_lstm_is_waiting,
//    output logic [7:0]  weights [0:2],
//    output logic [7:0]  inputs  [0:2],
//    output logic [31:0] bias,
//    output logic        o_is_load_bias,
//    output logic        o_is_last_timestep,
//    output logic [7:0]  o_index,
//    output logic [1:0]  o_mac_state,
//    output logic        o_is_last_input,
//    output logic [31:0] o_lstm_accu_bf,
//    output logic [31:0] o_mac_result,
//    output logic [1:0]  o_type_gate,
//    output logic [1:0]  o_gate,
//    output logic [31:0] o_value_gate [0:3],
//    output logic        o_is_load_cell,
//    output logic [2:0]  o_r_state,
//    output logic [4:0]  o_current_timestep,
//    output logic [7:0]  o_lstm_unit_result [0:3],
//    output logic [6:0]  o_current_no_units,
//    output logic [6:0]  o_remaining_no_units,
//    output logic        o_read_bias,
//    output logic [1:0]  o_current_layer,
//    output logic [4:0]  o_current_sample,
//    output logic [1:0]  o_count_gate,
//    output logic [1:0]  o_current_unit,
//    output logic        o_is_last_sample,
//    output logic [31:0] o_accu_input_bf,
//    output logic [31:0] o_accu_forget_bf,
//    output logic [31:0] o_accu_cell_bf,
//    output logic [31:0] o_accu_output_bf,
//    output logic [31:0] o_mac_accu_bf,
//    output logic [2:0]  o_mac_index,
//    output logic [31:0] o_mac_prev_sum_bf,
//    output logic [31:0] o_lstm_cell_state_bf,
//    output logic [31:0] o_lstm_hidden_state_bf,
//    output logic [7:0]  o_lstm_cell_state,
//    output logic [7:0]  o_lstm_hidden_state,
//    output logic [31:0] o_lstm_q_di_lstm_state,
//    output logic [7:0]  o_lstm_q_do_lstm_state,
//    output logic        o_lstm_type_state,
//    output logic [31:0] o_lstm_q_di_fc,
//    output logic [7:0]  o_lstm_q_do_fc,
//    output logic [31:0] o_lstm_di_current_unit_tanh_bf,
//    output logic [31:0] o_lstm_do_current_unit_tanh_bf,
//    output logic [31:0] o_lstm_di_current_unit_sigmoid_bf,
//    output logic [31:0] o_lstm_do_current_unit_sigmoid_bf,
//    output logic o_sigmoid_en,
//    output logic o_sigmoid_done,
//    output logic [1:0]  o_sigmoid_count
);

    localparam
        MAX_NO_UNITS            = 16,
        NO_UNITS_LSTM           = 16,
        NO_UNITS_FC             = 10,
        NO_FEATURES             = 10,
        NO_TIMESTEPS            = 28,
        NO_SAMPLES              = 1,
        
        INIT                    = 0,
        LSTM                    = 1,
        FC                      = 2,
        
        W_BITWIDTH              = 8,
        IN_BITWIDTH             = 8,
        OUT_BITWIDTH            = 32,
        B_BITWIDTH              = 32,
        SIZE_BUFFER             = 10,
        N_WEIGHTS               = 4,
        N_BIASES                = 4,
        N_INPUTS                = 1,
        N_GATES                 = 4,
        
        STATE_IDLE              = 3'd0,
        STATE_CONFIG            = 3'd1,
        STATE_RDATA             = 3'd2,
        STATE_RUN               = 3'd3,
        STATE_WBACK             = 3'd4,
        STATE_FINISH            = 3'd5,
        STATE_WAIT              = 3'd6,
        
        
        WREAD                   = 3'd0,
        IREAD                   = 3'd1,
        BREAD                   = 3'd2,
        CREAD                   = 3'd3,
        LOAD                    = 3'd4,
        
        IGATE                   = 2'd0,
        FGATE                   = 2'd1,
        CGATE                   = 2'd2,
        OGATE                   = 2'd3,
        
        LDATA                   = 1'd0,
        WDATA                   = 1'd1;
    
    
    logic [4:0]                             current_timestep;
    logic [4:0]                             current_feature;
    logic [4:0]                             current_sample;
    
    logic [2:0]                             r_state;
    logic                                   w_state;
    logic [2:0]                             state;
    logic [1:0]                             type_gate;
    
    logic [1:0]                             current_unit;
    
    logic                                   data_receive_done;
    logic                                   data_load_done;
    logic                                   config_done;
    logic                                   run_done;
    logic                                   wb_done;
    logic                                   finish_done;
    
    logic                                   is_continued;
    logic                                   is_last_input;
    logic                                   is_last_timestep;
    logic                                   is_last_sample;
    logic                                   is_load_bias;
    logic                                   is_load_cell;
    logic                                   lstm_is_waiting [0:MAX_NO_UNITS-1];
    logic                                   read_bias;
    // Signals for lstm unit
    
    logic   [W_BITWIDTH*3-1:0]              weight_bf   [0:N_GATES*MAX_NO_UNITS-1];
    logic   [IN_BITWIDTH*3-1:0]             input_bf    ;
    logic   [B_BITWIDTH-1:0]                bias_bf     [0:N_GATES*MAX_NO_UNITS-1];

    
    logic   [7:0]                           current_buffer_index;
    logic   [7:0]                           current_weight_index;
    logic   [7:0]                           current_input_index;
    logic   [7:0]                           current_bias_index;  
    
//    logic   [7:0]                           max_buffer_index;
    logic   [6:0]                           current_no_units;
    logic   [6:0]                           remaining_no_units;
    logic   [1:0]                           current_layer;
    
    logic                                   lstm_unit_en;
    logic  [W_BITWIDTH*3-1:0]               weight      [0:MAX_NO_UNITS-1]; 
    logic  [IN_BITWIDTH*3-1:0]              data_input;
    logic  [OUT_BITWIDTH-1:0]               pre_sum     [0:MAX_NO_UNITS-1];
    logic                                   lstm_finish_step [0:MAX_NO_UNITS-1];
    logic                                   lstm_unit_done  [0:MAX_NO_UNITS-1];
    logic  [7:0]                            lstm_unit_result [0:MAX_NO_UNITS-1];
    
    
//    assign o_state = state;
//    assign weights[0] = genblk1[2].u_lstm_unit.u_mac.weights_0;
//    assign weights[1] = genblk1[2].u_lstm_unit.u_mac.weights_1;
//    assign weights[2] = genblk1[2].u_lstm_unit.u_mac.weights_2;
//    assign inputs[0]  = genblk1[2].u_lstm_unit.u_mac.data_in_0;
//    assign inputs[1]  = genblk1[2].u_lstm_unit.u_mac.data_in_1;
//    assign inputs[2]  = genblk1[2].u_lstm_unit.u_mac.data_in_2;
//    assign bias       = genblk1[2].u_lstm_unit.u_mac.pre_sum;
//    assign o_is_load_bias = is_load_bias;
//    assign o_is_last_timestep = is_last_timestep;
//    assign o_index    = current_buffer_index;
//    assign o_mac_state = genblk1[2].u_lstm_unit.u_mac.state;
//    assign o_is_last_input = is_last_input;
//    assign o_lstm_accu_bf = genblk1[2].u_lstm_unit.accu_bf[0];
//    assign o_mac_result = genblk1[2].u_lstm_unit.mac_result;    
//    assign o_type_gate  = genblk1[2].u_lstm_unit.type_gate;
//    assign o_gate = genblk1[2].u_lstm_unit.gate;
//    assign o_value_gate[0] = genblk1[2].u_lstm_unit.input_gate[0];
//    assign o_value_gate[1] = genblk1[2].u_lstm_unit.forget_gate[0];
//    assign o_value_gate[2] = genblk1[2].u_lstm_unit.cell_update[0];
//    assign o_value_gate[3] = genblk1[2].u_lstm_unit.output_gate[0];
//    assign o_is_load_cell = is_load_cell;
//    assign o_r_state = r_state;
////    assign o_ht = genblk1[2].u_lstm_unit.hidden_state[0];
//    assign o_lstm_state = genblk1[2].u_lstm_unit.state;
//    assign o_lstm_finish_step = genblk1[2].u_lstm_unit.finish_step;
//    assign o_current_timestep = current_timestep;
//    assign o_lstm_unit_result[0] = lstm_unit_result[0];
//    assign o_lstm_unit_result[1] = lstm_unit_result[1];
//    assign o_lstm_unit_result[2] = lstm_unit_result[2];
//    assign o_lstm_unit_result[3] = lstm_unit_result[3];
//    assign o_current_no_units = current_no_units;
//    assign o_remaining_no_units = remaining_no_units;
//    assign o_read_bias = read_bias;
//    assign o_current_layer = current_layer;
//    assign o_current_sample = current_sample;
//    assign o_count_gate = genblk1[2].u_lstm_unit.count_gate;
//    assign o_current_unit = current_unit;
//    assign o_is_last_sample = is_last_sample;
    
//    assign o_accu_input_bf = genblk1[2].u_lstm_unit.accu_input_bf[0];
//    assign o_accu_forget_bf = genblk1[2].u_lstm_unit.accu_forget_bf[0];
//    assign o_accu_cell_bf = genblk1[2].u_lstm_unit.accu_cell_bf[0];
//    assign o_accu_output_bf = genblk1[2].u_lstm_unit.accu_output_bf[0];
//    assign o_mac_accu_bf = genblk1[2].u_lstm_unit.u_mac.accu_bf;
//    assign o_mac_index = genblk1[2].u_lstm_unit.u_mac.index;
//    assign o_mac_prev_sum_bf = genblk1[2].u_lstm_unit.u_mac.prev_sum_bf;

//    assign o_lstm_cell_state_bf = genblk1[2].u_lstm_unit.cell_state_bf;
//    assign o_lstm_hidden_state_bf = genblk1[2].u_lstm_unit.hidden_state_bf;
//    assign o_lstm_cell_state = genblk1[2].u_lstm_unit.cell_state[0];
//    assign o_lstm_hidden_state = genblk1[2].u_lstm_unit.hidden_state[0];
//    assign o_lstm_q_di_lstm_state   = genblk1[2].u_lstm_unit.q_di_lstm_state;
//    assign o_lstm_q_do_lstm_state   = genblk1[2].u_lstm_unit.q_do_lstm_state;
//    assign o_lstm_type_state   = genblk1[2].u_lstm_unit.type_state;
//    assign o_lstm_q_di_fc   = genblk1[2].u_lstm_unit.q_di_fc;
//    assign o_lstm_q_do_fc   = genblk1[2].u_lstm_unit.q_do_fc;
//    assign o_lstm_di_current_unit_tanh_bf = genblk1[2].u_lstm_unit.di_current_unit_tanh_bf;
//    assign o_lstm_do_current_unit_tanh_bf = genblk1[2].u_lstm_unit.do_current_unit_tanh_bf;
//    assign o_lstm_di_current_unit_sigmoid_bf = genblk1[2].u_lstm_unit.di_current_unit_sigmoid_bf;
//    assign o_lstm_do_current_unit_sigmoid_bf = genblk1[2].u_lstm_unit.do_current_unit_sigmoid_bf;
//    assign o_sigmoid_done = genblk1[2].u_lstm_unit.u_sigmoid.done;
//    assign o_sigmoid_en = genblk1[2].u_lstm_unit.u_sigmoid.en;
//    assign o_sigmoid_count = genblk1[2].u_lstm_unit.u_sigmoid.count;
    
    genvar i;
    
    generate
        for (i = 0; i < MAX_NO_UNITS; i = i+1) begin
            lstm_unit #(.W_BITWIDTH(W_BITWIDTH), .OUT_BITWIDTH(OUT_BITWIDTH)) u_lstm_unit (
                .clk(clk),
                .rstn(rstn),
                .en(lstm_unit_en),
                .is_last_input(is_last_input),
                .is_last_data_gate(is_last_data_gate),
                .is_last_timestep(is_last_timestep),
                .is_last_sample(is_last_sample),
                .is_continued(is_continued),
                .is_load_bias(is_load_bias),
                .type_gate(type_gate),
                .current_unit(current_unit),
                .current_layer(current_layer),
                .weight(weight[i]),
                .data_in(data_input),
                .pre_sum(pre_sum[i]),
                .is_waiting(lstm_is_waiting[i]),
                .finish_step(lstm_finish_step[i]),
                .done(lstm_unit_done[i]),
                .out(lstm_unit_result[i])
            );
        end
    endgenerate
       

    // implement FSM for controller
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            state               <= STATE_CONFIG;
            
            data_receive_done   <= 1'b0;
            run_done            <= 1'b0;
            config_done         <= 1'b0;
            wb_done             <= 1'b0;
            finish_done         <= 1'b0;
            current_unit        <= 2'b0;
            current_timestep    <= 0;
            current_layer       <= INIT;
            current_no_units    <= 0;
            remaining_no_units  <= NO_UNITS_LSTM;
            current_sample      <= 0;
            is_last_sample      <= 1'b0;
        end
        else begin
            case(state)
                STATE_CONFIG: begin
                    if (config_done) begin
                        if (current_layer == LSTM)  state   <= STATE_IDLE;
                        else begin
                            state   <= STATE_WAIT;
                            r_data  <= 1'b1;
                        end
                        read_bias   <= 1'b0;
                        config_done <= 1'b0;
                    end
                    else begin
                        if (current_sample == NO_SAMPLES - 1) is_last_sample = 1'b1;
                        else is_last_sample = 1'b0;
                        case(current_layer)
                            INIT: begin
                                current_layer           <= LSTM;
                                current_timestep        <= 0;
                                current_feature         <= 0;
                                if (NO_UNITS_LSTM > MAX_NO_UNITS) begin
                                    current_no_units    <= MAX_NO_UNITS;
                                    remaining_no_units  <= NO_UNITS_LSTM - MAX_NO_UNITS;
                                end
                                else begin
                                    current_no_units    <= NO_UNITS_LSTM;
                                    remaining_no_units  <= 0;
                                end
                            end
                            LSTM: begin
                                current_layer           <= FC;
                                if (NO_UNITS_FC > MAX_NO_UNITS) begin
                                    current_no_units    <= MAX_NO_UNITS;
                                    remaining_no_units  <= NO_UNITS_FC - MAX_NO_UNITS;    
                                end
                                else begin
                                    current_no_units    <= NO_UNITS_FC;
                                    remaining_no_units  <= 0;
                                end
//                                remaining_no_units      <= 0;   
                            end
                        endcase
                        config_done     <= 1'b1;
                    end
                end
                
                STATE_IDLE: begin
                
                    is_last_timestep    <= 1'b0;
//                    is_last_sample      <= 1'b0;
                    data_receive_done   <= 1'b0;
                    data_load_done      <= 1'b0;
                    wb_done             <= 1'b0;
                    run_done            <= 1'b0;
                    finish_done         <= 1'b0;
                    current_unit        <= 2'b0;
                    t_valid             <= 1'b0;
                    is_load_bias        <= 1'b0;
                    is_last_input       <= 1'b0;
//                    read_bias           <= 1'b0;
                    
                    current_weight_index    <= 8'b0;
                    current_input_index     <= 8'b0;
                    current_buffer_index    <= 8'b0;
                    current_bias_index      <= 8'b0;
//                      current_sample          <= 0;
//                    if (current_layer == LSTM) current_timestep        <= 0;
//                    else ;
                    
                    if (r_valid) begin
                        type_gate   <= IGATE;
                        state       <= STATE_RDATA;
                        r_state     <= WREAD;
                        w_state     <= LDATA;
                    end
                end
             
                STATE_RDATA: begin
                    if (data_receive_done && data_load_done) begin
                        data_load_done          <= 1'b0;
                        current_buffer_index    <= 8'b0;
                        r_state                 <= LOAD;
                        state                   <= STATE_RUN;
                    end
                    else if (!data_receive_done) begin       
                        case(r_state)
                            WREAD: begin
                                weight_bf[current_buffer_index] <= data_in[W_BITWIDTH*3-1:0];
                                if (current_layer == LSTM) begin
                                    if (current_buffer_index == N_GATES*current_no_units-1) begin // max_buffer = N_GATES*NO_UNITS-1
                                        current_buffer_index    <= 0;
                                        r_state                 <= IREAD;
                                    end 
                                    else current_buffer_index   <= current_buffer_index + 1;
                                end
                                else begin
                                    if (current_buffer_index == current_no_units-1) begin // max_buffer = N_GATES*NO_UNITS-1
                                        current_buffer_index    <= 0;
                                        r_state                 <= IREAD;
                                    end 
                                    else current_buffer_index   <= current_buffer_index + 1;
                                end
                            end
                            IREAD: begin
                                input_bf                    <= data_in[IN_BITWIDTH*3-1:0];
                                if (current_buffer_index == N_INPUTS-1) begin
                                    current_buffer_index    <= 0;
                                    if (read_bias) begin
                                        r_state             <= LOAD;
                                        data_receive_done   <= 1'b1;
                                        r_data              <= 1'b0;
                                    end
                                    else r_state <= BREAD;
                                end 
                                else current_buffer_index   <= current_buffer_index + 1;
                            end
                            BREAD: begin
                                bias_bf[current_buffer_index]   <= data_in;
                                is_load_bias                    <= 1'b1;
                                if (current_layer == LSTM) begin
                                    if (current_buffer_index == N_GATES*current_no_units-1) begin
                                        current_buffer_index    <= 0;
                                        r_state                 <= LOAD;
                                        data_receive_done       <= 1'b1;
                                        r_data                  <= 1'b0;
                                        if (remaining_no_units == 0) read_bias <= 1'b1;
                                        else read_bias = 1'b0;
                                    end 
                                    else current_buffer_index   <= current_buffer_index + 1; 
                                end
                                else begin
                                    if (current_buffer_index == current_no_units-1) begin
                                        current_buffer_index    <= 0;
                                        r_state                 <= LOAD;
                                        data_receive_done       <= 1'b1;
                                        r_data                  <= 1'b0;
                                        if (remaining_no_units == 0) read_bias <= 1'b1;
                                        else read_bias = 1'b0;
                                    end 
                                    else current_buffer_index   <= current_buffer_index + 1; 
                                end 
                            end
                        endcase
                    end
                    else begin
                        // load wi, wf, wc, wo for each unit
                        current_weight_index    <= current_weight_index + 1;
                        current_bias_index      <= current_bias_index + 1;
                        current_buffer_index    <= current_buffer_index + 1;
                        
                        weight[current_buffer_index]    <= weight_bf[current_weight_index][W_BITWIDTH*3-1:0];
                        data_input                      <= input_bf[IN_BITWIDTH*3-1:0];
                        pre_sum[current_buffer_index]   <= bias_bf[current_bias_index];
                        
                        if (current_buffer_index == current_no_units-1) begin
                            current_buffer_index    <= 0;                            
                            data_load_done          <= 1'b1;
                            if (current_layer == LSTM) begin
                                if (current_weight_index == N_GATES*current_no_units-1)  is_last_input <= 1'b1;
                                else is_last_input      <= 1'b0;
                            end 
                            else begin
                                is_last_input <= 1'b1;
                            end
                        end
                    end
                end
                
                STATE_RUN: begin
                     if (run_done) begin
                        is_continued    <= 1'b0;
                        run_done        <= 1'b0;
                        if (is_last_input && is_last_data_gate) begin
                            state           <= STATE_WBACK;
                            lstm_unit_en    <= 1'b0;
//                            w_valid         <= 1'b1;
                            current_unit    <= 0;
                            case(current_layer)
                                LSTM:   remaining_no_units      <= NO_UNITS_LSTM;
                                FC:     remaining_no_units      <= NO_UNITS_FC;
                            endcase
                        end
                        else begin
                            case(is_last_input) 
                                0: begin
                                    state           <= STATE_RDATA;
                                    r_state         <= LOAD;
                                    type_gate       <= type_gate+1;
                                end
                                1: begin
                                    state           <= STATE_WAIT;
                                    r_data          <= 1'b1;
                                end
                            endcase
                        end                        
                     end
                     else begin
                        lstm_unit_en    <= 1'b1;
                        
                        if (lstm_finish_step[current_no_units-1] || lstm_unit_done[current_no_units-1] || lstm_is_waiting[current_no_units-1]) begin
                            run_done        <= 1'b1;
                            is_continued    <= 1'b0;
                        end
                        else is_continued   <= 1'b1;
                     end
                end  
                
                STATE_WAIT: begin
//                    is_last_timestep    <= 1'b0;
                    data_receive_done   <= 1'b0;
                    data_load_done      <= 1'b0;
                    wb_done             <= 1'b0;
                    run_done            <= 1'b0;
                    finish_done         <= 1'b0;
                    current_unit        <= 2'b0;
                    t_valid             <= 1'b0;
                    is_load_bias        <= 1'b0;
                    is_load_cell        <= 1'b0;
                    is_last_input       <= 1'b0;
//                    read_bias           <= 1'b0;
                    
                    current_weight_index    <= 8'b0;
                    current_input_index     <= 8'b0;
                    current_buffer_index    <= 8'b0;
                    current_bias_index      <= 8'b0;
                      
                    if (r_valid) begin
                        type_gate   <= IGATE;
                        state       <= STATE_RDATA;
                        r_state     <= WREAD;
                        w_state     <= LDATA;
                        
                        case(current_layer)
                            LSTM: begin
                                if (remaining_no_units == 0) begin
                                    if (current_feature == NO_FEATURES - 1) begin
                                        current_feature     <= 0;
                                        current_unit        <= 0;
                                    end
                                    else begin
                                        current_feature <= current_feature + 1;
                                        current_unit    <= 0;
                                    end
                                    
                                    if (NO_UNITS_LSTM > MAX_NO_UNITS) begin
                                        current_no_units    <= MAX_NO_UNITS;
                                        remaining_no_units  <= NO_UNITS_LSTM - MAX_NO_UNITS;
                                    end
                                    else begin
                                        current_no_units    <= NO_UNITS_LSTM;
                                        remaining_no_units  <= 0;
                                    end
                                    current_unit            <= 0;
                                end
                                else if (remaining_no_units > MAX_NO_UNITS) begin
                                    current_no_units    <= MAX_NO_UNITS;
                                    remaining_no_units  <= remaining_no_units - MAX_NO_UNITS; 
                                    current_unit        <= current_unit + 1;
                                end
                                else begin
                                    current_no_units    <= remaining_no_units;
                                    remaining_no_units  <= 0;
                                    current_unit        <= current_unit + 1;
                                end
                                
                                if (current_timestep == NO_TIMESTEPS - 1) is_last_timestep = 1'b1;
                                else is_last_timestep = 1'b0;
                                
//                                if (current_sample == NO_SAMPLES - 1) is_last_sample = 1'b1;
//                                else is_last_sample = 1'b0;
                            end
                            FC: begin
                                if (remaining_no_units == 0) begin
                                    if (NO_UNITS_FC > MAX_NO_UNITS) begin
                                        current_no_units    <= MAX_NO_UNITS;
                                        remaining_no_units  <= NO_UNITS_FC - MAX_NO_UNITS;
                                    end
                                    else begin
                                        current_no_units    <= NO_UNITS_FC;
                                        remaining_no_units  <= 0;
                                    end
                                    current_unit            <= 0;
                                end
                                else if (remaining_no_units > MAX_NO_UNITS) begin
                                    current_no_units    <= MAX_NO_UNITS;
                                    remaining_no_units  <= remaining_no_units - MAX_NO_UNITS; 
                                    current_unit        <= current_unit + 1;
                                end
                                else begin
                                    current_no_units    <= remaining_no_units;
                                    current_unit        <= current_unit + 1;
                                    remaining_no_units  <= 0;
                                end
//                                if (current_sample == NO_SAMPLES - 1) is_last_sample = 1'b1;
//                                else is_last_sample = 1'b0;
                            end
                        endcase
                    end
                end
                
                STATE_WBACK: begin
                    if (wb_done) begin
                        w_valid         <= 0;
                        wb_done         <= 0;
                        read_bias       <= 0;
                        current_unit    <= 0;
                        if (current_layer == LSTM) begin
                            if (current_timestep == NO_TIMESTEPS-1) begin
                                state               <= STATE_CONFIG;
                                current_layer       <= LSTM;
                            end
                            else begin
                                current_timestep        <= current_timestep + 1;
                                current_feature         <= 0;
                                state                   <= STATE_WAIT;
                                remaining_no_units      <= NO_UNITS_LSTM;
                            end
                        end
                        else begin
                            if (current_sample == NO_SAMPLES -1) begin
                                current_sample      <= 0;
                                state               <= STATE_FINISH;
                            end
                            else begin
                                current_sample      <= current_sample + 1;
                                state               <= STATE_CONFIG;
                                current_layer       <= INIT;
                                remaining_no_units  <= NO_UNITS_LSTM;
                            end
                        end 
                    end
                    else begin
                        if (remaining_no_units != 0) begin
                            w_valid                 <= 1'b1;

                            if (current_buffer_index >= MAX_NO_UNITS - 4) begin
                                current_buffer_index    <= 0;
                                current_unit            <= current_unit + 1;
                            end
                            else current_buffer_index <= current_buffer_index + 4;
                            
                            if (remaining_no_units >= 4) remaining_no_units      <= remaining_no_units - 4;
                            else remaining_no_units = 0;
                            
                            if (current_buffer_index == current_no_units - 1) begin
                                out_data    <= {{24{1'b0}}, lstm_unit_result[current_buffer_index]};
                            end
                            else if (current_buffer_index == current_no_units - 2) begin
                                out_data    <= {{16{1'b0}}, lstm_unit_result[current_buffer_index+1], lstm_unit_result[current_buffer_index]};
                            end
                            else if (current_buffer_index == current_no_units - 3) begin
                                out_data    <= {{8{1'b0}}, lstm_unit_result[current_buffer_index+2], lstm_unit_result[current_buffer_index+1], lstm_unit_result[current_buffer_index]};
                            end
                            else begin
                                out_data    <= {lstm_unit_result[current_buffer_index+3], lstm_unit_result[current_buffer_index+2], lstm_unit_result[current_buffer_index+1], lstm_unit_result[current_buffer_index]};
                            end
                            
//                            if (current_layer == LSTM) begin
                                
//                            end
//                            else begin
                            
//                            end
                        end
                        else begin
                            w_valid <= 0;
                            wb_done <= 1;
                            out_data    <= {32{1'b0}};
                        end
                    end
                end
                
                STATE_FINISH: begin
                    if (finish_done) begin
                        state           <= STATE_IDLE;
                        finish_done     <= 1'b0;
                        t_valid         <= 1'b1;
                    end
                    else begin
                        finish_done     <= 1'b1;
                    end
                end
            endcase
        end
    end
    
    
endmodule