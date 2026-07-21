`timescale 1ns / 1ps

module score (
    input  logic        clk,
    input  logic        reset,
    // main controller -> score
    input  logic [ 2:0] main_state,
    //
    input  logic        good,        //pulse
    input  logic        perfect,     //pulse
    input  logic        miss,
    input  logic        combo_done,  //pulse 
    input  logic [ 9:0] combo_data,
    input  logic        fever,       //level
    // result -> score
    output logic [23:0] score
);
    /*
    점수 로직

    기본 점수
    perfect, good, miss는 항상 들어옴 (1clk pulse 신호)
    - perfect = 100점
    - good  = 50점
    - miss = 0점

    피버 점수 (non fever : 0, fever : 1)
    - X2배

    콤보 점수 (combo가 끊켰을 때, data와 함께 clk 1 pulse done 전송받기.)
    - 콤보 done
    */

    logic [22:0] basic_score;  //점수 임시 저장 변수
    logic [22:0] combo_reg;
    logic [22:0] combo_score;

    assign score = basic_score + combo_score;
     assign combo_reg = combo_data * (combo_data + 1);

    // logic [2:0] hit; // {perfect, good, miss} 각 hit 상태에 맞는 reg만 활성화 되는 one-hot 변수

    typedef enum logic [1:0] {
        IDLE,
        GAME,
        DONE
    } game_type;

    game_type state;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            state       <= IDLE;
            basic_score <= 23'b0;
            combo_score <= 23'b0;
            // combo_reg   <= 23'b0;
        end else begin
            case (state)
                IDLE: begin
                    basic_score <= 23'b0;
                    combo_score <= 23'b0;
                    // main controller state가 GAME_CONT로 들어가면 GAME state로 이동
                    if (main_state == 3'b011) begin
                        state <= GAME;
                    end
                end

                // score cal state
                GAME: begin
                    if (main_state == 3'b100) begin
                        //main controller state가 CAPTURE로 가면 FINAL state 진입
                        state <= DONE;
                    end else begin
                        if (perfect) begin
                            basic_score <= (fever ? basic_score + 200 : basic_score + 100);   //perfect 기본 점수 100점, fever 상태인 경우 200점
                        end else if (good) begin
                            basic_score <= (fever ? basic_score + 100 : basic_score + 50);    //good 기본 점수 50점, fever 상태인 경우 100점
                        end

                        // if (combo_done) begin
                        //     combo_reg <= combo_data * (combo_data + 1);

                        //     if (combo_reg) begin
                        //         if (combo_reg <= 16'd101) begin
                        //             combo_score <= combo_score + (combo_reg >> 1);
                        //         end else if (combo_reg <= 16'd2550) begin
                        //             combo_score <= combo_score + (combo_reg);
                        //         end else begin
                        //             combo_score <= combo_score + (combo_reg*3 >>1);
                        //         end
                        //     end
                        // end
                        if (combo_done) begin
                            if (combo_reg != 0) begin
                                if (combo_reg <= 23'd101)
                                    combo_score <= combo_score + (combo_reg >> 1);
                                else if (combo_reg <= 23'd2550)
                                    combo_score <= combo_score + combo_reg;
                                else
                                    combo_score <= combo_score + ((combo_reg * 3) >> 1);
                            end
                        end

                    end
                end

                DONE: begin
                    if (main_state == 3'b101) begin
                        state <= IDLE;
                    end
                end
            endcase
        end
    end
endmodule
