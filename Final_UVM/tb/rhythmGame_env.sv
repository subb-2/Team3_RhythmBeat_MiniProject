`ifndef ENVIRONMENT_SV
`define ENVIRONMENT_SV

`include "uvm_macros.svh"
import uvm_pkg::*;
`include "rhythmGame_agent.sv"
`include "rhythmGame_scoreboard.sv"
`include "rhythmGame_coverage.sv" 

class rhythmGame_env extends uvm_env;
    `uvm_component_utils(rhythmGame_env)
    rhythmGame_agent agt;
    rhythmGame_scoreboard scb;
    rhythmGame_coverage cov;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction  //new()

    //scb, cov 경우에는 report 까지 하는 경우도 있음
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        agt = rhythmGame_agent::type_id::create("agt", this);
        scb = rhythmGame_scoreboard::type_id::create("scb", this);
        cov = rhythmGame_coverage::type_id::create("cov", this);
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        agt.mon.ap.connect(scb.ap_imp);
        agt.mon.ap.connect(cov.analysis_export);
    endfunction

endclass  //component 

`endif
