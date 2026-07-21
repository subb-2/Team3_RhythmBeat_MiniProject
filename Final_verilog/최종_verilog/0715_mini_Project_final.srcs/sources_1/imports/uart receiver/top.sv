`timescale 1ns / 1ps

module top (
    input logic       clk,
    input logic       reset,
    input logic [3:0] btn,    // [0][1][2][3] : U, L, R, D
    // input logic sw,

    input  logic       vsync,
    output logic       xclk,
    input  logic       pclk,
    input  logic       href,
    input  logic [7:0] pdata,
    output logic       h_sync,
    output logic       v_sync,
    output logic [3:0] port_red,
    output logic [3:0] port_green,
    output logic [3:0] port_blue,
    output logic       scl,
    inout  logic       sda,

    output logic main_done,

    input  logic rx,
    output logic tx,

    output logic o_note_start,
    output logic [3:0] r_data
);

    logic [ 3:0] region;
    logic [ 2:0] w_state;
    logic [23:0] w_score;
    // [원래 코드 백업]
    // logic [23:0] w_score;
    logic        w_perfect;
    logic        w_good;
    logic        w_miss;
    logic [ 9:0] w_combo;
    logic        w_fever;

    logic        w_vga_sync;
    assign v_sync = w_vga_sync;

    // [이전 원래 코드 백업]
    // logic w_v_sync;
    // assign vsync = w_v_sync;

    logic w_cam_vsync;
    assign w_cam_vsync = vsync; // 입력 vsync 값을 내부 와이어로 할당

    logic o_btn_u, o_btn_l, o_btn_r, o_btn_d;


    logic [3:0]
        o_pos0,
        o_pos1,
        o_pos2,
        o_pos3,
        o_pos4,
        o_pos5,
        o_pos6,
        o_pos7,
        o_pos8,
        o_pos9,
        o_pos10,
        o_pos11,
        o_pos12,
        o_pos13,
        o_pos14,
        o_pos15;
    logic [9:0]
        o_lcnt0,
        o_lcnt1,
        o_lcnt2,
        o_lcnt3,
        o_lcnt4,
        o_lcnt5,
        o_lcnt6,
        o_lcnt7,
        o_lcnt8,
        o_lcnt9,
        o_lcnt10,
        o_lcnt11,
        o_lcnt12,
        o_lcnt13,
        o_lcnt14,
        o_lcnt15;
    logic       clk_100M;
    logic       clk_25M;
    logic [3:0] w_lane_data;
    logic w_note_start, w_game_done;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            o_note_start <= 1'b0;
        end else begin
            if (w_note_start) begin
                o_note_start <= ~o_note_start;
            end
        end
    end

    clk_wiz_0 instance_name (
        // Clock out ports
        .clk_100M(clk_100M),     // output clk_100M
        .clk_25M(clk_25M),     // output clk_25M
        // Status and control signals
        .reset(reset), // input reset
        // Clock in ports
        .clk_in1(clk)
    );  // input clk_in1

    BtnDebouncer U_debouncer_u (
        .clk  (clk),
        .reset(reset),
        .i_btn(btn[0]),
        .o_btn(o_btn_u)
    );

    BtnDebouncer U_debouncer_l (
        .clk  (clk),
        .reset(reset),
        .i_btn(btn[1]),
        .o_btn(o_btn_l)
    );

    BtnDebouncer U_debouncer_r (
        .clk  (clk),
        .reset(reset),
        .i_btn(btn[2]),
        .o_btn(o_btn_r)
    );

    BtnDebouncer U_debouncer_d (
        .clk  (clk),
        .reset(reset),
        .i_btn(btn[3]),
        .o_btn(o_btn_d)
    );

    MainController U_MainController (
        .clk(clk),
        .reset(reset),
        .btn_l_f(o_btn_l),
        .btn_r_f(o_btn_r),
        .btn_d_f(o_btn_d),
        .v_sync(w_vga_sync), // 게임 프레임 처리는 VGA 60Hz 동기화 신호에 매핑 (이전 코드: .v_sync(w_v_sync))
        .region(region),
        .capture_done(),
        .lane_data(w_lane_data),
        .note_start(w_note_start),
        .game_done(w_game_done),
        .main_done(main_done),
        .o_state(w_state),
        // .o_lane(),
        .o_duration(),
        .score(w_score),
        // [원래 코드 백업]
        // .score    (w_score)
        // );
        .perfect(w_perfect),
        .good(w_good),
        .miss(w_miss),
        .combo(w_combo),
        .fever(w_fever),
        .o_pos0(o_pos0),
        .o_lcnt0(o_lcnt0),
        .o_pos1(o_pos1),
        .o_lcnt1(o_lcnt1),
        .o_pos2(o_pos2),
        .o_lcnt2(o_lcnt2),
        .o_pos3(o_pos3),
        .o_lcnt3(o_lcnt3),
        .o_pos4(o_pos4),
        .o_lcnt4(o_lcnt4),
        .o_pos5(o_pos5),
        .o_lcnt5(o_lcnt5),
        .o_pos6(o_pos6),
        .o_lcnt6(o_lcnt6),
        .o_pos7(o_pos7),
        .o_lcnt7(o_lcnt7),
        .o_pos8(o_pos8),
        .o_lcnt8(o_lcnt8),
        .o_pos9(o_pos9),
        .o_lcnt9(o_lcnt9),
        .o_pos10(o_pos10),
        .o_lcnt10(o_lcnt10),
        .o_pos11(o_pos11),
        .o_lcnt11(o_lcnt11),
        .o_pos12(o_pos12),
        .o_lcnt12(o_lcnt12),
        .o_pos13(o_pos13),
        .o_lcnt13(o_lcnt13),
        .o_pos14(o_pos14),
        .o_lcnt14(o_lcnt14),
        .o_pos15(o_pos15),
        .o_lcnt15(o_lcnt15)
    );

    sender #(
        .CLK_FREQ (100_000_000),
        .BAUD_RATE(115_200)
    ) U_sender (
        .clk(clk),
        .reset(reset),
        // .sw(sw),
        .fifo_full(),  // full -> push 불가능
        .tx(tx),
        .main_state(w_state),
        .btn({o_btn_u, o_btn_d, o_btn_r, o_btn_l}),
        // .hit       (),
        .fever(w_fever),
        .perfect(w_perfect),
        .good(w_good),
        .miss(w_miss),
        .combo(w_combo[7:0]),
        .score(w_score)

        // input logic [11:0] capture_data[0:8799],
        // input logic        done_cap
    );

    receiver U_RECEIVER (
        .clk(clk),
        .reset(reset),
        .v_sync(v_sync),
        .rx(rx),
        .lane_data(w_lane_data),
        .note_start(w_note_start),
        .game_done(w_game_done),
        .r_data(r_data)
    );

    VGAcam U_VGAcam (
        .clk_100M  (clk_100M),
        .clk_25M   (clk_25M),
        .reset     (reset),
        .xclk      (xclk),
        .pclk      (pclk),
        .href      (href),
        .vsync     (w_cam_vsync),
        .pdata     (pdata),
        .h_sync    (h_sync),
        .v_sync    (w_vga_sync),
        .note_x0   (o_pos0),
        .note_x1   (o_pos1),
        .note_x2   (o_pos2),
        .note_x3   (o_pos3),
        .note_x4   (o_pos4),
        .note_x5   (o_pos5),
        .note_x6   (o_pos6),
        .note_x7   (o_pos7),
        .note_x8   (o_pos8),
        .note_x9   (o_pos9),
        .note_x10  (o_pos10),
        .note_x11  (o_pos11),
        .note_x12  (o_pos12),
        .note_x13  (o_pos13),
        .note_x14  (o_pos14),
        .note_x15  (o_pos15),
        .note_y0   (o_lcnt0),
        .note_y1   (o_lcnt1),
        .note_y2   (o_lcnt2),
        .note_y3   (o_lcnt3),
        .note_y4   (o_lcnt4),
        .note_y5   (o_lcnt5),
        .note_y6   (o_lcnt6),
        .note_y7   (o_lcnt7),
        .note_y8   (o_lcnt8),
        .note_y9   (o_lcnt9),
        .note_y10  (o_lcnt10),
        .note_y11  (o_lcnt11),
        .note_y12  (o_lcnt12),
        .note_y13  (o_lcnt13),
        .note_y14  (o_lcnt14),
        .note_y15  (o_lcnt15),
        .port_red  (port_red),
        .port_green(port_green),
        .port_blue (port_blue),
        .region    (region),
        .scl       (scl),
        .sda       (sda)
    );
endmodule
