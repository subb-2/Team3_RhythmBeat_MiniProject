`timescale 1ns / 1ps
`include "uvm_macros.svh"
import uvm_pkg::*;

//파일 이름과 동일하게 
`include "rhythmGame_interface.sv"
`include "rhythmGame_seq_item.sv"
`include "rhythmGame_sequence.sv"
`include "rhythmGame_driver.sv"
`include "rhythmGame_monitor.sv"
`include "rhythmGame_agent.sv"
`include "rhythmGame_scoreboard.sv"
`include "rhythmGame_coverage.sv"
`include "rhythmGame_env.sv"
`include "rhythmGame_test.sv"

module tb_rhythmGame ();
    logic clk;
    logic reset;

    always #5 clk = ~clk;

    rhythmGame_if vif (
        clk,
        reset
    );

    top_game dut (
        .clk       (clk),
        .reset     (reset),
        .music_sel (vif.music_sel),
        .v_sync    (vif.v_sync),
        .region    (vif.region),
        .main_state(vif.main_state),
        .lane_data (vif.lane_data),
        .note_start(vif.note_start),
        .score     (vif.score),
        .perfect   (vif.perfect),
        .good      (vif.good),
        .miss      (vif.miss),
        .combo     (vif.combo),
        .fever     (vif.fever),
        .o_pos0    (vif.o_pos0),
        .o_pos1    (vif.o_pos1),
        .o_pos2    (vif.o_pos2),
        .o_pos3    (vif.o_pos3),
        .o_pos4    (vif.o_pos4),
        .o_pos5    (vif.o_pos5),
        .o_pos6    (vif.o_pos6),
        .o_pos7    (vif.o_pos7),
        .o_pos8    (vif.o_pos8),
        .o_pos9    (vif.o_pos9),
        .o_pos10   (vif.o_pos10),
        .o_pos11   (vif.o_pos11),
        .o_pos12   (vif.o_pos12),
        .o_pos13   (vif.o_pos13),
        .o_pos14   (vif.o_pos14),
        .o_pos15   (vif.o_pos15),
        .o_lcnt0   (vif.o_lcnt0),
        .o_lcnt1   (vif.o_lcnt1),
        .o_lcnt2   (vif.o_lcnt2),
        .o_lcnt3   (vif.o_lcnt3),
        .o_lcnt4   (vif.o_lcnt4),
        .o_lcnt5   (vif.o_lcnt5),
        .o_lcnt6   (vif.o_lcnt6),
        .o_lcnt7   (vif.o_lcnt7),
        .o_lcnt8   (vif.o_lcnt8),
        .o_lcnt9   (vif.o_lcnt9),
        .o_lcnt10  (vif.o_lcnt10),
        .o_lcnt11  (vif.o_lcnt11),
        .o_lcnt12  (vif.o_lcnt12),
        .o_lcnt13  (vif.o_lcnt13),
        .o_lcnt14  (vif.o_lcnt14),
        .o_lcnt15  (vif.o_lcnt15)
    );
    //인터페이스 config_db에 저장
    initial begin
        clk   = 0;
        reset = 1;
        repeat (5) @(posedge clk);
        reset = 0;
    end

    initial begin
        //data type은 virtual 형태로 해야 함
        uvm_config_db#(virtual rhythmGame_if)::set(null, "*", "vif", vif);
        run_test();
    end

    initial begin
        $fsdbDumpfile("novas.fsdb");
        $fsdbDumpvars(0, tb_rhythmGame, "+all");
    end

endmodule
