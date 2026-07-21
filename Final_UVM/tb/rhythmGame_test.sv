`ifndef TEST_SV
`define TEST_SV

`include "uvm_macros.svh"
import uvm_pkg::*;

`include "rhythmGame_env.sv"
`include "rhythmGame_sequence.sv"

class rhythmGame_base_test extends uvm_test;
    `uvm_component_utils(rhythmGame_base_test)

    rhythmGame_env env;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction  //new()

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = rhythmGame_env::type_id::create("env", this);
    endfunction

    virtual function void end_of_elaboration_phase(uvm_phase phase);
        `uvm_info(get_type_name(), "===== UVM 계층 구조 =====", UVM_MEDIUM)
        uvm_top.print_topology();
    endfunction

    virtual task run_phase(uvm_phase phase);

    endtask  //run_phase

endclass  //component 

// =========================================================================
// 1. [Perfect 검증 테스트 클래스]
// =========================================================================
class rhythmGame_perfect_test extends rhythmGame_base_test;
    `uvm_component_utils(rhythmGame_perfect_test)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction  //new()

    // Run Phase : 실제 검증 시나리오(시퀀스) 구동 
    virtual task run_phase(uvm_phase phase);
        Perfect_seq seq;
        seq = Perfect_seq::type_id::create("seq");

        phase.raise_objection(this);
        repeat (10) begin
            `uvm_info(get_type_name(),
                      "Perfect 테스트 시나리오 구동 시작", UVM_LOW)
            // seq.num_loop = 10;
            seq.start(env.agt.sqr);
            `uvm_info(get_type_name(),
                      "Perfect 테스트 시나리오 구동 종료", UVM_LOW)
        end
        phase.drop_objection(this);
    endtask  //run_phase

endclass  //component  

// =========================================================================
// 2. [Good 검증 테스트 클래스]
// =========================================================================
class rhythmGame_good_test extends rhythmGame_base_test;
    `uvm_component_utils(rhythmGame_good_test)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction  //new()

    // Run Phase : 실제 검증 시나리오(시퀀스) 구동 
    virtual task run_phase(uvm_phase phase);
        Good_seq seq;
        seq = Good_seq::type_id::create("seq");

        phase.raise_objection(this);
        repeat (10) begin
            `uvm_info(get_type_name(),
                      "Good 테스트 시나리오 구동 시작", UVM_LOW)
            // seq.num_loop = 10;
            seq.start(env.agt.sqr);
            `uvm_info(get_type_name(),
                      "Good 테스트 시나리오 구동 종료", UVM_LOW)
        end
        phase.drop_objection(this);
    endtask  //run_phase

endclass  //component  


// =========================================================================
// 3. [Miss 검증 테스트 클래스]
// =========================================================================
class rhythmGame_miss_test extends rhythmGame_base_test;
    `uvm_component_utils(rhythmGame_miss_test)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction  //new()

    // Run Phase : 실제 검증 시나리오(시퀀스) 구동 
    virtual task run_phase(uvm_phase phase);
        Miss_seq seq;
        seq = Miss_seq::type_id::create("seq");

        phase.raise_objection(this);
        repeat (10) begin
            `uvm_info(get_type_name(),
                      "Miss 테스트 시나리오 구동 시작", UVM_LOW)
            // seq.num_loop = 10;
            seq.start(env.agt.sqr);
            `uvm_info(get_type_name(),
                      "Miss 테스트 시나리오 구동 종료", UVM_LOW)
        end
        phase.drop_objection(this);
    endtask  //run_phase

endclass  //component  


// =========================================================================
// 4. [조기 입력 무시 검증 테스트 클래스]
// =========================================================================
class rhythmGame_ignore_early_press_test extends rhythmGame_base_test;
    `uvm_component_utils(rhythmGame_ignore_early_press_test)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction  //new()

    virtual task run_phase(uvm_phase phase);
        IgnoreEarlyPress_seq seq;
        seq = IgnoreEarlyPress_seq::type_id::create("seq");

        phase.raise_objection(this);
        repeat (10) begin
            `uvm_info(get_type_name(),
                      "조기 입력 무시 검증 테스트 시나리오 구동 시작",
                      UVM_LOW)
            // seq.num_loop = 10;
            seq.start(env.agt.sqr);
            `uvm_info(get_type_name(),
                      "조기 입력 무시 검증 테스트 시나리오 구동 종료",
                      UVM_LOW)
        end
        phase.drop_objection(this);
    endtask  //run_phase

endclass  //component 

// =========================================================================
// 5. [종합 검증 테스트 클래스]
// =========================================================================
class rhythmGame_all_test extends rhythmGame_base_test;
    `uvm_component_utils(rhythmGame_all_test)
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction  //new()
    virtual task run_phase(uvm_phase phase);
        // 4가지 시퀀스 선언
        Perfect_seq          seq_perfect;
        Good_seq             seq_good;
        Miss_seq             seq_miss;
        IgnoreEarlyPress_seq seq_ignore;
        phase.raise_objection(this);
        repeat (10) begin
            // ----------------------------------------------------
            // 1. Perfect 시나리오 실행
            // ----------------------------------------------------
            `uvm_info(get_type_name(),
                      "=== [1/4] Perfect 시나리오 시작 ===", UVM_LOW)
            seq_perfect = Perfect_seq::type_id::create("seq_perfect");
            seq_perfect.start(env.agt.sqr);
            #100;  // 시나리오 간의 물리적 간격(딜레이) 제공
            // ----------------------------------------------------
            // 2. Good 시나리오 실행
            // ----------------------------------------------------
            `uvm_info(get_type_name(), "=== [2/4] Good 시나리오 시작 ===",
                      UVM_LOW)
            seq_good = Good_seq::type_id::create("seq_good");
            seq_good.start(env.agt.sqr);
            #100;
            // ----------------------------------------------------
            // 3. Miss 시나리오 실행
            // ----------------------------------------------------
            `uvm_info(get_type_name(), "=== [3/4] Miss 시나리오 시작 ===",
                      UVM_LOW)
            seq_miss = Miss_seq::type_id::create("seq_miss");
            seq_miss.start(env.agt.sqr);
            #100;
            // ----------------------------------------------------
            // 4. 조기 입력 무시 시나리오 실행
            // ----------------------------------------------------
            `uvm_info(get_type_name(),
                      "=== [4/4] 조기 입력 무시 시나리오 시작 ===",
                      UVM_LOW)
            seq_ignore = IgnoreEarlyPress_seq::type_id::create("seq_ignore");
            seq_ignore.start(env.agt.sqr);
            #100;
        end
        phase.drop_objection(
            this);  // 모든 시나리오 종료 후 락 해제
    endtask  //run_phase
endclass  //component


// =========================================================================
// 5. [랜덤 검증 테스트]
// =========================================================================
class rhythmGame_random_test extends rhythmGame_base_test;
    `uvm_component_utils(rhythmGame_random_test)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual task run_phase(uvm_phase phase);
        Random_seq seq;

        phase.raise_objection(this);
        `uvm_info(get_type_name(), "Random 테스트 시작", UVM_LOW)

        repeat (40) begin
            seq = Random_seq::type_id::create("seq");   // 매번 새로 생성
            if (!seq.randomize())
                `uvm_fatal(get_type_name(), "randomize 실패!")
            seq.start(env.agt.sqr);
        end

        `uvm_info(get_type_name(), "Random 테스트 종료", UVM_LOW)
        phase.drop_objection(this);
    endtask
endclass

// =========================================================================
// 6. [콤보 보너스 증거 수집 테스트]
// =========================================================================
class rhythmGame_combobonus_test extends rhythmGame_base_test;
    `uvm_component_utils(rhythmGame_combobonus_test)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual task run_phase(uvm_phase phase);
        ComboBonus_seq seq;
        seq = ComboBonus_seq::type_id::create("seq");

        phase.raise_objection(this);
        seq.start(env.agt.sqr);
        phase.drop_objection(this);
    endtask
endclass

// =========================================================================
// [커버리지 클로저] cross 20개 bin 전수 실행
// =========================================================================
class rhythmGame_closure_test extends rhythmGame_base_test;
    `uvm_component_utils(rhythmGame_closure_test)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual task run_phase(uvm_phase phase);
        Random_seq seq;
        bit [3:0] L[4]  = '{4'b0001, 4'b0010, 4'b0100, 4'b1000};
        int       lo[3] = '{193, 203, 233};   // Good / Perfect / Miss 구간 시작
        int       hi[3] = '{202, 222, 236};   // 각 구간 끝

        phase.raise_objection(this);

        // (1) 노트 레인 4 x 입력 레인 4 x 타이밍 구간 3 = 48조합
        foreach (L[i]) foreach (L[j]) foreach (lo[k]) begin
            seq = Random_seq::type_id::create("seq");
            seq.c_wrong.constraint_mode(0);
            if (!seq.randomize() with {
                    lane       == L[i];
                    press_lane == L[j];
                    do_press   == 1;
                    wait_cnt inside {[lo[k] : hi[k]]};
                })
                `uvm_fatal(get_type_name(), "randomize 실패")
            seq.start(env.agt.sqr);
        end

        // (2) 미입력 4조합  ← 기존 그대로
        foreach (L[i]) begin
            seq = Random_seq::type_id::create("seq");
            seq.c_wrong.constraint_mode(0);
            if (!seq.randomize() with {
                    lane     == L[i];
                    do_press == 0;
                })
                `uvm_fatal(get_type_name(), "randomize 실패")
            seq.start(env.agt.sqr);
        end

        phase.drop_objection(this);
    endtask
endclass

// =========================================================================
// [1단계 재현] 입력 레인을 노트 레인에 고정 — 오타가 발생할 수 없는 자극
// =========================================================================
class rhythmGame_random_stage1_test extends rhythmGame_base_test;
    `uvm_component_utils(rhythmGame_random_stage1_test)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual task run_phase(uvm_phase phase);
        Random_seq seq;

        phase.raise_objection(this);

        repeat (40) begin
            seq = Random_seq::type_id::create("seq");
            seq.c_wrong.constraint_mode(0);          // 오타 확률 제약 해제
            if (!seq.randomize() with {
                    press_lane == lane;              // 항상 정타 = 1단계 조건
                })
                `uvm_fatal(get_type_name(), "randomize 실패")
            seq.start(env.agt.sqr);
        end

        phase.drop_objection(this);
    endtask
endclass

`endif
