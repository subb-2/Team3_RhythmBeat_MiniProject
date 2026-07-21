`timescale 1ns / 1ps

module sender #(
    parameter CLK_FREQ  = 100_000_000,
    parameter BAUD_RATE = 115_200
) (
    input logic clk,
    input logic reset,

    output logic fifo_full,          
    output logic tx,

    input logic [ 2:0] main_state,
    input logic [ 3:0] btn,          
    input logic        fever,
    input logic        perfect,
    input logic        good,
    input logic        miss,
    input logic [ 7:0] combo,
    input logic [23:0] score
);
    logic [7:0] data_in;
    logic [7:0] w_data_out;
    logic       w_fifo_empty;
    logic       w_uart_ready;

    logic       fifo_pop;
    logic       fifo_push;
    logic       uart_valid;

    // --- FIFO Pop 및 UART Valid 정석 핸드셰이킹 인터페이스 ---
    assign fifo_pop = (!w_fifo_empty) && w_uart_ready && !uart_valid;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            uart_valid <= 1'b0;
        end else begin
            if (fifo_pop) begin
                uart_valid <= 1'b1;
            end else if (w_uart_ready) begin
                uart_valid <= 1'b0;
            end
        end
    end

    // --- FIFO 인스턴스 (DEPTH 32) ---
    fifo #(
        .DEPTH    (32),
        .BIT_WIDTH(8)
    ) U_FIFO_TX (
        .clk      (clk),
        .rst      (reset),
        .push     (fifo_push & !fifo_full),
        .pop      (fifo_pop),
        .push_data(data_in),
        .pop_data (w_data_out),
        .full     (fifo_full),
        .empty    (w_fifo_empty)
    );

    // --- UART TX 인스턴스 ---
    uart_tx #(
        .CLK_FREQ (CLK_FREQ),
        .BAUD_RATE(BAUD_RATE)
    ) U_UART_TX (
        .clk    (clk),
        .rst_n  (!reset),
        .data_in(w_data_out),
        .valid  (uart_valid), 
        .ready  (w_uart_ready),
        .tx     (tx)
    );

    // FSM 상태 정의에 확실한 START 상태 추가
    typedef enum logic [3:0] {
        IDLE,
        START,
        CONTROL,
        DATA,
        COMBO,
        SCORE_FIRST,
        SCORE_SECOND,
        SCORE_THIRD,
        DONE
    } send_state_t;

    send_state_t state;

    // --- 판정 래치 로직 ---
    logic perfect_held, good_held, miss_held;
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            perfect_held <= 1'b0;
            good_held    <= 1'b0;
            miss_held    <= 1'b0;
        end else begin
            if (perfect) perfect_held <= 1'b1;
            if (good)    good_held    <= 1'b1;
            if (miss)    miss_held    <= 1'b1;

            if (state == DONE) begin
                perfect_held <= 1'b0;
                good_held    <= 1'b0;
                miss_held    <= 1'b0;
            end
        end
    end

    // --- 버튼 및 메인 상태 래치 로직 ---
    logic [3:0] btn_held;
    logic [2:0] main_state_reg;
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            btn_held       <= 4'b0000;
            main_state_reg <= 3'b000;
        end else begin
            main_state_reg <= main_state;

            if (btn != 4'b0000) begin
                btn_held <= btn;
            end 
            else if (state == DONE) begin
                btn_held <= 4'b0000;
            end
        end
    end

    // --- 실시간 전송 예약 트리거 신호 생성 ---
    logic send_pending;
    logic [2:0] prev_main_state;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            send_pending    <= 1'b0;
            prev_main_state <= 3'b000;
        end else begin
            prev_main_state <= main_state;

            if ((btn != 4'b0000) || (main_state != prev_main_state) || perfect || good || miss) begin
                send_pending <= 1'b1;
            end 
            else if (state == START) begin // START 진입과 동시에 펜딩 클리어
                send_pending <= 1'b0; 
            end
        end
    end

    // --- FSM 로직 (START 단계를 신설하여 첫 패킷 깨짐을 원천 차단) ---
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            state     <= IDLE;
            data_in   <= 8'h00;
            fifo_push <= 1'b0;
        end else begin
            fifo_push <= 1'b0;
            case (state)
                IDLE: begin
                    if (!fifo_full && send_pending) begin
                        state <= START;
                    end
                end
                START: begin
                    data_in   <= 8'hFF; // 첫 번째 바이트 FF를 여기서 확실하게 push
                    fifo_push <= 1'b1;
                    state     <= CONTROL;
                end
                CONTROL: begin
                    data_in   <= {1'b0, main_state_reg, btn_held}; // 두 번째 바이트
                    fifo_push <= 1'b1;
                    state     <= DATA;
                end
                DATA: begin
                    data_in   <= {4'b0, fever, perfect_held, good_held, miss_held}; // 세 번째 바이트
                    fifo_push <= 1'b1;
                    state     <= COMBO;
                end
                COMBO: begin
                    data_in   <= combo; // 네 번째 바이트
                    fifo_push <= 1'b1;
                    state     <= SCORE_FIRST;
                end
                SCORE_FIRST: begin
                    data_in   <= score[7:0]; // 다섯 번째 바이트
                    fifo_push <= 1'b1;
                    state     <= SCORE_SECOND;
                end
                SCORE_SECOND: begin
                    data_in   <= score[15:8]; // 여섯 번째 바이트
                    fifo_push <= 1'b1;
                    state     <= SCORE_THIRD;
                end
                SCORE_THIRD: begin
                    data_in   <= score[23:16]; // 일곱 번째 바이트
                    fifo_push <= 1'b1; 
                    state     <= DONE;
                end
                DONE: begin
                    fifo_push <= 1'b0;
                    state     <= IDLE;
                end
                default: state <= IDLE;
            endcase
        end
    end
endmodule


// UART 송신기 (8N1: 데이터 8비트, 패리티 없음, 정지비트 1비트)
module uart_tx #(
    parameter CLK_FREQ  = 100_000_000,
    parameter BAUD_RATE = 115_200
) (
    input logic clk,
    input logic rst_n,
    input logic [7:0] data_in,  // 송신할 바이트
    input logic valid,  // 전송 시작 펄스 (1클럭 high)
    output logic ready,  // idle 상태 (다음 데이터 수락 가능)
    output logic tx  // 직렬 출력 라인
);

    // 한 비트 동안 카운트해야 하는 클럭 수
    localparam CLKS_PER_BIT = CLK_FREQ / BAUD_RATE;

    // 송신 FSM 상태
    localparam S_IDLE = 2'd0;  // 대기
    localparam S_START = 2'd1;  // 시작비트(0) 출력
    localparam S_DATA = 2'd2;  // 데이터 8비트 출력
    localparam S_STOP = 2'd3;  // 정지비트(1) 출력

    logic [1:0] state;
    logic [$clog2(CLKS_PER_BIT):0] clk_cnt;  // 비트 길이 카운터
    logic [2:0] bit_idx;  // 현재 송신 중인 비트 인덱스
    logic [7:0] shift_reg;  // 송신 데이터 보관

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state     <= S_IDLE;
            clk_cnt   <= 0;
            bit_idx   <= 0;
            shift_reg <= 8'h00;
            tx        <= 1'b1;  // idle 상태에서 라인은 high
            ready     <= 1'b1;
        end else begin
            case (state)
                S_IDLE: begin
                    tx    <= 1'b1;
                    ready <= 1'b1;
                    if (valid) begin
                        // 데이터 캡처 후 시작비트로 진입
                        shift_reg <= data_in;
                        clk_cnt   <= 0;
                        ready     <= 1'b0;
                        state     <= S_START;
                    end
                end

                S_START: begin
                    tx <= 1'b0;  // 시작비트
                    if (clk_cnt == CLKS_PER_BIT - 1) begin
                        clk_cnt <= 0;
                        bit_idx <= 0;
                        state   <= S_DATA;
                    end else begin
                        clk_cnt <= clk_cnt + 1;
                    end
                end

                S_DATA: begin
                    tx <= shift_reg[bit_idx];  // LSB부터 차례로 전송
                    if (clk_cnt == CLKS_PER_BIT - 1) begin
                        clk_cnt <= 0;
                        if (bit_idx == 3'd7) begin
                            state <= S_STOP;
                        end else begin
                            bit_idx <= bit_idx + 1;
                        end
                    end else begin
                        clk_cnt <= clk_cnt + 1;
                    end
                end

                S_STOP: begin
                    tx <= 1'b1;  // 정지비트
                    if (clk_cnt == CLKS_PER_BIT - 1) begin
                        clk_cnt <= 0;
                        state   <= S_IDLE;
                    end else begin
                        clk_cnt <= clk_cnt + 1;
                    end
                end

                default: state <= S_IDLE;
            endcase
        end
    end

endmodule

module fifo #(
    parameter DEPTH = 4,
    parameter BIT_WIDTH = 8 // SystemVerilog 스타일의 명시적 parameter 선언 유지
) (
    input  logic       clk,
    input  logic       rst,
    input  logic       push,
    input  logic       pop,
    input  logic [7:0] push_data,
    output logic [7:0] pop_data,
    output logic       full,
    output logic       empty
);
    logic [$clog2(DEPTH) - 1:0] w_wptr, w_rptr;

    register_file #(
        .DEPTH(DEPTH),
        .BIT_WIDTH(BIT_WIDTH)
    ) U_REG_FILE (
        .clk(clk),
        .push_data(push_data),
        .w_addr(w_wptr),
        .r_addr(w_rptr),
        .we(push & (~full)),
        .pop_data(pop_data)
    );

    control_unit #(
        .DEPTH(DEPTH)
    ) U_CONTROL_UNIT (
        .clk  (clk),
        .rst  (rst),
        .push (push),
        .pop  (pop),
        .wptr (w_wptr),
        .rptr (w_rptr),
        .full (full),
        .empty(empty)
    );

endmodule

module register_file #(
    parameter DEPTH = 4,
    parameter BIT_WIDTH = 8
) (
    input  logic                     clk,
    input  logic [    BIT_WIDTH-1:0] push_data,
    input  logic [$clog2(DEPTH)-1:0] w_addr,
    input  logic [$clog2(DEPTH)-1:0] r_addr,
    input  logic                     we,
    output logic [    BIT_WIDTH-1:0] pop_data
);

    // ram
    logic [BIT_WIDTH-1:0] register_file[0:DEPTH-1];

    // push to regeister file
    always_ff @(posedge clk) begin
        if (we) begin
            //push
            register_file[w_addr] <= push_data;
        end
        // else begin
        //     pop_data <= register_file[r_addr];
        // end
    end

    // pop
    assign pop_data = register_file[r_addr];

endmodule

module control_unit #(
    parameter DEPTH = 4
) (
    input  logic                     clk,
    input  logic                     rst,
    input  logic                     push,
    input  logic                     pop,
    output logic [$clog2(DEPTH)-1:0] wptr,
    output logic [$clog2(DEPTH)-1:0] rptr,
    output logic                     full,
    output logic                     empty
);

    logic [1:0] c_state, n_state;
    logic [$clog2(DEPTH)-1:0] wptr_reg, wptr_next, rptr_reg, rptr_next;
    logic full_reg, full_next, empty_reg, empty_next;

    assign wptr  = wptr_reg;
    assign rptr  = rptr_reg;
    assign full  = full_reg;
    assign empty = empty_reg;

    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            c_state   <= 2'b00;
            wptr_reg  <= 0;
            rptr_reg  <= 0;
            full_reg  <= 0;
            empty_reg <= 1;
        end else begin
            c_state   <= n_state;
            wptr_reg  <= wptr_next;
            rptr_reg  <= rptr_next;
            full_reg  <= full_next;
            empty_reg <= empty_next;
        end
    end

    //next_st, output
    always_comb begin
        n_state    = c_state;
        wptr_next  = wptr_reg;
        rptr_next  = rptr_reg;
        full_next  = full_reg;
        empty_next = empty_reg;
        unique case ({
            push, pop
        })
            // push
            2'b10: begin
                if (!full) begin
                    wptr_next  = wptr_reg + 1;
                    empty_next = 1'b0;
                    if (wptr_next == rptr_reg) begin
                        full_next = 1'b1;
                    end
                end
            end
            // pop
            2'b01: begin
                if (!empty) begin
                    rptr_next = rptr_reg + 1;
                    full_next = 1'b0;
                    if (wptr_reg == rptr_next) begin
                        empty_next = 1'b1;
                    end
                end
            end
            // push, pop
            2'b11: begin
                if (full_reg == 1'b1) begin
                    rptr_next = rptr_reg + 1;
                    full_next = 1'b0;
                end else if (empty_reg == 1'b1) begin
                    wptr_next  = wptr_reg + 1;
                    empty_next = 1'b0;
                end else begin
                    wptr_next = wptr_reg + 1;
                    rptr_next = rptr_reg + 1;
                end
            end
        endcase
    end
endmodule
