`timescale 1ns / 1ps

module MainController (
    input logic clk,
    input logic reset,

    // UI 제어용 물리 버튼
    input logic btn_l_f,
    input logic btn_r_f,
    input logic btn_d_f,

    //top_game이 필요로 하는 외부 신호
    input logic       v_sync,
    input logic [3:0] region,  // 리듬게임 4레인 타격 버튼

    // 카메라 완료 신호
    input logic capture_done,

    //uart로 받은 코드 lane 정보와 start 신호. linecounter에 들어감
    input logic [3:0] lane_data,
    input logic       note_start,

    //receiver에서 생성한 game_done 신호
    input logic game_done,

    // FSM 상태 및 제어 출력
    output logic       main_done,
    output logic [2:0] o_state,

    //top_game에서 생성되어 렌더링(VGA) 모듈로 나갈 데이터
    // output logic [ 3:0] o_lane,
    output logic [ 11:0] o_duration,
    output logic [ 23:0] score,
    // [원래 코드 백업]
    // output logic [23:0] score
    // );
    output logic         perfect,
    output logic         good,
    output logic         miss,
    output logic [  9:0] combo,
    output logic         fever,
    // [추가] 새 카메라 모듈의 노트 Y좌표 출력을 위한 통과 포트
    output logic [03:00] o_pos0,
    output logic [03:00] o_pos1,
    output logic [03:00] o_pos2,
    output logic [03:00] o_pos3,
    output logic [03:00] o_pos4,
    output logic [03:00] o_pos5,
    output logic [03:00] o_pos6,
    output logic [03:00] o_pos7,
    output logic [03:00] o_pos8,
    output logic [03:00] o_pos9,
    output logic [03:00] o_pos10,
    output logic [03:00] o_pos11,
    output logic [03:00] o_pos12,
    output logic [03:00] o_pos13,
    output logic [03:00] o_pos14,
    output logic [03:00] o_pos15,
    output logic [09:00] o_lcnt0,
    output logic [09:00] o_lcnt1,
    output logic [09:00] o_lcnt2,
    output logic [09:00] o_lcnt3,
    output logic [09:00] o_lcnt4,
    output logic [09:00] o_lcnt5,
    output logic [09:00] o_lcnt6,
    output logic [09:00] o_lcnt7,
    output logic [09:00] o_lcnt8,
    output logic [09:00] o_lcnt9,
    output logic [09:00] o_lcnt10,
    output logic [09:00] o_lcnt11,
    output logic [09:00] o_lcnt12,
    output logic [09:00] o_lcnt13,
    output logic [09:00] o_lcnt14,
    output logic [09:00] o_lcnt15
);

    logic [1:0] music_sel;

    MainControl U_main_control (
        .clk         (clk),
        .reset       (reset),
        .btn_l       (btn_l_f),
        .btn_r       (btn_r_f),
        .btn_d       (btn_d_f),
        .game_done   (game_done),
        .capture_done(capture_done),
        .music_sel   (music_sel),
        .done        (main_done),
        .o_state     (o_state)
    );

    // 3. 게임 코어 로직 (top_game)
    top_game U_top_game (
        .clk       (clk),
        .reset     (reset),
        .music_sel (music_sel),
        .v_sync    (v_sync),
        .region    (region),
        .main_state(o_state),
        .lane_data (lane_data),
        .note_start(note_start),
        // .o_lane      (o_lane),      
        .o_duration(o_duration),
        .score     (score),
        // [원래 코드 백업]
        // .score    (score)
        .perfect   (perfect),
        .good      (good),
        .miss      (miss),
        .combo     (combo),
        .fever     (fever),
        .o_pos0    (o_pos0),
        .o_lcnt0   (o_lcnt0),
        .o_pos1    (o_pos1),
        .o_lcnt1   (o_lcnt1),
        .o_pos2    (o_pos2),
        .o_lcnt2   (o_lcnt2),
        .o_pos3    (o_pos3),
        .o_lcnt3   (o_lcnt3),
        .o_pos4    (o_pos4),
        .o_lcnt4   (o_lcnt4),
        .o_pos5    (o_pos5),
        .o_lcnt5   (o_lcnt5),
        .o_pos6    (o_pos6),
        .o_lcnt6   (o_lcnt6),
        .o_pos7    (o_pos7),
        .o_lcnt7   (o_lcnt7),
        .o_pos8    (o_pos8),
        .o_lcnt8   (o_lcnt8),
        .o_pos9    (o_pos9),
        .o_lcnt9   (o_lcnt9),
        .o_pos10   (o_pos10),
        .o_lcnt10  (o_lcnt10),
        .o_pos11   (o_pos11),
        .o_lcnt11  (o_lcnt11),
        .o_pos12   (o_pos12),
        .o_lcnt12  (o_lcnt12),
        .o_pos13   (o_pos13),
        .o_lcnt13  (o_lcnt13),
        .o_pos14   (o_pos14),
        .o_lcnt14  (o_lcnt14),
        .o_pos15   (o_pos15),
        .o_lcnt15  (o_lcnt15)
    );

endmodule
