`timescale 1ns / 1ps

// UART 수신기 (8N1: 데이터 8비트, 패리티 없음, 정지비트 1비트)
module uart_rx #(
    parameter CLK_FREQ  = 100_000_000,
    parameter BAUD_RATE = 115_200
) (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       rx,        // 직렬 입력 라인
    output reg  [7:0] data_out,  // 수신된 바이트
    output reg        valid      // 수신 완료 펄스 (1클럭 high)
);

    localparam CLKS_PER_BIT = CLK_FREQ / BAUD_RATE;
    localparam HALF_BIT = CLKS_PER_BIT / 2;

    // 수신 FSM 상태
    localparam S_IDLE = 2'd0;  // 대기 (rx falling edge 감지)
    localparam S_START = 2'd1; // 시작비트 중앙까지 대기 후 재확인
    localparam S_DATA = 2'd2;  // 데이터 8비트 샘플링
    localparam S_STOP = 2'd3;  // 정지비트 통과

    reg [                   1:0] state;
    reg [$clog2(CLKS_PER_BIT):0] clk_cnt;
    reg [                   2:0] bit_idx;
    reg [                   7:0] shift_reg;

    // rx를 clk 도메인으로 가져오는 2단 동기화기 (메타스태빌리티 방지)
    reg rx_sync0, rx_sync;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_sync0 <= 1'b1;
            rx_sync  <= 1'b1;
        end else begin
            rx_sync0 <= rx;
            rx_sync  <= rx_sync0;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state     <= S_IDLE;
            clk_cnt   <= 0;
            bit_idx   <= 0;
            shift_reg <= 8'h00;
            data_out  <= 8'h00;
            valid     <= 1'b0;
        end else begin
            valid <= 1'b0;  // 기본값: 디어서트

            case (state)
                S_IDLE: begin
                    clk_cnt <= 0;
                    bit_idx <= 0;
                    if (rx_sync == 1'b0) // falling edge → 시작비트 후보
                        state <= S_START;
                end

                // 시작비트 중앙 시점까지 대기
                S_START: begin
                    if (clk_cnt == HALF_BIT - 1) begin
                        clk_cnt <= 0;
                        if (rx_sync == 1'b0) // 여전히 low → 유효한 시작비트
                            state <= S_DATA;
                        else state <= S_IDLE;  // 노이즈로 판단, 폐기
                    end else begin
                        clk_cnt <= clk_cnt + 1;
                    end
                end

                // 매 비트 길이마다 비트 중앙에서 샘플링
                S_DATA: begin
                    if (clk_cnt == CLKS_PER_BIT - 1) begin
                        clk_cnt            <= 0;
                        shift_reg[bit_idx] <= rx_sync;  // LSB부터 채움
                        if (bit_idx == 3'd7) begin
                            state <= S_STOP;
                        end else begin
                            bit_idx <= bit_idx + 1;
                        end
                    end else begin
                        clk_cnt <= clk_cnt + 1;
                    end
                end

                // 정지비트 한 비트 길이 대기 후 데이터 출력
                S_STOP: begin
                    if (clk_cnt == CLKS_PER_BIT - 1) begin
                        clk_cnt  <= 0;
                        data_out <= shift_reg;
                        valid    <= 1'b1; // 1클럭 펄스
                        state    <= S_IDLE;
                    end else begin
                        clk_cnt <= clk_cnt + 1;
                    end
                end

                default: state <= S_IDLE;
            endcase
        end
    end

endmodule