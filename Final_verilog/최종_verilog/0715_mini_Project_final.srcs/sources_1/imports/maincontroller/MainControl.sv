`timescale 1ns / 1ps

module MainControl (
    input logic clk,
    input logic reset,

    input logic btn_l,  // 왼쪽 (이전 곡)
    input logic btn_r,  // 오른쪽 (다음 곡)
    input logic btn_d,  // 선택/확인 버튼

    // 외부 모듈 상태 입력
    input logic game_done,
    input logic capture_done,

    // 제어 출력
    output logic [1:0] music_sel,
    output logic       done,
    output logic [2:0] o_state
);


    // 상태 정의
    localparam [2:0] IDLE = 3'b000,  // 대기 상태
    SELECT = 3'b001,  // 곡 선택 상태
    READY = 3'b010,  // 게임 시작 전 카운트다운(3초)
    GAME_CONT = 3'b011,  // 게임 플레이 진행
    CAPTURE = 3'b100,  // 결과 화면 및 사진 캡처
    DONE = 3'b101;  // 결과 출력 완료 및 대기

    logic [2:0] c_state, n_state;

    localparam TIME_3SEC = 29'd300_000_000;

    //simulation time_3sec
    //localparam TIME_3SEC = 20;

    logic [28:0] s_cnt;

    assign o_state = c_state;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            c_state   <= IDLE;
            music_sel <= 0;
            s_cnt     <= '0;
        end else begin
            c_state <= n_state;

            if (c_state == SELECT) begin
                if (btn_l) begin
                    if (music_sel == 2'b00) music_sel <= 2'b11;
                    else music_sel <= music_sel - 1'b1;
                end else if (btn_r) begin
                    if (music_sel == 2'b11) music_sel <= 2'b00;
                    else music_sel <= music_sel + 1'b1;
                end
            end

            if (c_state == READY) begin
                if (s_cnt < TIME_3SEC) begin
                    s_cnt <= s_cnt + 1'b1;
                end
            end else begin
                s_cnt <= '0;
            end
        end
    end

    always_comb begin
        n_state = c_state;
        done    =  0;

        case (c_state)
            IDLE: begin
                if (btn_d) begin
                    n_state = SELECT;
                end
            end
            SELECT: begin
                if (btn_d) begin
                    n_state = READY;
                end
            end
            READY: begin
                if (s_cnt >= TIME_3SEC) begin
                    n_state = GAME_CONT;
                end
            end

            GAME_CONT: begin
                if (game_done) begin
                    n_state = CAPTURE;
                end
            end
            CAPTURE: begin
                if (btn_d) begin
                    n_state = DONE;
                end
                // n_state = DONE;
            end
            DONE: begin
                done = 1'b1;
                if (btn_d) begin
                    n_state = IDLE;
                end
            end
            default: n_state = IDLE;
        endcase
    end

endmodule
