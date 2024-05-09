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
);

    localparam
        MAX_NO_UNITS            = 16,
        NO_UNITS_LSTM           = 32,
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
        // SIZE_BUFFER             = 10,
        // N_WEIGHTS               = 4,
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
        // CREAD                   = 3'd3,
        LOAD                    = 3'd4,
        
        IGATE                   = 2'd0;
        // FGATE                   = 2'd1,
        // CGATE                   = 2'd2,
        // OGATE                   = 2'd3,
        // WDATA                   = 1'd1;
    
    
    logic [4:0]                             current_timestep;
    logic [4:0]                             current_feature;
    logic [4:0]                             current_sample;
    
    logic [2:0]                             r_state;
    logic [2:0]                             state;
    logic [1:0]                             type_gate;
    
    logic                              current_unit;
    
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

    logic                                   lstm_is_waiting [0:MAX_NO_UNITS-1];
    logic                                   read_bias;
    // Signals for lstm unit
    
    logic   [W_BITWIDTH*3-1:0]              weight_bf   [0:N_GATES*MAX_NO_UNITS-1];
    logic   [IN_BITWIDTH*3-1:0]             input_bf    ;
    logic   [B_BITWIDTH-1:0]                bias_bf     [0:N_GATES*MAX_NO_UNITS-1];

    
    logic   [5:0]                           current_buffer_index;
    logic   [5:0]                           current_weight_index;
    logic   [5:0]                           current_bias_index;  
    logic   [5:0]                           current_no_units;
    logic   [5:0]                           remaining_no_units;
    logic   [1:0]                           current_layer;
    
    logic                                   lstm_unit_en;
    logic  [W_BITWIDTH*3-1:0]               weight      [0:MAX_NO_UNITS-1]; 
    logic  [IN_BITWIDTH*3-1:0]              data_input;
    logic  [OUT_BITWIDTH-1:0]               pre_sum     [0:MAX_NO_UNITS-1];
    logic                                   lstm_finish_step [0:MAX_NO_UNITS-1];
    logic                                   lstm_unit_done  [0:MAX_NO_UNITS-1];
    logic  [7:0]                            lstm_unit_result [0:MAX_NO_UNITS-1];
        
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
            current_unit        <= 1'b0;
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
                        if (current_sample == NO_SAMPLES - 1) is_last_sample <= 1'b1;
                        else is_last_sample <= 1'b0;
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

                            end
                        endcase
                        config_done     <= 1'b1;
                    end
                end
                
                STATE_IDLE: begin
                
                    is_last_timestep    <= 1'b0;
                    data_receive_done   <= 1'b0;
                    data_load_done      <= 1'b0;
                    wb_done             <= 1'b0;
                    run_done            <= 1'b0;
                    finish_done         <= 1'b0;
                    current_unit        <= 1'b0;
                    t_valid             <= 1'b0;
                    is_load_bias        <= 1'b0;
                    is_last_input       <= 1'b0;
                    
                    current_weight_index    <= 6'b0;
                    current_buffer_index    <= 6'b0;
                    current_bias_index      <= 6'b0;

                    if (r_valid) begin
                        type_gate   <= IGATE;
                        state       <= STATE_RDATA;
                        r_state     <= WREAD;
                    end
                end
             
                STATE_RDATA: begin
                    if (data_receive_done && data_load_done) begin
                        data_load_done          <= 1'b0;
                        current_buffer_index    <= 6'b0;
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
                                        else read_bias <= 1'b0;
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
                                        else read_bias <= 1'b0;
                                    end 
                                    else current_buffer_index   <= current_buffer_index + 1; 
                                end 
                            end
                        default: begin
                            r_state <= LOAD;
                        end
                        endcase
                    end
                    else begin
                        // load wi, wf, wc, wo for each unit
                        current_weight_index    <= current_weight_index + 1;
                        current_bias_index      <= current_bias_index + 1;
                        current_buffer_index    <= current_buffer_index + 1;
                        
                        weight[current_buffer_index[3:0]]    <= weight_bf[current_weight_index][W_BITWIDTH*3-1:0];
                        data_input                      <= input_bf[IN_BITWIDTH*3-1:0];
                        pre_sum[current_buffer_index[3:0]]   <= bias_bf[current_bias_index];
                        
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
                            current_unit    <= '0;
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
                    current_unit        <= 1'b0;
                    t_valid             <= 1'b0;
                    is_load_bias        <= 1'b0;
                    is_last_input       <= 1'b0;
//                    read_bias           <= 1'b0;
                    
                    current_weight_index    <= 6'b0;
                    current_buffer_index    <= 6'b0;
                    current_bias_index      <= 6'b0;
                      
                    if (r_valid) begin
                        type_gate   <= IGATE;
                        state       <= STATE_RDATA;
                        r_state     <= WREAD;
                        
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
                                
                                if (current_timestep == NO_TIMESTEPS - 1) is_last_timestep <= 1'b1;
                                else is_last_timestep <= 1'b0;
                                
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
                            else remaining_no_units <= 0;
                            
                            if (current_buffer_index == current_no_units - 1) begin
                                out_data    <= {{24{1'b0}}, lstm_unit_result[current_buffer_index[3:0]]};
                            end
                            else if (current_buffer_index == current_no_units - 2) begin
                                out_data    <= {{16{1'b0}}, lstm_unit_result[current_buffer_index[3:0]+1], lstm_unit_result[current_buffer_index[3:0]]};
                            end
                            else if (current_buffer_index == current_no_units - 3) begin
                                out_data    <= {{8{1'b0}}, lstm_unit_result[current_buffer_index[3:0]+2], lstm_unit_result[current_buffer_index[3:0]+1], lstm_unit_result[current_buffer_index[3:0]]};
                            end
                            else begin
                                out_data    <= {lstm_unit_result[current_buffer_index[3:0]+3], lstm_unit_result[current_buffer_index[3:0]+2], lstm_unit_result[current_buffer_index[3:0]+1], lstm_unit_result[current_buffer_index[3:0]]};
                            end
                            
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

                default: begin
                    state <= STATE_WAIT;
                end
            endcase
        end
    end
    
    
endmodule
