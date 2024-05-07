module accel_top #(
    parameter int BusWidth = 32
) (
    input logic clk, 
    input logic rst,
    // Device side
    input  logic        device_req_i,
    input  logic [31:0] device_addr_i,
    input  logic        device_we_i,
    input  logic [3:0]  device_be_i,
    input  logic [31:0] device_wdata_i,
    output logic        device_rvalid_o,
    output logic [31:0] device_rdata_o
    // Host side
    // output logic                  host_req_o,
    // output logic [BusWidth-1:0]   host_add_o,
    // output logic                  host_we_o,
    // output logic [BusWidth-1:0]   host_wdata_o,
    // output logic [BusWidth/8-1:0] host_be_o,
    // input  logic                  host_gnt_i,
    // input  logic                  host_r_valid_i,
    // input  logic [BusWidth-1:0]   host_r_rdata_i
    // interrupt
    // output logic irq_o
);
    // WRITE weight, bias, x_t (input data); h_t (hidden state)
    localparam int unsigned KERNEL_WEIGHT_F_X3 = 32'h4; // 3 * 8bit (1eight)
    localparam int unsigned KERNEL_WEIGHT_I_X3 = 32'h8;
    localparam int unsigned KERNEL_WEIGHT_O_X3 = 32'h12;
    localparam int unsigned KERNEL_WEIGHT_C_TEMP_X3 = 32'h16;

    localparam int unsigned X_t_DATA_3X = 32'h20; // 3 * 8bit (1input)

    localparam int unsigned BIAS_DATA_F_1 = 32'h32;
    localparam int unsigned BIAS_DATA_I_1 = 32'h36;
    localparam int unsigned BIAS_DATA_O_1 = 32'h40;
    localparam int unsigned BIAS_DATA_C_TEMP_1 = 32'h44;

    localparam int unsigned RECURRENT_KERNEL_WEIGHT_F_X3 = 32'h48;
    localparam int unsigned RECURRENT_KERNEL_WEIGHT_I_X3 = 32'h52;
    localparam int unsigned RECURRENT_KERNEL_WEIGHT_O_X3 = 32'h56;
    localparam int unsigned RECURRENT_KERNEL_WEIGHT_C_TEMP_X3 = 32'h60;

    localparam int unsigned H_t_DATA_X4_1 = 32'h64;
    localparam int unsigned H_t_DATA_X4_2 = 32'h68;
    localparam int unsigned H_t_DATA_X4_3 = 32'h72;
    localparam int unsigned H_t_DATA_X4_4 = 32'h76;

    // READ output (hidden state (output includeded))
    localparam int unsigned H_t_OUT_X4_1 = 32'h80;
    localparam int unsigned H_t_OUT_X4_2 = 32'h84;
    localparam int unsigned H_t_OUT_X4_3 = 32'h88;
    localparam int unsigned H_t_OUT_X4_4 = 32'h92;
    
    //  Control signal
    localparam int unsigned READ_VALID = 32'h96;
    localparam int unsigned IS_LAST_DATA_GATE = 32'h100;
    localparam int unsigned READ_DATA = 32'h104;
    localparam int unsigned W_VALID = 32'h108;
    localparam int unsigned T_VALID = 32'h112;

// />> LSTM
// timestep 0: 
//             [ x_t ]
//             | (W  W  W  W) * 32 | (I) * 1 | (b b b b) * 32|
//             | (W  W  W  W) * 32 | (I) * 1 | 
//             ..... int(28/3) + 1 times
//             | (W  W  W  W) * 32 | (I) * 1 | 
//             [ h_t ] ignored
//             << accel out h_t >> // 32 h_t 
//             | (ht ht ht ht) * 8|
// timestep 1:
//             [ x_t ]
//             | (W  W  W  W) * 32 | (I) * 1 | (b b b b) * 32|
//             | (W  W  W  W) * 32 | (I) * 1 | 
//             ..... int(28/3) + 1 times
//             | (W  W  W  W) * 32 | (I) * 1 | 
//             [ h_t ]
//             | (U  U  U  U) * 32 | (h_t) * 1 | 
//             | (U  U  U  U) * 32 | (h_t) * 1 | 
//             ..... int(32/3) + 1 times
//             | (U  U  U  U) * 32 | (h_t) * 1 | 
//             << accel out h_t >> // 32 h_t
// timestep 2:
//             [ x_t ]
//             | (W  W  W  W) * 32 | (I) * 1 | (b b b b) * 32|
//             | (W  W  W  W) * 32 | (I) * 1 | 
//             ..... int(28/3) + 1 times
//             | (W  W  W  W) * 32 | (I) * 1 | 
//             [ h_t ]
//             | (U  U  U  U) * 32 | (h_t) * 1 | 
//             | (U  U  U  U) * 32 | (h_t) * 1 | 
//             ..... int(32/3) + 1 times
//             | (U  U  U  U) * 32 | (h_t) * 1 | 
//             << accel out h_t >> // 32 h_t
// ........
// timestep 27:
//             [ x_t ]
//             | (W  W  W  W) * 32 | (I) * 1 | (b b b b) * 32|
//             | (W  W  W  W) * 32 | (I) * 1 | 
//             ..... int(28/3) + 1 times
//             | (W  W  W  W) * 32 | (I) * 1 | 
//             [ h_t ]
//             | (U  U  U  U) * 32 | (h_t) * 1 | 
//             | (U  U  U  U) * 32 | (h_t) * 1 | 
//             ..... int(32/3) + 1 times
//             | (U  U  U  U) * 32 | (h_t) * 1 |  
//             << accel out h_t >> // 32 h_t 

// accel_h-t => 28 *  32 
// />> FC
//             | (U  U  U  U) * 32 | (h_t) * 1 | 
//             | (U  U  U  U) * 32 | (h_t) * 1 | 
//             ..... int(28 * 32/3) + 1 times
//             | (U  U  U  U) * 32 | (h_t) * 1 |
//             << accel out fc_out >> // 32 bit

    logic [31:0] reg_addr;

    logic ctrl_r_valid;
    logic ctrl_is_last_data_gate;
    logic [31:0] ctrl_data_in;
    logic ctrl_r_data;
    logic ctrl_w_valid;
    logic ctrl_t_valid;
    logic [31:0] ctrl_out_data;
    
    assign reg_addr = device_addr_i - 32'h80005000;
    assign wr_r_valid = device_req_i & device_we_i & (reg_addr == READ_VALID);
    assign wr_is_last_data_gate = device_req_i & device_we_i & (reg_addr == IS_LAST_DATA_GATE);

    assign rd_r_data = device_req_i & ~device_we_i & (reg_addr == READ_VALID);
    assign rd_w_valid = device_req_i & ~device_we_i & (reg_addr == W_VALID);
    assign rd_t_valid = device_req_i & ~device_we_i & (reg_addr == T_VALID);


    assign wr_enable = device_req_i & device_we_i & (reg_addr >= KERNEL_WEIGHT_F_X3) & (reg_addr <= H_t_DATA_X4_3);
    // assign wr_kernel_weight_f = device_req_i & device_we_i & (reg_addr == KERNEL_WEIGHT_F_X3);
    // assign wr_kernel_weight_i = device_req_i & device_we_i & (reg_addr == KERNEL_WEIGHT_I_X3);
    // assign wr_kernel_weight_o = device_req_i & device_we_i & (reg_addr == KERNEL_WEIGHT_O_X3);
    // assign wr_kernel_weight_c = device_req_i & device_we_i & (reg_addr == KERNEL_WEIGHT_C_TEMP_X3);

    // assign wr_X_t_data = device_req_i & device_we_i & (reg_addr == X_t_DATA_3X);

    // assign wr_bias_data_f = device_req_i & device_we_i & (reg_addr == BIAS_DATA_F_1);
    // assign wr_bias_data_i = device_req_i & device_we_i & (reg_addr == BIAS_DATA_I_1);
    // assign wr_bias_data_o = device_req_i & device_we_i & (reg_addr == BIAS_DATA_O_1);
    // assign wr_bias_data_c = device_req_i & device_we_i & (reg_addr == BIAS_DATA_C_TEMP_1);

    // assign wr_recurrent_kernel_weight_f = device_req_i & device_we_i & (reg_addr == RECURRENT_KERNEL_WEIGHT_F_X3);
    // assign wr_recurrent_kernel_weight_i = device_req_i & device_we_i & (reg_addr == RECURRENT_KERNEL_WEIGHT_I_X3);
    // assign wr_recurrent_kernel_weight_o = device_req_i & device_we_i & (reg_addr == RECURRENT_KERNEL_WEIGHT_O_X3);
    // assign wr_recurrent_kernel_weight_c = device_req_i & device_we_i & (reg_addr == RECURRENT_KERNEL_WEIGHT_C_TEMP_X3);

    // assign wr_H_t_data_x4_1 = device_req_i & device_we_i & (reg_addr == H_t_DATA_X4_1);
    // assign wr_H_t_data_x4_2 = device_req_i & device_we_i & (reg_addr == H_t_DATA_X4_2);
    // assign wr_H_t_data_x4_3 = device_req_i & device_we_i & (reg_addr == H_t_DATA_X4_3);
    // assign wr_H_t_data_x4_4 = device_req_i & device_we_i & (reg_addr == H_t_DATA_X4_4);
    assign rd_enable = device_req_i & ~device_we_i & (reg_addr >= H_t_OUT_X4_1) & (reg_addr <= H_t_OUT_X4_4);
    // assign rd_H_t_out_x4_1 = device_req_i & ~device_we_i & (reg_addr == H_t_OUT_X4_1);
    // assign rd_H_t_out_x4_2 = device_req_i & ~device_we_i & (reg_addr == H_t_OUT_X4_2);
    // assign rd_H_t_out_x4_3 = device_req_i & ~device_we_i & (reg_addr == H_t_OUT_X4_3);
    // assign rd_H_t_out_x4_4 = device_req_i & ~device_we_i & (reg_addr == H_t_OUT_X4_4);

    
    controller u_crtl (
        .clk,
        .rstn(rst),
        .r_valid(ctrl_r_valid),
        .is_last_data_gate(ctrl_is_last_data_gate),
        .data_in(ctrl_data_in),
        .r_data(ctrl_r_data),
        .w_valid(ctrl_w_valid),
        .t_valid(ctrl_t_valid),
        .out_data(ctrl_out_data)
    );


    always_ff @(posedge clk or negedge rst) begin
        if(!rst) begin
            device_rvalid_o <= '0;
        end
        else begin
            if (wr_r_valid) begin
                ctrl_r_valid <= device_wdata_i;
            end

            if (wr_is_last_data_gate) begin
                ctrl_is_last_data_gate <= device_wdata_i;
            end

            if (rd_r_data) begin
                device_rvalid_o <= '1;
                device_rdata_o <= ctrl_r_data;
            end

            if (rd_w_valid) begin
                device_rvalid_o <= '1;
                device_rdata_o <= ctrl_w_valid;
            end

            if (rd_t_valid) begin
                device_rvalid_o <= '1;
                device_rdata_o <= ctrl_t_valid;
            end

            if (wr_enable) begin
                ctrl_data_in <= device_wdata_i;
            end

            if (rd_enable) begin
                device_rvalid_o <= '1;
                device_rdata_o <= ctrl_out_data;
            end
        end
    end


endmodule
