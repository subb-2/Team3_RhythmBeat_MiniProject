`ifndef MONITOR_SV
`define MONITOR_SV

`include "uvm_macros.svh"
import uvm_pkg::*;
`include "rhythmGame_seq_item.sv"

//템플릿 
class rhythmGame_monitor extends uvm_monitor;
    `uvm_component_utils(rhythmGame_monitor)

    //통신선 필요
    uvm_analysis_port #(rhythmGame_seq_item) ap;
    virtual rhythmGame_if vif;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction  //new()

    //scb, cov 경우에는 report 까지 하는 경우도 있음
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        ap = new("ap", this);
        if (!uvm_config_db#(virtual rhythmGame_if)::get(
                this, "", "vif", vif
            )) begin
            `uvm_fatal(get_type_name(),
                       "[monitor] vif를 가져오지 못했습니다!");
        end
    endfunction

    virtual task run_phase(uvm_phase phase);
        // 리셋 해제될 때까지 모니터링 대기 
        wait (vif.reset == 0);
        `uvm_info(get_type_name(), "rhythmGame 모니터링 시작 ...",
                  UVM_MEDIUM)

        forever begin
            rhythmGame_transaction();
        end
    endtask  //run_phase

    task rhythmGame_transaction();
        //tr 받기
        rhythmGame_seq_item item;
        string s;

        @(vif.mon_cb);

        if (vif.mon_cb.v_sync || vif.mon_cb.note_start || vif.mon_cb.perfect || vif.mon_cb.good || vif.mon_cb.miss) begin
            item            = rhythmGame_seq_item::type_id::create("mon_item");

            // 자극 신호와 판정 펄스는 지금 시점 값으로
            item.lane_data  = vif.mon_cb.lane_data;
            item.region     = vif.mon_cb.region;
            item.note_start = vif.mon_cb.note_start;
            item.v_sync     = vif.mon_cb.v_sync;
            item.perfect    = vif.mon_cb.perfect;
            item.good       = vif.mon_cb.good;
            item.miss       = vif.mon_cb.miss;
            item.fever      = vif.mon_cb.fever;

            item.pos[0]     = vif.mon_cb.o_pos0;
            item.lcnt[0]    = vif.mon_cb.o_lcnt0;
            item.pos[1]     = vif.mon_cb.o_pos1;
            item.lcnt[1]    = vif.mon_cb.o_lcnt1;
            item.pos[2]     = vif.mon_cb.o_pos2;
            item.lcnt[2]    = vif.mon_cb.o_lcnt2;
            item.pos[3]     = vif.mon_cb.o_pos3;
            item.lcnt[3]    = vif.mon_cb.o_lcnt3;
            item.pos[4]     = vif.mon_cb.o_pos4;
            item.lcnt[4]    = vif.mon_cb.o_lcnt4;
            item.pos[5]     = vif.mon_cb.o_pos5;
            item.lcnt[5]    = vif.mon_cb.o_lcnt5;
            item.pos[6]     = vif.mon_cb.o_pos6;
            item.lcnt[6]    = vif.mon_cb.o_lcnt6;
            item.pos[7]     = vif.mon_cb.o_pos7;
            item.lcnt[7]    = vif.mon_cb.o_lcnt7;
            item.pos[8]     = vif.mon_cb.o_pos8;
            item.lcnt[8]    = vif.mon_cb.o_lcnt8;
            item.pos[9]     = vif.mon_cb.o_pos9;
            item.lcnt[9]    = vif.mon_cb.o_lcnt9;
            item.pos[10]    = vif.mon_cb.o_pos10;
            item.lcnt[10]   = vif.mon_cb.o_lcnt10;
            item.pos[11]    = vif.mon_cb.o_pos11;
            item.lcnt[11]   = vif.mon_cb.o_lcnt11;
            item.pos[12]    = vif.mon_cb.o_pos12;
            item.lcnt[12]   = vif.mon_cb.o_lcnt12;
            item.pos[13]    = vif.mon_cb.o_pos13;
            item.lcnt[13]   = vif.mon_cb.o_lcnt13;
            item.pos[14]    = vif.mon_cb.o_pos14;
            item.lcnt[14]   = vif.mon_cb.o_lcnt14;
            item.pos[15]    = vif.mon_cb.o_pos15;
            item.lcnt[15]   = vif.mon_cb.o_lcnt15;

            // 결과 레지스터는 한 클럭 뒤 값으로
            if (vif.mon_cb.perfect || vif.mon_cb.good || vif.mon_cb.miss) begin
                @(vif.mon_cb);
                item.score = vif.mon_cb.score;
                item.combo = vif.mon_cb.combo;
            end else begin
                item.score = vif.mon_cb.score;
                item.combo = vif.mon_cb.combo;
            end

            // `uvm_info(get_type_name(),
            //           $sformatf("mon item: %s", item.convert2string()), UVM_MEDIUM)
            // 디버깅 로그 출력
            // `uvm_info(
            //     get_type_name(),
            //     $sformatf(
            //         "Mon 수집 완료: lane_data=%b region=%b | perf=%b good=%b miss=%b score=%0d",
            //         item.lane_data, item.region, item.perfect, item.good,
            //         item.miss, item.score), UVM_HIGH)

            s = "";
            for (int i = 0; i < 16; i++) begin
                if (item.lcnt[i] != 0)
                    s = {
                        s,
                        $sformatf(
                            "[%0d]pos=%b lcnt=%0d ",
                            i,
                            item.pos[i],
                            item.lcnt[i]
                        )
                    };
            end

            `uvm_info(get_type_name(),
                      $sformatf("Mon 수집 완료 : %s| region=%b perf=%b score=%0d", s,
                                item.region, item.perfect, item.score),
                      UVM_HIGH)

            //값 전송 
            ap.write(item);
        end
    endtask  //rhythmGame_transaction

endclass  //component 

`endif
