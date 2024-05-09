
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/05/2024 03:52:50 PM
// Design Name: 
// Module Name: lstm_unit
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


module lstm_unit #( parameter W_BITWIDTH = 8,
                    parameter IN_BITWIDTH = W_BITWIDTH,
                    parameter OUT_BITWIDTH = 32,
                    parameter PREV_SUM_BITWIDTH = OUT_BITWIDTH)(
                    input                                   clk,
                    input                                   rstn,
                    input                                   en,
                    input                                   is_last_input,
                    input                                   is_last_data_gate,
                    input                                   is_last_timestep,
                    input                                   is_last_sample,
                    input                                   is_continued,
                    input                                   is_load_bias,
                    input  [1:0]                            type_gate,
                    input                                   current_unit,
                    input  [1:0]                            current_layer,
                    input  [W_BITWIDTH*3-1:0]               weight,
                    input  [IN_BITWIDTH*3-1:0]              data_in,
                    input  [PREV_SUM_BITWIDTH-1:0]          pre_sum,
                    output logic                            is_waiting,
                    output logic                            finish_step,
                    output logic                            done,
                    output logic [7:0]                      out
    );
    
    localparam
        // MAX_NO_UNITS        = 16,
        // NO_UNITS_LSTM       = 32,
        // NO_UNITS_FC         = 10,
        QUANTIZE_SIZE       = 8,
        BUFFER_SIZE         = 32,
        // NO_UNITS            = NO_UNITS_LSTM/MAX_NO_UNITS,
        NO_UNITS            = 2,
        OUT_SIZE            = NO_UNITS*8,
        LSTM                = 1,
        FC                  = 2,
        
        STATE_IDLE          = 3'b000,
        STATE_IRB           = 3'b001,
        STATE_GATE          = 3'b010,
        STATE_CELL          = 3'b011,
        STATE_HIDDEN        = 3'b100,
        // STATE_QUANTIZATION  = 3'b101,
        STATE_WAIT          = 3'b110,
        STATE_FINISH        = 3'b111,
        
        MULT_S0             = 0,
        MULT_S1             = 1,
        MULT_S2             = 2,
        MULT_S3             = 3,
        MULT_S4             = 4,
        
        INPUT_GATE          = 2'b00,
        FORGET_GATE         = 2'b01,
        CELL_UPDATE         = 2'b10,
        OUTPUT_GATE         = 2'b11,
        
        MULT_LATENCY        = 3,
        LATENCY             = 1;
        
        
    
    logic   [2:0]   state;
    logic           irb_done;
    logic           gate_done;
    logic           cell_done;
    logic           hidden_done;
    // logic           wait_done;
    logic           finish_done;
    // logic           is_quantized_ct;
    // logic           quantized_ht;
    logic   [2:0]   remain_waiting_time;
    logic      internal_current_unit;
//    logic           f_prev_cell_bf_done;
//    logic           i_cell_update_bf_done;
    logic           update_cell_state_bf;
    // logic           update_hidden_state_bf;
    logic   [2:0]   current_mult_shift;
    
    // add signal for quantization -----------------------------------------
    logic   [BUFFER_SIZE-1:0]       accu_input_bf   [0:OUT_SIZE/8 - 1];
    logic   [BUFFER_SIZE-1:0]       accu_forget_bf  [0:OUT_SIZE/8 - 1];
    logic   [BUFFER_SIZE-1:0]       accu_cell_bf    [0:OUT_SIZE/8 - 1];
    logic   [BUFFER_SIZE-1:0]       accu_output_bf  [0:OUT_SIZE/8 - 1];
    logic   [BUFFER_SIZE-1:0]       accu_bf         [0:OUT_SIZE/8 - 1];
    // logic   [BUFFER_SIZE-1:0]       accu_fc_bf;
    
    logic   [BUFFER_SIZE-1:0]       cell_update     [0:OUT_SIZE/8 - 1];
    logic   [BUFFER_SIZE-1:0]       input_gate      [0:OUT_SIZE/8 - 1];
    logic   [BUFFER_SIZE-1:0]       forget_gate     [0:OUT_SIZE/8 - 1];
    logic   [BUFFER_SIZE-1:0]       output_gate     [0:OUT_SIZE/8 - 1];
    
    // logic   [BUFFER_SIZE-1:0]       cell_mult_bf;
    logic   [BUFFER_SIZE-1:0]       cell_state_bf   ;
    logic   [BUFFER_SIZE-1:0]       hidden_state_bf ;
    
    logic   [QUANTIZE_SIZE-1:0]     cell_state      [0:OUT_SIZE/8 - 1];  
    // logic   [QUANTIZE_SIZE-1:0]     hidden_state    [0:OUT_SIZE/8 - 1];
    
    logic   [BUFFER_SIZE-1:0]       q_di_lstm_state ;
    logic   [QUANTIZE_SIZE-1:0]     q_do_lstm_state ;
    logic                           type_state      ;
    
    logic   [BUFFER_SIZE-1:0]       q_di_fc;
    logic   [QUANTIZE_SIZE-1:0]     q_do_fc;
        
    logic   [BUFFER_SIZE-1:0]      di_current_unit_tanh_bf;
    logic   [BUFFER_SIZE-1:0]      di_current_unit_sigmoid_bf;
    logic   [BUFFER_SIZE-1:0]      do_current_unit_tanh_bf;
    logic   [BUFFER_SIZE-1:0]      do_current_unit_sigmoid_bf;
    
     
    logic  [1:0]                            gate;
    logic  [1:0]                            count_gate;
    logic  [1:0]                            count_cell;
    
    logic  [BUFFER_SIZE-1:0]                tanh_cell_bf;
//    logic  [BUFFER_SIZE-1:0]                i_cell_update_bf;
    
    logic                                   mac_en;
    logic  [W_BITWIDTH-1:0]                 weights_bf_0;
    logic  [W_BITWIDTH-1:0]                 weights_bf_1; 
    logic  [W_BITWIDTH-1:0]                 weights_bf_2;  
    logic  [IN_BITWIDTH-1:0]                data_in_bf_0;
    logic  [IN_BITWIDTH-1:0]                data_in_bf_1;
    logic  [IN_BITWIDTH-1:0]                data_in_bf_2;
    logic  [OUT_BITWIDTH-1:0]               pre_sum_bf;
    logic                                   mac_done;
    logic  [OUT_BITWIDTH-1:0]               mac_result;
    
    // logic  [OUT_BITWIDTH-1:0]               fc_bf;
    
    logic   tanh_en;
    logic   sigmoid_en;
    logic   q_lstm_en;
    logic   q_fc_en;
    
    logic   tanh_done;
    logic   sigmoid_done;
    logic   q_lstm_done;
    logic   q_fc_done;
    
    MAC #(.W_BITWIDTH(W_BITWIDTH), .OUT_BITWIDTH(OUT_BITWIDTH)) u_mac (
        .clk(clk),
        .rstn(rstn),
        .en(mac_en),
        .weights_0(weights_bf_0),
        .weights_1(weights_bf_1),
        .weights_2(weights_bf_2),
        .data_in_0(data_in_bf_0),
        .data_in_1(data_in_bf_1),
        .data_in_2(data_in_bf_2),
        .pre_sum(pre_sum_bf),
        .done(mac_done),
        .out(mac_result)
    );
        
    tanh_appr u_tanh (
        .clk(clk),
        .rstn(rstn),
        .en(tanh_en),
        .data_in(di_current_unit_tanh_bf),
        .done(tanh_done),
        .data_out(do_current_unit_tanh_bf)
    );
    
    sigmoid_appro u_sigmoid (
        .clk(clk),
        .rstn(rstn),
        .en(sigmoid_en),
        .data_in(di_current_unit_sigmoid_bf),
        .done(sigmoid_done),
        .data_out(do_current_unit_sigmoid_bf)
    );
    
    quantization_lstm q1 (
        .clk(clk),
        .rstn(rstn),
        .en(q_lstm_en),
        .type_state(type_state), 
        .data_in(q_di_lstm_state),
        .done(q_lstm_done), 
        .data_out(q_do_lstm_state)
    ); 

    quantization_fc q2(
        .clk(clk),
        .rstn(rstn),
        .en(q_fc_en), 
        .data_in(q_di_fc),
        .done(q_fc_done),
        .data_out(q_do_fc)
    );
    
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            state       <= 3'b000;
            
            irb_done            <= 1'b0;
            gate_done           <= 1'b0;
            cell_done           <= 1'b0;
            hidden_done         <= 1'b0;
            // wait_done           <= 1'b0;
            finish_done         <= 1'b0;
            count_gate          <= 2'b00;
            
            remain_waiting_time    <= LATENCY;
            
            weights_bf_0           <= {W_BITWIDTH{1'b0}};
            weights_bf_1           <= {W_BITWIDTH{1'b0}};
            weights_bf_2           <= {W_BITWIDTH{1'b0}};
            data_in_bf_0           <= {IN_BITWIDTH{1'b0}};
            data_in_bf_1           <= {IN_BITWIDTH{1'b0}};
            data_in_bf_2           <= {IN_BITWIDTH{1'b0}};
            pre_sum_bf             <= {PREV_SUM_BITWIDTH{1'b0}};
//            accu_bf                <= {BUFFER_SIZE{1'b0}};
            // accu_fc_bf             <= {BUFFER_SIZE{1'b0}};
            cell_state[current_unit]    <= {QUANTIZE_SIZE{1'b0}};
            internal_current_unit  <= 0;
            done                   <= 1'b0;
        end
        else begin
            case(state) 
                STATE_IDLE: begin
                    irb_done            <= 1'b0;
                    gate_done           <= 1'b0;
                    cell_done           <= 1'b0;
                    hidden_done         <= 1'b0;
                    // wait_done           <= 1'b0;
                    finish_done         <= 1'b0;
                    finish_step         <= 1'b0;
                    done                <= 1'b0;
                    
                    tanh_en                 <= 1'b0;
                    sigmoid_en              <= 1'b0;
                    q_lstm_en               <= 1'b0;
                    q_fc_en                 <= 1'b0;
                    
                    accu_input_bf[current_unit]       <= 0;
                    accu_forget_bf[current_unit]      <= 0;
                    accu_cell_bf[current_unit]        <= 0;
                    accu_output_bf[current_unit]      <= 0;
                    accu_bf[current_unit]             <= {BUFFER_SIZE{1'b0}};
                    
//                    cell_state[current_unit]          <= {OUT_BITWIDTH{1'b0}};
                    
                    remain_waiting_time <= LATENCY;
                    
                    if (en && !done) begin
                        weights_bf_0    <= weight[W_BITWIDTH-1:0];
                        weights_bf_1    <= weight[W_BITWIDTH*2-1:W_BITWIDTH];
                        weights_bf_2    <= weight[W_BITWIDTH*3-1:W_BITWIDTH*2];
                        data_in_bf_0    <= data_in[IN_BITWIDTH-1:0];
                        data_in_bf_1    <= data_in[IN_BITWIDTH*2-1:IN_BITWIDTH];
                        data_in_bf_2    <= data_in[IN_BITWIDTH*3-1:IN_BITWIDTH*2];
                        
//                        cell_state[current_unit]    <= {QUANTIZE_SIZE{1'b0}};
//                        prev_cell_state[1]                  <= {QUANTIZE_SIZE{1'b0}};
                        case(is_load_bias)
                            0: pre_sum_bf     <= accu_bf[current_unit];
                            1: pre_sum_bf     <= pre_sum;
                        endcase
                        gate            <= type_gate;
                        state           <= STATE_IRB;
                        is_waiting      <= 1'b0;
                        // is_quantized_ct <= 1'b0;
                        count_gate      <= 2'b00;
                        count_cell      <= 2'b00;
                    end
                end
                
                STATE_IRB: begin
                    if (irb_done) begin
                        if (is_last_data_gate && is_last_input) begin
                            if (current_layer == LSTM) begin
                                state                   <= STATE_GATE;
                                is_waiting              <= 1'b0;
                                irb_done                <= 1'b0;
                                current_mult_shift      <= 3'b000;
                                tanh_en                 <= 1'b0;
                                sigmoid_en              <= 1'b0;
                                q_lstm_en               <= 1'b0;
                                q_fc_en                 <= 1'b0;
                                
                                case(gate)
                                    INPUT_GATE:     accu_input_bf[current_unit]   <= mac_result;
                                    FORGET_GATE:    accu_forget_bf[current_unit]  <= mac_result;
                                    CELL_UPDATE:    accu_cell_bf[current_unit]    <= mac_result;
                                    OUTPUT_GATE:    accu_output_bf[current_unit]  <= mac_result;
                                endcase
                            end
                            else if (current_layer == FC) begin
                                if (is_last_sample) begin
                                    state           <= STATE_FINISH;
                                    done            <= 1'b1;
                                end
                                else begin  
                                    state           <= STATE_IDLE;
                                    is_waiting      <= 1'b1;
                                end
                                // fc_bf               <= mac_result; 
//                                out                 <= mac_result[QUANTIZE_SIZE-1:0];
                                out                 <= q_do_fc;
                                irb_done            <= 1'b0;     
                            end
                            else ;
                            remain_waiting_time     <= LATENCY;
                        end
                        else begin
                            state                   <= STATE_WAIT;
                            is_waiting              <= 1'b1;
                            irb_done                <= 1'b0;
                            accu_bf[current_unit]   <= mac_result;
                        end               
                    end
                    else begin
                        mac_en          <= 1'b1;       
                        if (mac_done) begin
                            if (current_layer == FC) begin
                                q_fc_en     <= 1'b1;
                                if (q_fc_done) begin
                                    q_fc_en     <= 1'b0;
                                    irb_done    <= 1'b1;
                                end
                                else ;
                                q_di_fc     <= mac_result;
                                mac_en      <= 1'b0;
                            end
                            else begin
                                irb_done    <= 1'b1;
                                mac_en      <= 1'b0;
                            end 
                             
                        end
                        else ;
                    end
                end
               
                STATE_WAIT: begin
                    is_waiting          <= 1'b0;                  
                    if (remain_waiting_time == 0) begin
                        finish_step     <= 1'b0;
                        if (is_continued == 1) begin
                            state           <= STATE_IRB;
                            weights_bf_0    <= weight[W_BITWIDTH-1:0];
                            weights_bf_1    <= weight[W_BITWIDTH*2-1:W_BITWIDTH];
                            weights_bf_2    <= weight[W_BITWIDTH*3-1:W_BITWIDTH*2];
                            data_in_bf_0    <= data_in[IN_BITWIDTH-1:0];
                            data_in_bf_1    <= data_in[IN_BITWIDTH*2-1:IN_BITWIDTH];
                            data_in_bf_2    <= data_in[IN_BITWIDTH*3-1:IN_BITWIDTH*2];
                            
                            case(is_load_bias)
                                0: pre_sum_bf       <= accu_bf[current_unit];
                                1: pre_sum_bf       <= pre_sum;
                            endcase
                            
//                            prev_cell_state[current_unit]       <= cell_state[current_unit][QUANTIZE_SIZE-1:0];
                            if (finish_step == 1'b1) begin
                                finish_step         <= 1'b0;
                            end
                            else ;
                            
                            remain_waiting_time     <= LATENCY;
                        end
                        else begin
                            state      <= STATE_WAIT;
                            if (gate != type_gate) begin
                                case(gate)
                                    INPUT_GATE:     accu_input_bf[current_unit]   <= accu_bf[current_unit];
                                    FORGET_GATE:    accu_forget_bf[current_unit]  <= accu_bf[current_unit];
                                    CELL_UPDATE:    accu_cell_bf[current_unit]    <= accu_bf[current_unit];
                                    OUTPUT_GATE:    accu_output_bf[current_unit]  <= accu_bf[current_unit];
                                endcase
                                
                                case(type_gate)
                                    INPUT_GATE:     accu_bf[current_unit] <= accu_input_bf[current_unit];
                                    FORGET_GATE:    accu_bf[current_unit] <= accu_forget_bf[current_unit];
                                    CELL_UPDATE:    accu_bf[current_unit] <= accu_cell_bf[current_unit];
                                    OUTPUT_GATE:    accu_bf[current_unit] <= accu_output_bf[current_unit];
                                endcase
                                
                                gate    <= type_gate;
                            end
                            else gate   <= type_gate;
                        end
                    end
                    else remain_waiting_time <= remain_waiting_time - 1;
                end
                
                STATE_GATE: begin
                    if (gate_done) begin
                        gate_done       <= 1'b0;
                        gate            <= type_gate;
                        state           <= STATE_CELL;
                        
//                        weights_bf_0    <= forget_gate[internal_current_unit];
//                        weights_bf_1    <= input_gate[internal_current_unit];
//                        weights_bf_2    <= {W_BITWIDTH{1'b0}};
//                        data_in_bf_0    <= prev_cell_state[internal_current_unit];
//                        data_in_bf_1    <= cell_update[internal_current_unit];
//                        data_in_bf_2    <= {IN_BITWIDTH{1'b0}};
//                        pre_sum_bf      <= {PREV_SUM_BITWIDTH{1'b0}};
                        update_cell_state_bf                <= 1'b0;
                        remain_waiting_time                 <= MULT_LATENCY;
                        current_mult_shift                  <= 3'b000;
                        cell_state_bf                       <= 32'h0;
//                        cell_update[internal_current_unit]  <= do_current_unit_tanh_bf;
                        /////////////////////////////////////////////////////////
                    end
                    else begin
                        if (count_gate == 2'b11) begin
                            
//                            gate_done       <= 1'b1;
//                            output_gate[internal_current_unit]  <= do_current_unit_sigmoid_bf;                    
//                            count_gate      <= 2'b00;
                            tanh_en     <= 1'b1;
                            if (tanh_done) begin
                                if (remain_waiting_time == 0) begin
                                    count_gate          <= 2'b00;
                                    gate_done           <= 1'b1;
                                    remain_waiting_time <= LATENCY;
                                end
                                else remain_waiting_time <= remain_waiting_time - 1;
                                tanh_en         <= 1'b0;
                                cell_update[internal_current_unit]  <= do_current_unit_tanh_bf;
                            end
                            else ;
                            di_current_unit_tanh_bf             <= accu_cell_bf[internal_current_unit];
                        end
                        else begin
                            case(gate)
                                
                                INPUT_GATE: begin
                                    sigmoid_en      <= 1'b1;
                                    if (sigmoid_done) begin
                                        sigmoid_en                          <= 1'b0;
                                        output_gate[internal_current_unit]  <= do_current_unit_sigmoid_bf; 
                                        
                                        if (remain_waiting_time == 0) begin
//                                            output_gate[internal_current_unit]  <= do_current_unit_sigmoid_bf; 
                                            gate                                <= FORGET_GATE;
                                            count_gate                          <= count_gate + 1;
                                            remain_waiting_time                 <= LATENCY;
                                        end
                                        else remain_waiting_time <= remain_waiting_time - 1;
                                    end
                                    else ;
                                    di_current_unit_sigmoid_bf          <= accu_input_bf[internal_current_unit];
                                end
                                FORGET_GATE: begin
                                    sigmoid_en      <= 1'b1;
                                    if (sigmoid_done) begin
                                        if (remain_waiting_time == 0) begin
                                            gate                                <= OUTPUT_GATE;
                                            count_gate                          <= count_gate + 1;
                                            remain_waiting_time                 <= LATENCY;
                                        end
                                        else remain_waiting_time <= remain_waiting_time - 1;
                                        
                                        input_gate[internal_current_unit]   <= do_current_unit_sigmoid_bf;
                                        sigmoid_en                          <= 1'b0;
                                    end
                                    di_current_unit_sigmoid_bf          <= accu_forget_bf[internal_current_unit];   
                                end
                                OUTPUT_GATE: begin
                                    sigmoid_en      <= 1'b1;
                                    if (sigmoid_done) begin
                                        if (remain_waiting_time == 0) begin
                                            gate                                <= INPUT_GATE;
                                            count_gate                          <= count_gate + 1;
                                            remain_waiting_time                 <= LATENCY;
                                        end
                                        else remain_waiting_time <= remain_waiting_time - 1;
                                        forget_gate[internal_current_unit]  <= do_current_unit_sigmoid_bf;
                                        sigmoid_en                          <= 1'b0;
                                    end
                                    di_current_unit_sigmoid_bf          <= accu_output_bf[internal_current_unit];
                                end
                                default: begin
                                    gate <= INPUT_GATE;
                                end
                            endcase
                        end
                    end
                end
                
                STATE_CELL: begin
                    if (cell_done) begin
                        q_lstm_en   <= 1'b1;
                        tanh_en     <= 1'b1;
                        if (q_lstm_done && tanh_done) begin
                            state           <= STATE_HIDDEN;
                            cell_done       <= 1'b0;
                            q_lstm_en       <= 1'b1;
                            cell_state[internal_current_unit]   <= q_do_lstm_state;
                            
                            tanh_cell_bf            <= do_current_unit_tanh_bf;
                            current_mult_shift      <= 0;
                            update_cell_state_bf    <= 1'b0;
                            
//                            quantized_ht            <= 1'b0;
//                            is_quantized_ct         <= 1'b0;
                            type_state              <= 1;  
                            remain_waiting_time     <= MULT_LATENCY;  
                            hidden_state_bf         <= 32'h00000000;
    //                        accu_cell_bf[internal_current_unit]     <= mac_result;
                        end
                        di_current_unit_tanh_bf     <= cell_state_bf;
                        q_di_lstm_state             <= cell_state_bf;                                       
                    end
                    else begin
                        
                        case(count_cell)
                            2'b00: begin
//                                f_prev_cell_bf      <= forget_gate[internal_current_unit] * cell_state[internal_current_unit];
//                                f_prev_cell_bf      <= forget_gate[internal_current_unit];
                                if (remain_waiting_time == 0) begin
                                    mac_en                  <= 1'b1;
                                    if (mac_done) begin
                                        mac_en              <= 1'b0;
                                        if (!update_cell_state_bf) update_cell_state_bf <= 1'b1;
                                        else begin
                                            if (current_mult_shift == MULT_S2) current_mult_shift <= 0;
                                            else current_mult_shift  <= current_mult_shift + 1;
    
                                            case(current_mult_shift)
                                                MULT_S0: cell_state_bf <= cell_state_bf + mac_result;
                                                MULT_S1: cell_state_bf <= cell_state_bf + (mac_result <<< 8);
                                                MULT_S2: begin 
                                                    cell_state_bf   <= cell_state_bf + (mac_result <<< 16);
                                                    count_cell      <= count_cell + 1;
                                                end
                                            endcase 
                                            remain_waiting_time     <= MULT_LATENCY;
                                            update_cell_state_bf    <= 1'b0;
                                         end   
                                    end
                                end
                                else begin
                                    remain_waiting_time <= remain_waiting_time - 1;
                                    case(current_mult_shift)
                                        MULT_S0: begin
                                            weights_bf_0    <= forget_gate[internal_current_unit][7:0];
                                            weights_bf_1    <= {W_BITWIDTH{1'b0}};
                                            weights_bf_2    <= {W_BITWIDTH{1'b0}};
                                            data_in_bf_0    <= cell_state[internal_current_unit];
                                            data_in_bf_1    <= {IN_BITWIDTH{1'b0}};
                                            data_in_bf_2    <= {IN_BITWIDTH{1'b0}};
                                            pre_sum_bf      <= {PREV_SUM_BITWIDTH{1'b0}};
                                        end
                                        MULT_S1: begin
                                            weights_bf_0    <= forget_gate[internal_current_unit][15:8];
                                            weights_bf_1    <= {W_BITWIDTH{1'b0}};
                                            weights_bf_2    <= {W_BITWIDTH{1'b0}};
                                            data_in_bf_0    <= cell_state[internal_current_unit];
                                            data_in_bf_1    <= {IN_BITWIDTH{1'b0}};
                                            data_in_bf_2    <= {IN_BITWIDTH{1'b0}};
                                            pre_sum_bf      <= {PREV_SUM_BITWIDTH{1'b0}};
                                        end
                                        MULT_S2: begin
                                            weights_bf_0    <= forget_gate[internal_current_unit][23:16];
                                            weights_bf_1    <= {W_BITWIDTH{1'b0}};
                                            weights_bf_2    <= {W_BITWIDTH{1'b0}};
                                            data_in_bf_0    <= cell_state[internal_current_unit];
                                            data_in_bf_1    <= {IN_BITWIDTH{1'b0}};
                                            data_in_bf_2    <= {IN_BITWIDTH{1'b0}};
                                            pre_sum_bf      <= {PREV_SUM_BITWIDTH{1'b0}};
                                        end
                                    endcase
                                end
                            end
                            
                            2'b01: begin
//                                i_cell_update_bf    <= input_gate[internal_current_unit] * cell_update[internal_current_unit];
//                                i_cell_update_bf    <= input_gate[internal_current_unit];
                                if (remain_waiting_time == 0) begin
                                    mac_en                  <= 1'b1;
                                    if (mac_done) begin
                                        mac_en              <= 1'b0;
                                        if (!update_cell_state_bf) update_cell_state_bf <= 1'b1;
                                        else begin
                                            current_mult_shift  <= current_mult_shift + 1;
                                            update_cell_state_bf <= 1'b0;
                                            case(current_mult_shift)
                                                MULT_S0: cell_state_bf  <= cell_state_bf + mac_result;
                                                MULT_S1: cell_state_bf  <= cell_state_bf + (mac_result <<< 8);
                                                MULT_S2: cell_state_bf  <= cell_state_bf + (mac_result <<< 16);
                                                MULT_S3: cell_state_bf  <= cell_state_bf + (mac_result <<< 24);
                                                MULT_S4: begin
                                                    cell_state_bf   <= cell_state_bf + (mac_result <<< 32);
                                                    cell_done       <= 1'b1;
                                                    count_cell      <= 2'b00; 
                                                end
                                            endcase   
                                            remain_waiting_time     <= MULT_LATENCY;
//                                            update_cell_state_bf    <= 1'b0; 
                                        end
                                    end
                                end
                                else begin
                                    remain_waiting_time <= remain_waiting_time - 1;
                                    case(current_mult_shift)
                                        MULT_S0: begin
                                            weights_bf_0    <= input_gate[internal_current_unit][7:0];
                                            weights_bf_1    <= {W_BITWIDTH{1'b0}};
                                            weights_bf_2    <= {W_BITWIDTH{1'b0}};
                                            data_in_bf_0    <= cell_update[internal_current_unit][7:0];
                                            data_in_bf_1    <= {IN_BITWIDTH{1'b0}};
                                            data_in_bf_2    <= {IN_BITWIDTH{1'b0}};
                                            pre_sum_bf      <= {PREV_SUM_BITWIDTH{1'b0}};
                                        end
                                        MULT_S1: begin
                                            weights_bf_0    <= input_gate[internal_current_unit][15:8];
                                            weights_bf_1    <= input_gate[internal_current_unit][7:0];
                                            weights_bf_2    <= {W_BITWIDTH{1'b0}};
                                            data_in_bf_0    <= cell_update[internal_current_unit][7:0];
                                            data_in_bf_1    <= cell_update[internal_current_unit][15:8];
                                            data_in_bf_2    <= {IN_BITWIDTH{1'b0}};
                                            pre_sum_bf      <= {PREV_SUM_BITWIDTH{1'b0}};
                                        end
                                        MULT_S2: begin
                                            weights_bf_0    <= input_gate[internal_current_unit][23:16];
                                            weights_bf_1    <= input_gate[internal_current_unit][15:8];
                                            weights_bf_2    <= input_gate[internal_current_unit][7:0];
                                            data_in_bf_0    <= cell_update[internal_current_unit][7:0];
                                            data_in_bf_1    <= cell_update[internal_current_unit][15:8];
                                            data_in_bf_2    <= cell_update[internal_current_unit][23:16];
                                            pre_sum_bf      <= {PREV_SUM_BITWIDTH{1'b0}};
                                        end
                                        MULT_S3: begin
                                            weights_bf_0    <= input_gate[internal_current_unit][23:16];
                                            weights_bf_1    <= input_gate[internal_current_unit][15:8];
                                            weights_bf_2    <= {W_BITWIDTH{1'b0}};
                                            data_in_bf_0    <= cell_update[internal_current_unit][15:8];
                                            data_in_bf_1    <= cell_update[internal_current_unit][23:16];
                                            data_in_bf_2    <= {IN_BITWIDTH{1'b0}};
                                            pre_sum_bf      <= {PREV_SUM_BITWIDTH{1'b0}};
                                        end
                                        MULT_S4: begin
                                            weights_bf_0    <= input_gate[internal_current_unit][23:16];
                                            weights_bf_1    <= {W_BITWIDTH{1'b0}};
                                            weights_bf_2    <= {W_BITWIDTH{1'b0}};
                                            data_in_bf_0    <= cell_update[internal_current_unit][23:16];
                                            data_in_bf_1    <= {IN_BITWIDTH{1'b0}};
                                            data_in_bf_2    <= {IN_BITWIDTH{1'b0}};
                                            pre_sum_bf      <= {PREV_SUM_BITWIDTH{1'b0}};
                                        end
                                    endcase
                                end
                            end
                            default: begin
                                count_cell <= 2'b00;
                            end
                        endcase
                    end
                    
                end
                
                STATE_HIDDEN: begin
                    if (hidden_done) begin
                        q_lstm_en   <= 1'b1;
                        if (q_lstm_done) begin
                            if (internal_current_unit == 1) begin
                                if (is_last_timestep) cell_state[current_unit]    <= {QUANTIZE_SIZE{1'b0}};
                                else ;
                                state           <= STATE_IDLE;
                                is_waiting      <= 1'b1;
                                finish_step     <= 1'b1;
                            end
                            else begin
                                state                   <= STATE_GATE;
                                internal_current_unit   <= internal_current_unit + 1;  
                            end
                            hidden_done                             <= 1'b0;
//                            hidden_state[internal_current_unit]     <= q_do_lstm_state;
                            out                                     <= q_do_lstm_state;
                            q_lstm_en   <= 1'b0;
                        end
                        else ;
                       
                    end
                    else begin
                        if (remain_waiting_time == 0) begin
                            mac_en                  <= 1'b1;
                            if (mac_done) begin
                                mac_en              <= 1'b0;
                                if (!update_cell_state_bf) update_cell_state_bf <= 1'b1;
                                else begin
                                    current_mult_shift  <= current_mult_shift + 1;
                                    update_cell_state_bf <= 1'b0;
                                    case(current_mult_shift)
                                        MULT_S0: hidden_state_bf  <= hidden_state_bf + mac_result;
                                        MULT_S1: hidden_state_bf  <= hidden_state_bf + (mac_result <<< 8);
                                        MULT_S2: hidden_state_bf  <= hidden_state_bf + (mac_result <<< 16);
                                        MULT_S3: hidden_state_bf  <= hidden_state_bf + (mac_result <<< 24);
                                        MULT_S4: begin
                                            hidden_state_bf   <= hidden_state_bf + (mac_result <<< 32);
                                            hidden_done       <= 1'b1;
                                            count_cell        <= 2'b00; 
                                        end
                                    endcase   
                                    remain_waiting_time     <= MULT_LATENCY;
//                                            update_cell_state_bf    <= 1'b0; 
                                end
                            end
                        end
                        else begin
                            remain_waiting_time <= remain_waiting_time - 1;
                            case(current_mult_shift)
                                MULT_S0: begin
                                    weights_bf_0    <= output_gate[internal_current_unit][7:0];
                                    weights_bf_1    <= {W_BITWIDTH{1'b0}};
                                    weights_bf_2    <= {W_BITWIDTH{1'b0}};
                                    data_in_bf_0    <= tanh_cell_bf[7:0];
                                    data_in_bf_1    <= {IN_BITWIDTH{1'b0}};
                                    data_in_bf_2    <= {IN_BITWIDTH{1'b0}};
                                    pre_sum_bf      <= {PREV_SUM_BITWIDTH{1'b0}};
                                end
                                MULT_S1: begin
                                    weights_bf_0    <= output_gate[internal_current_unit][15:8];
                                    weights_bf_1    <= output_gate[internal_current_unit][7:0];
                                    weights_bf_2    <= {W_BITWIDTH{1'b0}};
                                    data_in_bf_0    <= tanh_cell_bf[7:0];
                                    data_in_bf_1    <= tanh_cell_bf[15:8];
                                    data_in_bf_2    <= {IN_BITWIDTH{1'b0}};
                                    pre_sum_bf      <= {PREV_SUM_BITWIDTH{1'b0}};
                                end
                                MULT_S2: begin
                                    weights_bf_0    <= output_gate[internal_current_unit][23:16];
                                    weights_bf_1    <= output_gate[internal_current_unit][15:8];
                                    weights_bf_2    <= output_gate[internal_current_unit][7:0];
                                    data_in_bf_0    <= tanh_cell_bf[7:0];
                                    data_in_bf_1    <= tanh_cell_bf[15:8];
                                    data_in_bf_2    <= tanh_cell_bf[23:16];
                                    pre_sum_bf      <= {PREV_SUM_BITWIDTH{1'b0}};
                                end
                                MULT_S3: begin
                                    weights_bf_0    <= output_gate[internal_current_unit][23:16];
                                    weights_bf_1    <= output_gate[internal_current_unit][15:8];
                                    weights_bf_2    <= {W_BITWIDTH{1'b0}};
                                    data_in_bf_0    <= tanh_cell_bf[15:8];
                                    data_in_bf_1    <= tanh_cell_bf[23:16];
                                    data_in_bf_2    <= {IN_BITWIDTH{1'b0}};
                                    pre_sum_bf      <= {PREV_SUM_BITWIDTH{1'b0}};
                                end
                                MULT_S4: begin
                                    weights_bf_0    <= output_gate[internal_current_unit][23:16];
                                    weights_bf_1    <= {W_BITWIDTH{1'b0}};
                                    weights_bf_2    <= {W_BITWIDTH{1'b0}};
                                    data_in_bf_0    <= tanh_cell_bf[23:16];
                                    data_in_bf_1    <= {IN_BITWIDTH{1'b0}};
                                    data_in_bf_2    <= {IN_BITWIDTH{1'b0}};
                                    pre_sum_bf      <= {PREV_SUM_BITWIDTH{1'b0}};
                                end
                            endcase
                        end  
                    end
                end
                
                                
                STATE_FINISH: begin
                    if (finish_done) begin
                        state           <= STATE_IDLE;
                        finish_done     <= 1'b0;
                        done            <= 1'b1;
                    end
                    else begin
//                        out             <= hidden_state[current_unit];
                        finish_done     <= 1'b1;
                    end
                end
            default: begin
                state <= STATE_IDLE;
            end
            endcase
        end
    end
    
    logic [7:0] unused_tanh_cell_bf = tanh_cell_bf[31:24];
endmodule
