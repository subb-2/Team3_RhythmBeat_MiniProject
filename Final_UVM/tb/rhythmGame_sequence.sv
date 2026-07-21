`ifndef RHYTHMGAME_SEQUENCE_SV
`define RHYTHMGAME_SEQUENCE_SV

`include "uvm_macros.svh"
import uvm_pkg::*;
`include "rhythmGame_seq_item.sv"

class rhythmGame_seq extends uvm_sequence #(rhythmGame_seq_item);
    `uvm_object_utils(rhythmGame_seq)

    function new(string name = "rhythmGame_seq");
        super.new(name);
    endfunction  //new()

    function automatic bit [3:0] lane_to_region(bit [3:0] lane);
        return {lane[0], lane[1], lane[2], lane[3]};
    endfunction

    // ----------------------------------------------------
    // [Helper Task 1] 노트 생성 (lane_data와 note_start 주입)
    // ----------------------------------------------------
    task send_note(bit [3:0] lane);
        rhythmGame_seq_item item;
        item = rhythmGame_seq_item::type_id::create("item");
        start_item(item);

        item.note_start = 1'b1;
        item.lane_data = lane;
        item.region = 4'b0000;
        item.v_sync = 1'b0;
        item.main_state = 3'b011;

        finish_item(item);
    endtask

    // ----------------------------------------------------
    // [Helper Task 2] 플레이어 입력 없이 v_sync만 토글하여 대기 (노트 하강)
    // ----------------------------------------------------
    task wait_frames(int num_frames);
        repeat (num_frames) begin
            rhythmGame_seq_item item;

            // v_sync = 1 (프레임 갱신 시작)
            item = rhythmGame_seq_item::type_id::create("item");
            start_item(item);
            item.note_start = 1'b0;
            item.lane_data = 4'b0000;
            item.region = 4'b0000;
            item.v_sync = 1'b1;
            item.main_state = 3'b011;
            finish_item(item);

            // v_sync = 0 (비활성화)
            item = rhythmGame_seq_item::type_id::create("item");
            start_item(item);
            item.note_start = 1'b0;
            item.lane_data  = 4'b0000;
            item.region     = 4'b0000;
            item.v_sync     = 1'b0;
            item.main_state = 3'b011;
            finish_item(item);
        end
    endtask

    // ----------------------------------------------------
    // [Helper Task 3] 판정 타이밍에 v_sync와 함께 플레이어 입력 주입
    // ----------------------------------------------------
    task press_region(bit [3:0] region_val);
        rhythmGame_seq_item item;

        // 1. 손 입력 + v_sync High
        item = rhythmGame_seq_item::type_id::create("press_high");
        start_item(item);
        item.note_start = 1'b0;
        item.lane_data  = 4'b0000;
        item.region     = region_val;
        item.v_sync     = 1'b1;
        item.main_state = 3'b011;
        finish_item(item);

        // 2. v_sync 하강 에지
        // DUT가 판정하는 순간이므로 region을 계속 유지
        item = rhythmGame_seq_item::type_id::create("press_tick");
        start_item(item);
        item.note_start = 1'b0;
        item.lane_data  = 4'b0000;
        item.region     = region_val;
        item.v_sync     = 1'b0;
        item.main_state = 3'b011;
        finish_item(item);

        // 3. 판정 후 손 입력 해제
        item = rhythmGame_seq_item::type_id::create("press_release");
        start_item(item);
        item.note_start = 1'b0;
        item.lane_data  = 4'b0000;
        item.region     = 4'b0000;
        item.v_sync     = 1'b0;
        item.main_state = 3'b011;
        finish_item(item);
    endtask  //press_region

endclass

// =========================================================================
// 1. [Perfect 시퀀스] 판정선 중앙(Y=400 부근)에서 정확히 누르는 케이스
// =========================================================================
class Perfect_seq extends rhythmGame_seq;
    `uvm_object_utils(Perfect_seq)

    function new(string name = "Perfect_seq");
        super.new(name);
    endfunction  //new()

    virtual task body();
        bit [3:0] lane;

        lane = 4'b0001;

        `uvm_info(get_type_name(), "Perfect_seq 시나리오 시작!", UVM_LOW)

        send_note(lane);
        wait_frames(212);
        press_region(lane_to_region(lane));
        wait_frames(10);

        `uvm_info(get_type_name(), "Perfect_seq 시나리오 종료!", UVM_LOW)
    endtask
endclass

// =========================================================================
// 2. [Good 시퀀스] 판정선에 도달하기 약간 직전(Y=384 부근)에 일찍 누르는 케이스
// =========================================================================
class Good_seq extends rhythmGame_seq;
    `uvm_object_utils(Good_seq)

    function new(string name = "Good_seq");
        super.new(name);
    endfunction

    virtual task body();
        bit [3:0] lane;

        lane = 4'b0001;

        `uvm_info(get_type_name(), "Good_seq 시나리오 시작!", UVM_LOW)

        send_note(lane);
        wait_frames(195);
        press_region(lane_to_region(lane));
        wait_frames(10);

        `uvm_info(get_type_name(), "Good_seq 시나리오 종료!", UVM_LOW)
    endtask
endclass

// =========================================================================
// 3. [Miss 시퀀스] 버튼을 전혀 누르지 않고 지나쳐버리는 케이스
// =========================================================================
class Miss_seq extends rhythmGame_seq;
    `uvm_object_utils(Miss_seq)

    function new(string name = "Miss_seq");
        super.new(name);
    endfunction

    virtual task body();
        bit [3:0] lane;

        lane = 4'b0001;

        `uvm_info(get_type_name(), "Miss_seq 시나리오 시작!", UVM_LOW)

        send_note(lane);

        // Y=465를 지나야 Miss 발생
        wait_frames(234);
        `uvm_info(get_type_name(), "Miss_seq 시나리오 종료!", UVM_LOW)
    endtask
endclass

// =========================================================================
// 4. [조기 입력 무시 검증 시퀀스] 
//    판정존 전의 성급한 입력은 무시하고, 진짜 판정 타이밍에 정상 판정되는지 검증
// =========================================================================
class IgnoreEarlyPress_seq extends rhythmGame_seq;
    `uvm_object_utils(IgnoreEarlyPress_seq)

    function new(string name = "IgnoreEarlyPress_seq");
        super.new(name);
    endfunction

    virtual task body();
        bit [3:0] lane;

        lane = 4'b0001;
        `uvm_info(get_type_name(), "IgnoreEarlyPress_seq 시나리오 시작!",
                  UVM_LOW)

        // 1. 1번 레인 노트 생성 (Y=0)
        send_note(lane);

        // 2. 노트가 내려가는 도중 (Y=120 부근) 판정 영역보다 한참 전에 대기
        wait_frames(30);

        // 3. 판정 영역 도달 전 성급하게 손을 감지시킴 (조기 입력)
        // -> [검증 포인트 1] 이 시점에 perfect, good, miss 모두 0(무반응)이어야 합니다.
        press_region(lane_to_region(lane));

        // 4. 진짜 판정선 근처(Y=400)까지 마저 내려올 때까지 대기
        // (앞서 총 30프레임 대기 + 입력용 2프레임 소모했으므로 68프레임 추가 대기)
        wait_frames(181);

        // 5. 진짜 판정선 타이밍에 다시 입력 주입
        // -> [검증 포인트 2] 앞선 조기 입력과 무관하게 정상적으로 'perfect' 판정이 나와야 합니다.
        press_region(lane_to_region(lane));

        // 6. 결과 관찰 대기
        wait_frames(10);

        `uvm_info(get_type_name(), "IgnoreEarlyPress_seq 시나리오 종료!",
                  UVM_LOW)
    endtask
endclass

// =========================================================================
// 5. [랜덤 시퀀스] 레인·타이밍·오타 여부를 무작위로 뽑아 한 노트를 검증
// =========================================================================
class Random_seq extends rhythmGame_seq;
    `uvm_object_utils(Random_seq)

    // ---- 랜덤화 대상 ----
    rand bit [3:0] lane;        // 노트를 뿌릴 레인 (one-hot)
    rand bit [3:0] press_lane;  // 실제로 누를 레인 (one-hot)
    rand int       wait_cnt;    // 몇 프레임 뒤에 누를까
    rand bit       do_press;    // 아예 안 누르는(Miss) 경우도 섞기

    // ---- 예측 결과 ----
    string         expected;

    constraint c_lane {
        lane       inside {4'b0001, 4'b0010, 4'b0100, 4'b1000};
        press_lane inside {4'b0001, 4'b0010, 4'b0100, 4'b1000};
    }

    // 65% 정타 / 35% 오타
    constraint c_wrong {
        press_lane dist {
            lane   :/ 65,
            [0:15] :/ 35
        };
    }

    // 판정 시점 lcnt = 2 * wait_cnt
    //   Good(이른)  lcnt 386~404  -> 193~202
    //   Perfect     lcnt 406~444  -> 203~222
    //   Good(늦은)  lcnt 446~464  -> 223~232
    //   Miss        lcnt 466~     -> 233~
    constraint c_wait {
        wait_cnt inside {[193 : 236]};
        wait_cnt dist {
            [193 : 202] :/ 20,
            [203 : 222] :/ 40,
            [223 : 232] :/ 20,
            [233 : 236] :/ 20
        };
    }

    constraint c_press {
        do_press dist {
            1 :/ 90,
            0 :/ 10
        };
    }

    function new(string name = "Random_seq");
        super.new(name);
    endfunction

    function void post_randomize();
        int lcnt;
        if (!do_press) begin
            expected = "MISS";                  // 입력 없음
        end else if (press_lane != lane) begin
            expected = "MISS";                  // 오타 -> 판정 안 되고 통과
        end else begin
            lcnt = 2 * wait_cnt;
            if (lcnt < 385) expected = "NONE";
            else if (lcnt <= 404) expected = "GOOD";
            else if (lcnt <= 445) expected = "PERFECT";
            else if (lcnt <= 465) expected = "GOOD";
            else expected = "MISS";
        end
    endfunction

    virtual task body();
        `uvm_info(get_type_name(), $sformatf(
                  "Random_seq 시작: lane=%b press_lane=%b wait=%0d press=%0b expected=%s",
                  lane, press_lane, wait_cnt, do_press, expected), UVM_LOW)

        send_note(lane);
        wait_frames(wait_cnt);

        if (do_press) press_region(lane_to_region(press_lane));

        // 정타 입력이면 판정이 바로 나오므로 짧게,
        // 오타/미입력이면 노트가 465를 통과해 Miss가 날 때까지 대기
        if (do_press && press_lane == lane) wait_frames(15);
        else                                wait_frames(240 - wait_cnt);

        `uvm_info(get_type_name(), "Random_seq 종료!", UVM_LOW)
    endtask
endclass

// // =========================================================================
// // 5. [랜덤 시퀀스] 레인과 타이밍을 무작위로 뽑아 한 노트를 검증
// // =========================================================================
// class Random_seq extends rhythmGame_seq;
//     `uvm_object_utils(Random_seq)

//     // ---- 랜덤화 대상 ----
//     rand bit [3:0] lane;      // 노트를 뿌릴 레인 (one-hot)
//     rand int       wait_cnt;  // 몇 프레임 뒤에 누를까
//     rand bit       do_press;  // 아예 안 누르는(Miss) 경우도 섞기

//     // ---- 예측 결과 (randomize 후 계산) ----
//     string         expected;

//     constraint c_lane {lane inside {4'b0001, 4'b0010, 4'b0100, 4'b1000};}

//     // 판정 시점 lcnt = 2 * wait_cnt
//     //   Good(이른)  lcnt 386~404  -> 193~202
//     //   Perfect     lcnt 406~444  -> 203~222
//     //   Good(늦은)  lcnt 446~464  -> 223~232
//     //   Miss        lcnt 466~     -> 233~
//     constraint c_wait {
//         wait_cnt inside {[193 : 236]};
//         wait_cnt dist {
//             [193 : 202] :/ 20,
//             [203 : 222] :/ 40,
//             [223 : 232] :/ 20,
//             [233 : 236] :/ 20
//         };
//     }

//     constraint c_press {
//         do_press dist {
//             1 :/ 90,
//             0 :/ 10
//         };
//     }

//     function new(string name = "Random_seq");
//         super.new(name);
//     endfunction

//     function void post_randomize();
//         int lcnt;
//         if (!do_press) begin
//             expected = "MISS";
//         end else begin
//             lcnt = 2 * wait_cnt;          // 2*wait_cnt - 2 였던 것 수정
//             if (lcnt < 385) expected = "NONE";
//             else if (lcnt <= 404) expected = "GOOD";
//             else if (lcnt <= 445) expected = "PERFECT";
//             else if (lcnt <= 465) expected = "GOOD";
//             else expected = "MISS";
//         end
//     endfunction

//     virtual task body();
//         `uvm_info(get_type_name(), $sformatf(
//                   "Random_seq 시작: lane=%b wait=%0d press=%0b expected=%s",
//                   lane, wait_cnt, do_press, expected), UVM_LOW)

//         send_note(lane);
//         wait_frames(wait_cnt);

//         if (do_press) press_region(lane_to_region(lane));

//         // 미입력 시 노트가 ZONE_MAX(465)를 통과해 Miss가 날 때까지 대기
//         // lcnt = 2*N 이므로 233프레임이면 466 도달 -> 총 240프레임 확보
//         if (do_press) wait_frames(15);
//         else          wait_frames(240 - wait_cnt);

//         `uvm_info(get_type_name(), "Random_seq 종료!", UVM_LOW)
//     endtask
// endclass

// =========================================================================
// [증거 수집용] 콤보 보너스 검증 시퀀스
// =========================================================================
class ComboBonus_seq extends rhythmGame_seq;
    `uvm_object_utils(ComboBonus_seq)

    function new(string name = "ComboBonus_seq");
        super.new(name);
    endfunction

    virtual task body();
        bit [3:0] lane = 4'b0001;

        `uvm_info(get_type_name(), "=== 1단계: Perfect 10연속 ===", UVM_LOW)
        repeat (10) begin
            send_note(lane);
            wait_frames(212);
            press_region(lane_to_region(lane));
            wait_frames(10);
        end

        `uvm_info(get_type_name(), "=== 2단계: Miss (콤보 10 끊김) ===",
                  UVM_LOW)
        send_note(lane);
        wait_frames(240);
        wait_frames(20);

        `uvm_info(get_type_name(), "=== 3단계: Perfect 3연속 ===", UVM_LOW)
        repeat (3) begin
            send_note(lane);
            wait_frames(212);
            press_region(lane_to_region(lane));
            wait_frames(10);
        end

        `uvm_info(get_type_name(), "=== 4단계: Miss (콤보 3 끊김) ===",
                  UVM_LOW)
        send_note(lane);
        wait_frames(240);
        wait_frames(20);

        // [핵심] 마지막에 판정을 더 붙여 보너스 반영분을 관측
        `uvm_info(get_type_name(),
                  "=== 5단계: Perfect 2연속 (보너스 확인) ===",
                  UVM_LOW)
        repeat (2) begin
            send_note(lane);
            wait_frames(212);
            press_region(lane_to_region(lane));
            wait_frames(10);
        end
    endtask
endclass


`endif
