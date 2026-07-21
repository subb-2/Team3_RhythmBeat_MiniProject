`timescale 1ns / 1ps

module top_game (
    input  logic        clk,
    input  logic        reset,
    input  logic [ 1:0] music_sel,
    input  logic        v_sync,
    input  logic [ 3:0] region,
    input  logic [ 2:0] main_state,
    //PC에서 받는 노트 lane 정보
    input  logic [ 3:0] lane_data,
    input  logic        note_start,
    output logic [23:0] score,
    // [원래 코드 백업 (사용자 수정 시 perfect, good, miss, combo, fever 아웃풋 포트가 누락되어 판정이 막히는 문제 발생)]
    // );
    output logic        perfect,
    output logic        good,
    output logic        miss,
    output logic [ 9:0] combo,
    output logic        fever,
    // [추가] 새 카메라 모듈의 노트 렌더링용 실시간 Y좌표 출력 포트
    output logic [ 3:0] o_pos0,
    output logic [ 3:0] o_pos1,
    output logic [ 3:0] o_pos2,
    output logic [ 3:0] o_pos3,
    output logic [ 3:0] o_pos4,
    output logic [ 3:0] o_pos5,
    output logic [ 3:0] o_pos6,
    output logic [ 3:0] o_pos7,
    output logic [ 3:0] o_pos8,
    output logic [ 3:0] o_pos9,
    output logic [ 3:0] o_pos10,
    output logic [ 3:0] o_pos11,
    output logic [ 3:0] o_pos12,
    output logic [ 3:0] o_pos13,
    output logic [ 3:0] o_pos14,
    output logic [ 3:0] o_pos15,
    output logic [ 9:0] o_lcnt0,
    output logic [ 9:0] o_lcnt1,
    output logic [ 9:0] o_lcnt2,
    output logic [ 9:0] o_lcnt3,
    output logic [ 9:0] o_lcnt4,
    output logic [ 9:0] o_lcnt5,
    output logic [ 9:0] o_lcnt6,
    output logic [ 9:0] o_lcnt7,
    output logic [ 9:0] o_lcnt8,
    output logic [ 9:0] o_lcnt9,
    output logic [ 9:0] o_lcnt10,
    output logic [ 9:0] o_lcnt11,
    output logic [ 9:0] o_lcnt12,
    output logic [ 9:0] o_lcnt13,
    output logic [ 9:0] o_lcnt14,
    output logic [ 9:0] o_lcnt15
);

    logic [31:0] note_data;
    logic note_done;
    logic [3:0] w_rom_lane; // [추가] 곡 리더기가 읽어온 정적 노트 레인을 임시 보관할 와이어

    // [원래 코드 백업 (사용자 수정 시 perfect, good, miss, combo_done, fever가 내부 와이어로만 선언됨)]
    // logic perfect, good, miss, combo_done, fever;
    logic combo_done;
    logic [9:0] combo_data;
    logic [9:0] current_combo;

    // 외부/UART에는 현재 진행 중인 콤보를 실시간으로 전달함
    // combo_data는 기존처럼 Miss 직전 콤보 점수 계산에만 사용함
    assign combo = current_combo;

    //game reset
    logic game_reset;
    assign game_reset = reset || (main_state != 3'b011);    //GAME_CONT 상태가 아닐 때 rom 초기화


    line_count U_LINE_COUNT (
        .clk     (clk),
        .reset   (game_reset),
        .i_note  (note_start),
        .i_lane  (lane_data),   // i_lane 에 w_rom_lane 매핑
        // [원래 코드 백업 (사용자 수정 시 필터링 안 된 v_sync가 직접 매핑되어 노트 텔레포트 유발)]
        .i_vs    (v_sync),
        //.i_vs   (v_sync_clean),
        .o_pos0  (o_pos0),
        .o_lcnt0 (o_lcnt0),
        .o_pos1  (o_pos1),
        .o_lcnt1 (o_lcnt1),
        .o_pos2  (o_pos2),
        .o_lcnt2 (o_lcnt2),
        .o_pos3  (o_pos3),
        .o_lcnt3 (o_lcnt3),
        .o_pos4  (o_pos4),
        .o_lcnt4 (o_lcnt4),
        .o_pos5  (o_pos5),
        .o_lcnt5 (o_lcnt5),
        .o_pos6  (o_pos6),
        .o_lcnt6 (o_lcnt6),
        .o_pos7  (o_pos7),
        .o_lcnt7 (o_lcnt7),
        .o_pos8  (o_pos8),
        .o_lcnt8 (o_lcnt8),
        .o_pos9  (o_pos9),
        .o_lcnt9 (o_lcnt9),
        .o_pos10 (o_pos10),
        .o_lcnt10(o_lcnt10),
        .o_pos11 (o_pos11),
        .o_lcnt11(o_lcnt11),
        .o_pos12 (o_pos12),
        .o_lcnt12(o_lcnt12),
        .o_pos13 (o_pos13),
        .o_lcnt13(o_lcnt13),
        .o_pos14 (o_pos14),
        .o_lcnt14(o_lcnt14),
        .o_pos15 (o_pos15),
        .o_lcnt15(o_lcnt15)
    );

    GameResult U_GAMERESULT (
        .clk       (clk),
        // [원래 코드 백업 (사용자 수정 시 대기상태 판정기 리셋 방지 누락)]
        // .reset     (reset),
        .reset     (game_reset),
        .o_pos0  (o_pos0),
        .o_lcnt0 (o_lcnt0),
        .o_pos1  (o_pos1),
        .o_lcnt1 (o_lcnt1),
        .o_pos2  (o_pos2),
        .o_lcnt2 (o_lcnt2),
        .o_pos3  (o_pos3),
        .o_lcnt3 (o_lcnt3),
        .o_pos4  (o_pos4),
        .o_lcnt4 (o_lcnt4),
        .o_pos5  (o_pos5),
        .o_lcnt5 (o_lcnt5),
        .o_pos6  (o_pos6),
        .o_lcnt6 (o_lcnt6),
        .o_pos7  (o_pos7),
        .o_lcnt7 (o_lcnt7),
        .o_pos8  (o_pos8),
        .o_lcnt8 (o_lcnt8),
        .o_pos9  (o_pos9),
        .o_lcnt9 (o_lcnt9),
        .o_pos10 (o_pos10),
        .o_lcnt10(o_lcnt10),
        .o_pos11 (o_pos11),
        .o_lcnt11(o_lcnt11),
        .o_pos12 (o_pos12),
        .o_lcnt12(o_lcnt12),
        .o_pos13 (o_pos13),
        .o_lcnt13(o_lcnt13),
        .o_pos14 (o_pos14),
        .o_lcnt14(o_lcnt14),
        .o_pos15 (o_pos15),
        .o_lcnt15(o_lcnt15),
        .region    (region),
        // [원래 코드 백업 (사용자 수정 시 필터링 안 된 v_sync가 직접 매핑되어 판정 마스크 꼬임 유발)]
        .v_sync    (v_sync),
        //.v_sync    (v_sync_clean),
        .perfect   (perfect),
        .good      (good),
        .miss      (miss),
        .combo_done(combo_done),
        // [원래 코드 백업 (사용자 수정 시 combo_data 핀에 오타 combd_data가 매핑되어 컴파일 에러 발생)]
        // .combo_data(combd_data),
        .combo_data(combo_data),
        .current_combo(current_combo),
        .fever     (fever)
        // .o_lane    (o_lane)  // [추가] 실시간 조합된 노트 X좌표를 모듈 밖으로 출력
    );

    score U_SCORE (
        .clk       (clk),
        .reset     (reset),
        .main_state(main_state),
        .good      (good),
        .perfect   (perfect),
        .miss      (miss),
        .combo_done(combo_done),
        .combo_data(combo_data),
        .fever     (fever),
        .score     (score)
    );

endmodule
