module SCCB_sender(
   input  logic clk,
   input  logic reset,
   input  logic WR,
   input  logic start,
   input  logic [15:0] tx_data,
   input  logic SCCBrp,
   output logic SCCBdone,
   output wire  scl,
   inout  logic sda,
   output logic [7:0] rx_data
);

    logic cmd_start, cmd_write, cmd_read, cmd_stop, done, busy;
    logic [7:0] txBuffer;

    // IP address setting
    localparam IP_ADDR = 7'h21;

    typedef enum logic [2:0] {
        IDLE = 3'd0,
        START,
        ID,
        REG,
        DATA,
        STOP
    } i2c_state;
    i2c_state state;

    always_ff @(posedge clk, posedge reset) begin
        if(reset) begin
            state <= IDLE;
            cmd_start <= 0;
            cmd_write <= 0;
            cmd_read  <= 0;
            cmd_stop  <= 0;
            SCCBdone  <= 1'b0;
        end else begin
            cmd_start <= 0;
            cmd_write <= 0;
            cmd_read  <= 0;
            cmd_stop  <= 0;

            case(state)
                IDLE: begin
                    SCCBdone <= 1'b0;
                    if(start) begin
                       state     <= START;
                       cmd_start <= 1'b1; 
                    end
                end
                START: begin
                    if(done) begin
                        state     <= ID;
                        txBuffer  <= {IP_ADDR, WR}; // 1: read, 0: write
                        cmd_write <= 1'b1;
                    end
                end
                ID: begin
                    if(busy) begin
                        if(done) begin
                            if(WR == 0) begin
                                state     <= REG;
                                txBuffer  <= tx_data[15:8];
                                cmd_write <= 1'b1;
                            end else begin
                                state    <= DATA;
                                cmd_read <= 1'b1;
                            end
                        end
                    end
                end
                REG: begin
                    if(busy) begin
                        if(done) begin
                            if(SCCBrp) begin
                                state <= STOP;
                                cmd_stop <= 1'b1;
                            end else begin
                                state <= DATA;
                                txBuffer  <= tx_data[7:0];
                                cmd_write <= 1'b1;
                            end
                        end
                    end
                end
                DATA: begin
                    if(busy) begin
                        if(done) begin
                            cmd_stop <= 1'b1;
                            state    <= STOP;
                        end
                    end
                end
                STOP: begin
                    if(busy) begin
                        if(done) begin
                            state    <= IDLE;
                            SCCBdone <= 1'b1;
                        end
                    end
                end
            endcase
        end
    end

    I2C_Master U_SCCB_MASTER(
        .clk(clk),
        .reset(reset),
        .cmd_start(cmd_start),
        .cmd_write(cmd_write),
        .cmd_read(cmd_read),
        .cmd_stop(cmd_stop),
        .tx_data(txBuffer),
        .ack_in(1'b1),
        .rx_data(rx_data),
        .done(done),
        .ack_out(),
        .busy(busy),
        .scl(scl),
        .sda(sda)
    );

endmodule