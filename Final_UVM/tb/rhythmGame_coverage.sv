`ifndef COVERAGE_SV
`define COVERAGE_SV

`include "uvm_macros.svh"
import uvm_pkg::*;
`include "rhythmGame_seq_item.sv"

//템플릿 
class rhythmGame_coverage extends uvm_subscriber #(rhythmGame_seq_item);
    `uvm_component_utils(rhythmGame_coverage)

    //covergroup 만들기 위해 seq_item 필요
    rhythmGame_seq_item req;
    bit [3:0] active_lane;
    bit [2:0] verdict_val;     // {perfect, good, miss}

    covergroup cg_rhythm_game;

        // 1. 노트 생성 레인 데이터 측정
        // cp_lane: coverpoint req.lane_data {
        cp_lane: coverpoint active_lane {
            bins lane_1 = {4'b0001};
            bins lane_2 = {4'b0010};
            bins lane_3 = {4'b0100};
            bins lane_4 = {4'b1000};
        }
        // 2. 플레이어의 버튼(영역) 입력 레인 측정
        cp_region: coverpoint req.region {
            bins press_1 = {4'b0001};
            bins press_2 = {4'b0010};
            bins press_3 = {4'b0100};
            bins press_4 = {4'b1000};
            bins no_press = {4'b0000};  // 손을 뗀 상태
        }
        // 3. 교차 커버리지: 노트 위치와 손 입력 위치가 정상적으로 크로스 매치되었는가?
        cross_lane_press: cross cp_lane, cp_region;

        cp_verdict: coverpoint verdict_val {
            bins perfect = {3'b100};
            bins good = {3'b010};
            bins miss = {3'b001};
            bins none = {3'b000};
        }

        cross_lane_verdict: cross cp_lane, cp_verdict;

    endgroup  // cg_rhythm_game

    function new(string name, uvm_component parent);
        super.new(name, parent);
        cg_rhythm_game = new();
    endfunction  //new()

    virtual function void write(rhythmGame_seq_item t);
        req = t;
        if (t.note_start) begin
            active_lane = t.lane_data;
        end
        verdict_val = {t.perfect, t.good, t.miss};
        //sample을 하면 수집됨 
        cg_rhythm_game.sample();
    endfunction

    // =========================================================================
    // [커버리지 요약 리포트]
    // =========================================================================
    virtual function void report_phase(uvm_phase phase);
        super.report_phase(phase);

        `uvm_info(get_type_name(), "===== Coverage Summary =====", UVM_LOW)

        // 전체 커버리지율 출력
        `uvm_info(
            get_type_name(), $sformatf(
            "    Overall             : %.1f%%", cg_rhythm_game.get_coverage()),
            UVM_LOW)

        // 1. 노트 라인 커버리지 출력
        `uvm_info(get_type_name(), $sformatf(
                  "    Lane Cover          : %.1f%%",
                  cg_rhythm_game.cp_lane.get_coverage()
                  ), UVM_LOW)

        // 2. 버튼 입력 커버리지 출력
        `uvm_info(get_type_name(), $sformatf(
                  "    Region (Press) Cover: %.1f%%",
                  cg_rhythm_game.cp_region.get_coverage()
                  ), UVM_LOW)

        // 3. 교차(Cross) 커버리지 출력
        `uvm_info(get_type_name(), $sformatf(
                  "    Cross(lane, press)  : %.1f%%",
                  cg_rhythm_game.cross_lane_press.get_coverage()
                  ), UVM_LOW)

        // 4. 판정 결과 커버리지 출력
        `uvm_info(get_type_name(), $sformatf(
                  "    Verdict Cover       : %.1f%%",
                  cg_rhythm_game.cp_verdict.get_coverage()
                  ), UVM_LOW)

        // 5. 레인별 판정 결과 교차 커버리지 출력
        `uvm_info(get_type_name(), $sformatf(
                  "    Cross(lane,verdict) : %.1f%%",
                  cg_rhythm_game.cross_lane_verdict.get_coverage()
                  ), UVM_LOW)

        `uvm_info(get_type_name(), "===== Coverage Summary =====\n\n", UVM_LOW)
    endfunction

endclass  //component 

`endif
