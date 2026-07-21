`ifndef DRIVER_SV
`define DRIVER_SV

`include "uvm_macros.svh"
import uvm_pkg::*;

//rhythmGame_seq_item 부르기 위함 
`include "rhythmGame_seq_item.sv"

class rhythmGame_driver extends uvm_driver #(rhythmGame_seq_item);
    `uvm_component_utils(rhythmGame_driver)

    virtual rhythmGame_if vif;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction  //new()

    //scb, cov 경우에는 report 까지 하는 경우도 있음
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual rhythmGame_if)::get(
                this, "", "vif", vif
            )) begin
            `uvm_fatal(get_type_name(),
                       "[driver] Virtual Interface 'vif'를 config_db에서 가져오지 못했습니다!");
        end
    endfunction

    // Run Phase: 시뮬레이션 중 무한 루프를 돌며 시퀀스 아이템을 RTL에 인가
    virtual task run_phase(uvm_phase phase);
        rhythmGame_init();
        //보통 처음에 리셋 해줌
        //그리고 다시 1이 될 때를 기다림
        //리셋 해제되면 다시 들어가겠다는 의미 
        wait (vif.reset == 0);
        `uvm_info(get_type_name(),
                  "리셋 해제 확인, 트랜젝션 대기 중...",
                  UVM_MEDIUM)

        forever begin
            rhythmGame_seq_item req;
            seq_item_port.get_next_item(req);
            drive_rhythmGame(req);
            seq_item_port.item_done();
        end
    endtask  //run_phase

    task rhythmGame_init();
        vif.drv_cb.note_start <= 1'b0;
        vif.drv_cb.lane_data  <= 4'b0000;
        vif.drv_cb.region     <= 4'b0000;
        vif.drv_cb.v_sync     <= 1'b0;
        vif.drv_cb.main_state <= 3'b000;
    endtask  //rhythmGame_init

    task drive_rhythmGame(rhythmGame_seq_item req);
        @(vif.drv_cb);
        vif.drv_cb.note_start <= req.note_start;
        vif.drv_cb.lane_data  <= req.lane_data;
        vif.drv_cb.region     <= req.region;
        vif.drv_cb.v_sync     <= req.v_sync;
        vif.drv_cb.main_state <= req.main_state;
        `uvm_info(get_type_name(), $sformatf("drv rhythmGame 구동 완료: %s",
                                             req.convert2string()), UVM_MEDIUM)
        // if (req.note_start || req.region != 4'b0000) begin
        //     `uvm_info(get_type_name(),
        //               $sformatf("drv: %s", req.convert2string()), UVM_MEDIUM)
        // end
    endtask

endclass  //component 

`endif
