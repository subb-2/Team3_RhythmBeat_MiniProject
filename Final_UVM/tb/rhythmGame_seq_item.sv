`ifndef RHYTHMGAME_SEQ_ITEM_SV
`define RHYTHMGAME_SEQ_ITEM_SV

`include "uvm_macros.svh"
import uvm_pkg::*;

class rhythmGame_seq_item extends uvm_sequence_item;
    // ==========================================
    // 입력 제어 신호 (Driver -> DUT)
    // ==========================================
    rand logic [1:0] music_sel;
    logic v_sync;
    rand logic [3:0] region;  // 타격 신호 (사용자 입력)
    rand logic [2:0] main_state;  // 메인 제어기 상태
    rand logic [3:0] lane_data;  // 수신 노트 정보
    rand logic note_start;  // 노트 시작 펄스

    // DUT -> Monitor
    logic [23:0] score;
    logic perfect;
    logic good;
    logic miss;
    logic [9:0] combo;
    logic fever;

    logic [3:0] pos[0:15];  // 각 슬롯의 레인
    logic [9:0] lcnt[0:15];  // 각 슬롯의 Y좌표

    // 게임 상태 활성화 
    constraint c_game_state {main_state == 3'b011;}

    //factory에 등록하는 절차 
    `uvm_object_utils_begin(rhythmGame_seq_item)
        `uvm_field_int(music_sel, UVM_ALL_ON)
        `uvm_field_int(v_sync, UVM_ALL_ON)
        `uvm_field_int(region, UVM_ALL_ON)
        `uvm_field_int(main_state, UVM_ALL_ON)
        `uvm_field_int(lane_data, UVM_ALL_ON)
        `uvm_field_int(note_start, UVM_ALL_ON)
        `uvm_field_int(score, UVM_ALL_ON)
        `uvm_field_int(perfect, UVM_ALL_ON)
        `uvm_field_int(good, UVM_ALL_ON)
        `uvm_field_int(miss, UVM_ALL_ON)
        `uvm_field_int(combo, UVM_ALL_ON)
        `uvm_field_int(fever, UVM_ALL_ON)
    `uvm_object_utils_end

    function new(string name = "rhythmGame_seq_item");
        super.new(name);
    endfunction  //new()

    function string convert2string();
        // 어떤 종류의 동작을 수헹 중인지 표시해주는 구분 태그 
        string event_tag;

        // 동작 상황에따ㄸ라 태그 분기
        if (note_start && region != 4'b0000)
            event_tag = "NOTE_AND_HIT"; // 노트가 내려오는 동시에 손 타격
        else if (note_start)
            event_tag = "NOTE_START";  // 단순히 새 노트만 생성됨
        else if (region != 4'b0000)
            event_tag = "USER_TAP"; // 노트는 없는데 사용자가 타격함
        else event_tag = "IDLE_FRAME";  // 조용한 프레임

        return $sformatf(
            "[%s] v_sync=%b note_start=%b lane_data=%b region=%b main_state=%b",
            event_tag,
            v_sync,
            note_start,
            lane_data,
            region,
            main_state
        );

    endfunction
endclass

`endif
