module OV7670_SCCB_Controller(
    input  logic clk, // 100MHz
    input  logic reset,
    output logic scl,
    // output logic scl0,
    // output logic scl1,
    inout  logic sda
);
    // // cam select
    // logic cam;
    // logic scl;
    // assign scl0 = cam ? 1'b1 : scl;
    // assign scl1 = cam ? scl : 1'b1;

    // SCCB Controller Signals
    logic SCCBstart, SCCBrw, SCCBdone, SCCBrp;
    logic [7:0]  RdataBlock;
    logic [15:0] WdataBlock;


    /*** settings ***/
    // QVGA Resolution
    localparam hstart = 168,
               hstop  = 24,
               vstart = 12,
               vstop  = 492,
               /*** do not edit ***/
               HSTART = (hstart>>3)&8'hff,
               HSTOP  = (hstop>>3)&8'hff,
               HREF   = ((hstop&8'h07)<<3)|(hstart&8'h07),
               VSTART = (vstart>>2)&8'hff,
               VSTOP  = (vstop>>2)&8'hff,
               VREF   = ((vstop&8'h03)<<2)|(vstart&8'h03);
    // enable setting (en = 1)
    localparam AutoExposureMode_EN = 1,
               AutoGainMode_EN     = 1;
    // brightness setting
    localparam BRIGHTNESS = 128;
    /*******************/


    localparam IDLE = 0,
               ResetSW = 1,
               ShowColorBar = 2,
               AutoExposureMode = 3,
               SetBrightness = 4,
               AutoGainMode = 5;
    localparam P1 = 1,
               P2 = 2,
               P3 = 3,
               P4 = 4,
               P5 = 5,
               P6 = 6,
               P7 = 7,
               P8 = 8,
               P9 = 9,
               WRITE = 10,
               READ1 = 11,
               READ2 = 12,
               DONE  = 13;

    localparam ROM_DEPTH = 70;
    logic [15:0] ROM[0:ROM_DEPTH-1];
    logic [7:0] ConfigRAM[0:5];

    logic [3:0] state;           // Function
    logic [3:0] Fstate, Rstate;  // state, Return state
    logic [4:0] done;            // Function Complete check
    logic Rdone, temp;           // Rdone (1) READ 1st Phase done
    logic [$clog2(3_000_000)-1:0] cnt_reg;
    logic [$clog2(ROM_DEPTH)-1:0] instrAddr;
    logic [$clog2(6)-1:0] configAddr;

    initial begin
        $readmemh("OV7670setting.mem", ROM);
    end

    always_comb begin
        ConfigRAM = '{HSTART, HSTOP, HREF, VSTART, VSTOP, VREF};
    end
    
    always_ff @(posedge clk, posedge reset) begin
        if(reset) begin
            // cam        <= 1'b0;
            state      <= IDLE;
            Fstate     <= IDLE;
            Rstate     <= IDLE;
            done       <= 5'b0;
            instrAddr  <= 0;
            configAddr <= 0;
            WdataBlock <= 0;
            SCCBstart  <= 1'b0;
            SCCBrw     <= 1'b0;
            SCCBrp     <= 1'b0;
            Rdone      <= 1'b0;
            temp       <= 1'b0;
            cnt_reg    <= 0;
        end else begin
            case(state)
                IDLE: begin
                    // if(!cam && !done) begin
                    //     done       <= 5'd0;
                    //     instrAddr  <= 0;
                    //     configAddr <= 0;
                    //     state      <= ResetSW;
                    // end else if(cam && done) begin
                    //     done       <= 5'd0;
                    //     instrAddr  <= 0;
                    //     configAddr <= 0;
                    //     state      <= ResetSW;
                    // end
                    if(!done) state <= ResetSW;
                    SCCBstart <= 1'b0;
                end
                ResetSW: begin
                    case(Fstate)
                        IDLE: begin // WriteSCCB(REG_COM7, 0x80)
                            if(temp == 1'b0) begin
                                WdataBlock <= ROM[instrAddr];
                                temp       <= 1'b1;
                            end
                                else begin
                                SCCBrw     <= 1'b0;
                                SCCBstart  <= 1'b1;
                                Rstate     <= P1;
                                Fstate     <= WRITE;
                                temp       <= 1'b0;
                                end
                            end
                        P1: begin // delay 30ms
                            cnt_reg <= cnt_reg + 1;
                            if(cnt_reg == 3_000_000-1) begin
                            // if(cnt_reg == 1_000_00-1) begin     // debugging
                                Fstate    <= P2;
                                cnt_reg   <= 0;
                            end
                        end
                        P2: begin // Config(defaults)
                            if(temp == 1'b0) begin
                                WdataBlock <= ROM[instrAddr];
                                temp <= 1'b1;
                            end else begin
                                SCCBrw     <= 1'b0;
                                SCCBstart  <= 1'b1;
                                Fstate     <= WRITE;
                                if(instrAddr == 50) Rstate <= P5;
                                else                Rstate <= P2;
                                temp <= 1'b0;
                            end
                        end
                        P3: begin // delay 1ms
                            cnt_reg <= cnt_reg + 1;
                            if(cnt_reg == 100_000-1) begin
                                if(instrAddr == 44 || instrAddr == 57) Fstate <= P4;
                                else if (instrAddr == 59)              Fstate  <= DONE;
                                else begin
                                    cnt_reg <= 0;
                                    Fstate  <= Rstate;
                                end
                            end
                        end
                        P4: begin // delay 10ms
                            cnt_reg <= cnt_reg + 1;
                            if(cnt_reg == 1_000_000-1) begin
                                if(instrAddr == 57)       Fstate  <= P6;
                                else                      Fstate  <= P2;
                                cnt_reg <= 0;
                            end
                        end
                        P5: begin // SetResolution(QVGA)_SetFrameControl
                            if(temp == 1'b0) begin
                                WdataBlock <= {ROM[instrAddr][15:8], ConfigRAM[configAddr]};
                                temp <= 1'b1;
                            end else begin
                                SCCBrw     <= 1'b0;
                                SCCBstart  <= 1'b1;
                                Rstate     <= P5;
                                Fstate     <= WRITE;
                                temp       <= 1'b0;
                            end
                        end
                        P6: begin // SetColorFormat
                            if(Rdone) begin
                                if(temp == 1'b0) begin
                                    if(instrAddr == 57) WdataBlock[7:0] <= ((WdataBlock[7:0] & 8'b11111010) | 8'h04);
                                    if(instrAddr == 58) WdataBlock[7:0] <= ((WdataBlock[7:0] & 8'b00001111) | 8'h10);
                                    temp <= 1'b1;
                                end else begin
                                    SCCBrw    <= 1'b0;
                                    SCCBstart <= 1'b1;
                                    Rstate    <= P6;
                                    Fstate    <= WRITE;
                                    Rdone     <= 1'b0;
                                    temp      <= 1'b0;
                                end
                            end else begin
                                if(temp == 1'b0) begin
                                    WdataBlock <= ROM[instrAddr];
                                    temp <= 1'b1;
                                end else begin
                                    SCCBrw    <= 1'b0;
                                    SCCBstart <= 1'b1;
                                    SCCBrp    <= 1'b1;
                                    Rstate    <= P6;
                                    Fstate    <= READ1;
                                    temp      <= 1'b0;
                                end
                            end
                        end
                        WRITE: begin
                            SCCBstart <= 1'b0;
                            if(SCCBdone) begin
                                Fstate    <= P3;
                                instrAddr <= instrAddr + 1;
                                if(instrAddr > 50 && instrAddr < 57) configAddr <= configAddr + 1;
                            end
                        end
                        READ1: begin
                            SCCBstart <= 1'b0;
                            if(SCCBdone) begin
                                SCCBstart <= 1'b1;
                                SCCBrw    <= 1'b1;
                                SCCBrp    <= 1'b0;
                                Fstate    <= READ2;
                            end
                        end
                        READ2: begin
                            SCCBstart <= 1'b0;
                            if(SCCBdone) begin
                                SCCBrw  <= 1'b0;
                                SCCBrp  <= 1'b0;
                                temp    <= 1'b1;
                                cnt_reg <= 0;
                            end
                            if(temp) begin
                                WdataBlock[7:0] <= RdataBlock;
                                Fstate          <= Rstate;
                                Rdone           <= 1'b1;
                                temp            <= 1'b0;
                            end
                        end
                        DONE: begin
                            done[0] <= 1'b1;
                            // state   <= IDLE;   // debugging
                        end
                    endcase
                    if(done[0]) begin
                        state  <= AutoExposureMode;
                        Fstate <= P1; // Use READ
                        // Fstate <= P2; // No READ
                    end
                end
                ShowColorBar: begin
                    case(Fstate)
                        DONE: begin
                            done[1] <= 1'b1;
                        end
                    endcase
                    if(done[1]) begin
                        state  <= AutoExposureMode;
                        Fstate <= P1; // Use READ
                        // Fstate <= P2; // No READ
                    end
                end
                AutoExposureMode: begin
                    case(Fstate)
                        P1: begin   // Use READ
                            if(Rdone) begin
                                if(temp == 1'b0) begin
                                    if(AutoExposureMode_EN) WdataBlock[7:0] <= WdataBlock[7:0] | 8'h01;
                                    else                    WdataBlock[7:0] <= WdataBlock[7:0] & 8'hfe;
                                    temp <= 1'b1;
                                end else begin
                                    SCCBrw    <= 1'b0;
                                    SCCBstart <= 1'b1;
                                    Rstate    <= DONE;
                                    Fstate    <= WRITE;
                                    Rdone     <= 1'b0;
                                    temp      <= 1'b0;
                                end
                            end else begin
                                if(temp == 1'b0) begin
                                    WdataBlock <= ROM[instrAddr];
                                    temp <= 1'b1;
                                end else begin
                                    SCCBrw    <= 1'b0;
                                    SCCBstart <= 1'b1;
                                    SCCBrp    <= 1'b1;
                                    Rstate    <= P1;
                                    Fstate    <= READ1;
                                    temp      <= 1'b0;
                                end
                            end
                        end
                        P2: begin  // No READ
                            if(temp == 1'b0) begin
                                if(AutoExposureMode_EN) WdataBlock <= {ROM[instrAddr][15:8], 8'h01};
                                else                    WdataBlock <= {ROM[instrAddr][15:8], 8'hfe};
                                temp <= 1'b1;
                            end else begin
                                SCCBstart <= 1'b1;
                                SCCBrw    <= 1'b0;
                                Fstate    <= WRITE;
                                Rstate    <= DONE;
                                temp      <= 1'b0;
                            end
                        end
                        WRITE: begin
                            SCCBstart <= 1'b0;
                            if(SCCBdone) begin
                                Fstate    <= Rstate;
                                instrAddr <= instrAddr + 1;
                            end
                        end
                        READ1: begin
                            SCCBstart <= 1'b0;
                            if(SCCBdone) begin
                                SCCBstart <= 1'b1;
                                SCCBrw    <= 1'b1;
                                SCCBrp    <= 1'b0;
                                Fstate    <= READ2;
                            end
                        end
                        READ2: begin
                            SCCBstart <= 1'b0;
                            if(SCCBdone) begin
                                SCCBrw  <= 1'b0;
                                SCCBrp  <= 1'b0;
                                temp    <= 1'b1;
                                cnt_reg <= 0;
                            end
                            if(temp) begin
                                WdataBlock[7:0] <= RdataBlock;
                                Fstate          <= Rstate;
                                Rdone           <= 1'b1;
                                temp            <= 1'b0;
                            end
                        end
                        DONE: begin
                            done[2] <= 1'b1;
                        end
                    endcase
                    if(done[2]) begin
                        state  <= SetBrightness;
                        Fstate <= P1;
                    end
                end
                SetBrightness: begin
                    case(Fstate)
                        P1: begin
                            if(temp == 1'b0) begin
                                if(BRIGHTNESS >= 8'd127) WdataBlock <= {ROM[instrAddr][15:8], 8'(BRIGHTNESS-8'd127)};
                                else                     WdataBlock <= {ROM[instrAddr][15:8], 8'(8'd255-BRIGHTNESS)};
                                temp <= 1'b1;
                            end else begin
                                SCCBrw     <= 1'b0;
                                SCCBstart  <= 1'b1;
                                Fstate     <= WRITE;
                                temp       <= 1'b0;
                            end
                        end
                        WRITE: begin
                            SCCBstart <= 1'b0;
                            if(SCCBdone) begin
                                Fstate    <= DONE;
                                done[3]   <= 1'b1;
                                instrAddr <= instrAddr + 1;
                            end
                        end
                        DONE: begin
                            done[3] <= 1'b1;
                        end
                    endcase
                    if(done[3]) begin
                        state  <= AutoGainMode;
                        Fstate <= P1; // Use READ
                        // Fstate <= P2; // No READ
                    end
                end
                AutoGainMode: begin
                    case(Fstate)
                        P1: begin   // Use READ
                            if(Rdone) begin
                                if(temp == 1'b0) begin
                                    if(AutoGainMode_EN) WdataBlock[7:0] <= WdataBlock[7:0] | 8'h04;
                                    else                WdataBlock[7:0] <= WdataBlock[7:0] & 8'hfb;
                                    temp <= 1'b1;
                                end else begin
                                    SCCBrw    <= 1'b0;
                                    SCCBstart <= 1'b1;
                                    Fstate    <= WRITE;
                                    Rstate    <= DONE;
                                    Rdone     <= 1'b0;
                                    temp      <= 1'b0;
                                end
                            end else begin
                                if(temp == 1'b0) begin
                                    WdataBlock <= ROM[instrAddr];
                                    temp <= 1'b1;
                                end else begin
                                    SCCBrw    <= 1'b0;
                                    SCCBstart <= 1'b1;
                                    SCCBrp    <= 1'b1;
                                    Rstate    <= P1;
                                    Fstate    <= READ1;
                                    temp      <= 1'b0;
                                end
                            end
                        end
                        P2: begin  // No READ
                            if(temp == 1'b0) begin
                                if(AutoExposureMode_EN) WdataBlock <= {ROM[instrAddr][15:8], 8'h04};
                                else                    WdataBlock <= {ROM[instrAddr][15:8], 8'hfb};
                                temp <= 1'b1;
                            end else begin
                                SCCBstart <= 1'b1;
                                SCCBrw    <= 1'b0;
                                Fstate    <= WRITE;
                                Rstate    <= DONE;
                                temp      <= 1'b0;
                            end
                        end
                        WRITE: begin
                            SCCBstart <= 1'b0;
                            if(SCCBdone) begin
                                if(Rstate == DONE) done[4] <= 1'b1;
                                Fstate    <= Rstate;
                                instrAddr <= instrAddr + 1;
                            end
                        end
                        READ1: begin
                            SCCBstart <= 1'b0;
                            if(SCCBdone) begin
                                SCCBstart <= 1'b1;
                                SCCBrw    <= 1'b1;
                                SCCBrp    <= 1'b0;
                                Fstate    <= READ2;
                            end
                        end
                        READ2: begin
                            SCCBstart <= 1'b0;
                            if(SCCBdone) begin
                                SCCBrw  <= 1'b0;
                                SCCBrp  <= 1'b0;
                                temp    <= 1'b1;
                                cnt_reg <= 0;
                            end
                            if(temp) begin
                                WdataBlock[7:0] <= RdataBlock;
                                Fstate          <= Rstate;
                                Rdone           <= 1'b1;
                                temp            <= 1'b0;
                            end
                        end
                        DONE: begin
                            done[4] <= 1'b1;
                        end
                    endcase
                    if(done[4]) begin
                        // if(!cam)     cam <= 1'b1;
                        // else if(cam) cam <= 1'b0;
                        state  <= IDLE;
                        Fstate <= IDLE;
                    end
                end
            endcase
        end
    end

    SCCB_sender U_SCCB_SENDER(
        .clk(clk),
        .reset(reset),
        .WR(SCCBrw),
        .start(SCCBstart),
        .tx_data(WdataBlock),
        .SCCBdone(SCCBdone),
        .SCCBrp(SCCBrp),
        .scl(scl),
        .sda(sda),
        .rx_data(RdataBlock)
    );
endmodule