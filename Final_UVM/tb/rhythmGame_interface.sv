interface rhythmGame_if (
    input logic clk,
    input logic reset
);
    // ==========================================
    // 1. 입력 제어 신호 (Driver -> DUT)
    // ==========================================
    logic [ 1:0] music_sel;
    logic        v_sync;
    logic [ 3:0] region;
    logic [ 2:0] main_state;
    logic [ 3:0] lane_data;
    logic        note_start;

    // ==========================================
    // 2. 출력 결과 신호 (DUT -> Monitor)
    // ==========================================
    logic [23:0] score;
    logic        perfect;
    logic        good;
    logic        miss;
    logic [ 9:0] combo;
    logic        fever;

    // ==========================================
    // 3. 디버깅용 실시간 슬롯 정보 (DUT -> Monitor)
    // ==========================================
    logic [ 3:0] o_pos0;
    logic [ 3:0] o_pos1;
    logic [ 3:0] o_pos2;
    logic [ 3:0] o_pos3;
    logic [ 3:0] o_pos4;
    logic [ 3:0] o_pos5;
    logic [ 3:0] o_pos6;
    logic [ 3:0] o_pos7;
    logic [ 3:0] o_pos8;
    logic [ 3:0] o_pos9;
    logic [ 3:0] o_pos10;
    logic [ 3:0] o_pos11;
    logic [ 3:0] o_pos12;
    logic [ 3:0] o_pos13;
    logic [ 3:0] o_pos14;
    logic [ 3:0] o_pos15;
    logic [ 9:0] o_lcnt0;
    logic [ 9:0] o_lcnt1;
    logic [ 9:0] o_lcnt2;
    logic [ 9:0] o_lcnt3;
    logic [ 9:0] o_lcnt4;
    logic [ 9:0] o_lcnt5;
    logic [ 9:0] o_lcnt6;
    logic [ 9:0] o_lcnt7;
    logic [ 9:0] o_lcnt8;
    logic [ 9:0] o_lcnt9;
    logic [ 9:0] o_lcnt10;
    logic [ 9:0] o_lcnt11;
    logic [ 9:0] o_lcnt12;
    logic [ 9:0] o_lcnt13;
    logic [ 9:0] o_lcnt14;
    logic [ 9:0] o_lcnt15;


    clocking drv_cb @(posedge clk);
        default input #1step output #0;

        output music_sel;
        output v_sync;
        output region;
        output main_state;
        output lane_data;
        output note_start;
    endclocking

    clocking mon_cb @(posedge clk);
        default input #1step;
        input music_sel;
        input v_sync;
        input region;
        input main_state;
        input lane_data;
        input note_start;
        input score;
        input perfect;
        input good;
        input miss;
        input combo;
        input fever;
        input o_pos0;
        input o_pos1;
        input o_pos2;
        input o_pos3;
        input o_pos4;
        input o_pos5;
        input o_pos6;
        input o_pos7;
        input o_pos8;
        input o_pos9;
        input o_pos10;
        input o_pos11;
        input o_pos12;
        input o_pos13;
        input o_pos14;
        input o_pos15;
        input o_lcnt0;
        input o_lcnt1;
        input o_lcnt2;
        input o_lcnt3;
        input o_lcnt4;
        input o_lcnt5;
        input o_lcnt6;
        input o_lcnt7;
        input o_lcnt8;
        input o_lcnt9;
        input o_lcnt10;
        input o_lcnt11;
        input o_lcnt12;
        input o_lcnt13;
        input o_lcnt14;
        input o_lcnt15;
    endclocking

    modport mp_drv(clocking drv_cb, input clk, input reset);
    modport mp_mon(clocking mon_cb, input clk, input reset);

endinterface
