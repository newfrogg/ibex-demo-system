module and_wrapper # (
    parameter int BusWidth = 32,
    parameter int Width = 1
) (
    input  logic                clk_i,
    input  logic                rst_ni,

    // IO for device bus.
    input  logic                device_req_i,
    input  logic [BusWidth-1:0] device_addr_i,
    input  logic                device_we_i,
    input  logic [         3:0] device_be_i,
    input  logic [BusWidth-1:0] device_wdata_i,
    output logic                device_rvalid_o,
    output logic [BusWidth-1:0] device_rdata_o

);

// --------------------------------------------------------------------------
// Register Addresses
// --------------------------------------------------------------------------
    localparam int unsigned AND_STATUS_REG = 32'h0;
    localparam int unsigned AND_INPUT_REG = 32'h4;
    localparam int unsigned AND_OUTPUT_REG = 32'h8;
// --------------------------------------------------------------------------
// Customized IPS Core - IPs wires
// --------------------------------------------------------------------------
    logic and2_start;
    logic [Width-1:0] and2_dataa;
    logic [Width-1:0] and2_datab;
    logic [Width-1:0] and2_result;
    logic and2_done;
// --------------------------------------------------------------------------
// Internal wires
// --------------------------------------------------------------------------
    logic [11:0] reg_addr;
    logic and2_o_wr_en;
    logic and2_i_rd_en_q, and2_i_rd_en_d;

    always @(posedge clk_i or negedge rst_ni) begin
        if(!rst_ni) begin
            device_rvalid_o <= '0;
            device_rdata_o <= '0;
            and2_start <= '0;
            and2_done <= '0;
        end else begin
            if (and2_o_wr_en) begin
                and2_start <= 1'b1;
                {and2_dataa, and2_datab} <= device_wdata_i[2*Width-1:0];
            end

            if (and2_i_rd_en_d) begin
                device_rdata_o <= {{(32-Width){1'b0}}, and2_result};
                device_rvalid_o <= and2_done;

            end
            device_rvalid_o <= device_req_i;
            and2_i_rd_en_q <= and2_i_rd_en_d;
        end
    end


    // deocode write and read requests
    assign reg_addr = device_addr_i[11:0];
    assign and2_o_wr_en = device_req_i & device_we_i & (reg_addr == AND_OUTPUT_REG[11:0]);
    assign and2_i_rd_en_d = device_req_i & ~device_we_i & (reg_addr == AND_INPUT_REG[11:0]);



    and2 # (
        .Width(1)
    ) u_and2 (
        .clk(clk_i),
        .start_i(and2_start),
        .in0_i(and2_dataa),
        .in1_i(and2_datab),
        .out_o(and2_result),
        .ready_o(and2_done)
    );

endmodule
