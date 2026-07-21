`ifndef AGENT_SV
`define AGENT_SV

`include "uvm_macros.svh"
import uvm_pkg::*;
`include "rhythmGame_seq_item.sv"
`include "rhythmGame_driver.sv" 
`include "rhythmGame_monitor.sv"

typedef uvm_sequencer#(rhythmGame_seq_item) rhythmGame_sequencer;

class rhythmGame_agent extends uvm_agent;
    `uvm_component_utils(rhythmGame_agent)

    rhythmGame_driver drv;
    rhythmGame_monitor mon;
    rhythmGame_sequencer sqr;
    //uvm_sequencer #(rhythmGame_seq_item) sqr;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        drv = rhythmGame_driver::type_id::create("drv", this);
        mon = rhythmGame_monitor::type_id::create("mon", this);
        sqr = rhythmGame_sequencer::type_id::create("sqr", this);
    endfunction  //new()

    //scb, cov 경우에는 report 까지 하는 경우도 있음
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        drv.seq_item_port.connect(sqr.seq_item_export);
    endfunction

endclass  //component 

// `endif

// `ifndef AGENT_SV
// `define AGENT_SV

// `include "uvm_macros.svh"
// import uvm_pkg::*;

// `include "rhythmGame_seq_item.sv"
// `include "rhythmGame_driver.sv"     // <-- include 추가
// `include "rhythmGame_monitor.sv"    // <-- include 추가

// typedef uvm_sequencer#(rhythmGame_seq_item) rhythmGame_sequencer;

// class rhythmGame_agent extends uvm_agent; // <-- 클래스명 rhythmGame_agent로 수정
//     `uvm_component_utils(rhythmGame_agent)

//     rhythmGame_driver drv;
//     rhythmGame_monitor mon;
//     rhythmGame_sequencer sqr;

//     // 생성자에서는 부모 클래스 호출만 하고, 컴포넌트 생성은 하지 않습니다.
//     function new(string name, uvm_component parent);
//         super.new(name, parent);
//     endfunction  //new()

//     // [1단계] Build Phase: 하위 컴포넌트들(drv, mon, sqr)을 생성(build)합니다.
//     virtual function void build_phase(uvm_phase phase);
//         super.build_phase(phase);
        
//         mon = rhythmGame_monitor::type_id::create("mon", this);

//         // get_is_active()는 이 에이전트가 신호를 주는 주체(Active)일 때만 드라이버와 시퀀서를 생성합니다.
//         if (get_is_active() == UVM_ACTIVE) begin
//             drv = rhythmGame_driver::type_id::create("drv", this);
//             sqr = rhythmGame_sequencer::type_id::create("sqr", this);
//         end
//     endfunction

//     // [2단계] Connect Phase: 컴포넌트 생성이 끝난 후, 포트들을 연결(connect)합니다.
//     virtual function void connect_phase(uvm_phase phase);
//         super.connect_phase(phase);

//         // Active 모드일 때만 드라이버와 시퀀서 포트를 연결해 줍니다.
//         if (get_is_active() == UVM_ACTIVE) begin
//             drv.seq_item_port.connect(sqr.seq_item_export);
//         end
//     endfunction

// endclass  //component 

`endif
