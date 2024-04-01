module and_top (
    input logic clk,
    input logic rst_ni,
    // Device side
    input logic device_req_i,
    input logic [31:0] device_addr_i,
    input logic device_we_i,
    input logic [3:0] device_be_i,
    input logic [31:0] device_wdata_i,
    output logic device_rvalid_o,
    output logic [31:0] device_rdata_o,

    output logic and2_irq_o
);
    localparam int unsigned AND_INPUT_REG = 32'h4;
    localparam int unsigned AND_OUTPUT_REG = 32'h8;


    logic [11:0] reg_addr;
    logic and_o_wr_en;
    logic [15:0] input_and[2];
    logic enable;
    logic and_i_rd_en;
    logic [31:0] out;
    logic valid;

    assign reg_addr = device_addr_i[11:0];
    assign and_o_wr_en = device_req_i & device_we_i & (reg_addr == AND_INPUT_REG[11:0]);
    assign and_i_rd_en = device_req_i & ~device_we_i & (reg_addr == AND_OUTPUT_REG[11:0]);

    always@(posedge clk or negedge rst_ni) begin
        if(!rst_ni) begin
            device_rvalid_o <= '0;
            and2_irq_o <= '0;
        end else begin
            and2_irq_o <= valid;
            if(and_o_wr_en) begin
                {input_and[0], input_and[1]} <= device_wdata_i;
                enable <= 1'b1;

            end
            if(and_i_rd_en) begin
                device_rvalid_o <= 1'b1;
                device_rdata_o <= out;
            end
        end
    end


    and_gate # (
        .DataWidth(16)
    ) u_and_gate (
        .clk,
        .enable_i(enable),
        .a_i(input_and[0]),
        .b_i(input_and[1]),
        // .out_o(device_rdata_o[15:0]),
        .out_o(out[15:0]),
        .valid_o(valid)
    );


    logic unused_device_addr, unused_device_be, unused_device_wdata;

    assign out[31:16] = '0;
    assign unused_device_addr = ^device_addr_i[31:10];
    assign unused_device_be = ^device_be_i;
    assign unused_device_wdata = ^device_wdata_i[31:16];

endmodule


