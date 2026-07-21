`ifndef SCOREBOARD_SV
`define SCOREBOARD_SV

`include "uvm_macros.svh"
import uvm_pkg::*;
`include "rhythmGame_seq_item.sv"

class rhythmGame_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(rhythmGame_scoreboard)

    //통신 통로
    uvm_analysis_imp #(rhythmGame_seq_item, rhythmGame_scoreboard) ap_imp;

    // 스코어보드 내부에서 독자적으로 계산할 예상 점수/콤보 변수
    int expected_score = 0;
    int expected_combo = 0;
    int pending_bonus = 0;

    int num_errors = 0;
    int num_perfect = 0;
    int num_good = 0;
    int num_miss = 0;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction  //new()

    //scb, cov 경우에는 report 까지 하는 경우도 있음
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        ap_imp = new("ap_imp", this);
    endfunction

    virtual function void write(rhythmGame_seq_item item);
        expected_score += pending_bonus;  // ← 이 두 줄 추가
        pending_bonus = 0;

        // 예상 점수 및 각 판정 별 카운팅 누적
        if (item.perfect) begin
            expected_score += (item.fever ? 200 : 100);
            expected_combo += 1;
            num_perfect++;  // Perfect 개수 누적
        end else if (item.good) begin
            expected_score += (item.fever ? 100 : 50);
            num_good++;  // Good 개수 누적
        end else if (item.miss) begin
            // 끊긴 콤보로 보너스를 계산해서 메모만 해둠 (지금 더하지 않음)
            if (expected_combo != 0) begin
                int cr = expected_combo * (expected_combo + 1);
                if (cr <= 101) pending_bonus = cr >> 1;
                else if (cr <= 2550) pending_bonus = cr;
                else pending_bonus = (cr * 3) >> 1;
            end
            expected_combo = 0;
            num_miss++;
        end

        // 스코어 및 콤보 검증
        if (item.perfect || item.good || item.miss) begin

            // [스코어 검증]
            if (expected_score !== item.score) begin
                num_errors++;
                `uvm_error(
                    get_type_name(),
                    $sformatf(
                        "FAIL! Score Mismatch: expected = %0d, actual = %0d",
                        expected_score, item.score))
            end else begin
                `uvm_info(get_type_name(), $sformatf(
                          "PASS! Score Match: expected = %0d, actual = %0d",
                          expected_score,
                          item.score
                          ), UVM_MEDIUM)
            end
            // [콤보 검증]
            if (expected_combo !== item.combo) begin
                num_errors++;
                `uvm_error(
                    get_type_name(),
                    $sformatf(
                        "FAIL! Combo Mismatch: expected = %0d, actual = %0d",
                        expected_combo, item.combo))
            end else begin
                `uvm_info(get_type_name(), $sformatf(
                          "PASS! Combo Match: expected = %0d, actual = %0d",
                          expected_combo,
                          item.combo
                          ), UVM_MEDIUM)
            end
        end

    endfunction

    virtual function void report_phase(uvm_phase phase);
        string result = (num_errors == 0) ? "** PASS **" : "** FAIL **";

        super.report_phase(phase);

        `uvm_info(get_type_name(),
                  "************* summary report ***************", UVM_MEDIUM)
        `uvm_info(get_type_name(), $sformatf("Result      : %s", result),
                  UVM_MEDIUM)
        `uvm_info(get_type_name(), $sformatf("Perfect num : %0d", num_perfect),
                  UVM_MEDIUM)
        `uvm_info(get_type_name(), $sformatf("Good num    : %0d", num_good),
                  UVM_MEDIUM)
        `uvm_info(get_type_name(), $sformatf("Miss num    : %0d", num_miss),
                  UVM_MEDIUM)
        `uvm_info(get_type_name(), $sformatf("Error num   : %0d", num_errors),
                  UVM_MEDIUM)
        `uvm_info(get_type_name(),
                  "*******************************************", UVM_MEDIUM)
    endfunction

endclass  //component 

`endif
