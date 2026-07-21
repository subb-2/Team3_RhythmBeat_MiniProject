`timescale 1ns / 1ps

//game done 신호까지 생성
module receiver (
    input  logic       clk,
    input  logic       reset,
    input  logic       v_sync,
    input  logic       rx,
    //line count side
    output logic [3:0] lane_data,
    output logic       note_start,
    //MainControl side
    output logic       game_done,
    output logic [3:0] r_data
);

    logic v_sync_1, v_sync_r_edge;
    //logic [3:0] r_data;
    logic [7:0] data_out;
    logic valid, en;

    //v_sync falling edge detection
    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            v_sync_1 <= 0;
        end else begin
            v_sync_1 <= v_sync;
        end
    end

    //v_sync posedge detect
    assign v_sync_r_edge = ((v_sync_1 == 0) && (v_sync == 1)) ? 1 : 0;

    uart_rx #(
        .CLK_FREQ (100_000_000),
        .BAUD_RATE(115_200)
    ) U_UART_RX (
        .clk     (clk),
        .rst_n   (~reset),
        .rx      (rx),
        .data_out(data_out),
        .valid   (valid)
    );

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            r_data    <= 0;
            game_done <= 0;
            en        <= 0;
        end else begin
            game_done <= 0;
            if (note_start) begin
                en <= 0;
            end else if (valid) begin
                en     <= 1'b1;
                r_data <= data_out[3:0];
                if (data_out[7:4] == 4'hF) begin
                    game_done <= 1'b1;
                end
            end
        end
    end

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            lane_data  <= 0;
            note_start <= 0;
        end else begin
            note_start <= 0;
            if (v_sync_r_edge && en) begin
                lane_data  <= r_data;
                note_start <= 1'b1;
            end
        end
    end


endmodule
