module RegionDetector(
    input  logic        clk,
    input  logic        vsync,
    input  logic        reset,
    input  logic [9:0]  x_pixel_VGA,
    input  logic [9:0]  y_pixel_VGA,
    input  logic [15:0] frame_data,
    output logic [3:0]  region
);

    logic vsync_reg;

    localparam TARGET_PX = 50,
               X_PX      = 320,
               Y_PX      = 240,
               TOT_PX    = X_PX * Y_PX;

    logic [8:0] x_pixel, y_pixel;
    assign x_pixel = x_pixel_VGA >> 1;
    assign y_pixel = y_pixel_VGA >> 1;
    logic [$clog2(TOT_PX>>2)-1:0] pxl_cnt0, pxl_cnt1, pxl_cnt2, pxl_cnt3;

    // Color Detect
    logic [3:0]  r_check, g_check, b_check;
    logic isRED, isBLUE;
    assign r_check = frame_data[15:12];   // RGB565 -> RGB444
    assign g_check = frame_data[10:7];    // ignore smaller bit
    assign b_check = frame_data[4:1];
    assign isRED  = (r_check > 4'b0100) &&
                    (g_check < 4'b0111) &&
                    (b_check < 4'b0111) &&
                    (r_check > 4'(g_check + 4'b0010)) && (r_check > 4'(b_check + 4'b0010));
    // assign isBLUE = (r_check < 4'b0111) &&
    //                 (g_check < 4'b0111) &&
    //                 (b_check > 4'b0100) &&
    //                 (b_check > 4'(r_check + 4'b0010)) && (b_check > 4'(g_check + 4'b0010));
                   
    // FSM
    localparam IDLE = 0, SCAN = 1, DECISION = 2;
    logic [1:0] state;

    always_ff @(posedge clk, posedge reset) begin
        if(reset) begin
            // REGION count
            pxl_cnt0       <= 0;
            pxl_cnt1       <= 0;
            pxl_cnt2       <= 0;
            pxl_cnt3       <= 0;
            //output
            region         <= 4'd0;
            // FSM
            state          <= 2'd0;
            vsync_reg      <= 1'b0;
        end else begin
            if(vsync) vsync_reg <= 1'b1;
            if(vsync_reg && (x_pixel == 0 && y_pixel == 0)) begin
                state    <= SCAN;
                pxl_cnt0 <= 0;
                pxl_cnt1 <= 0;
                pxl_cnt2 <= 0;
                pxl_cnt3 <= 0;
            end

            case(state)
                SCAN: begin
                    if((x_pixel < X_PX) && (y_pixel < Y_PX)) begin
                        // count RED pixel each region
                        if(isRED) begin
                            if(x_pixel >= 0 && x_pixel < 70) begin
                                pxl_cnt0 <= pxl_cnt0 + 1;
                            end else if(x_pixel >=  90 && x_pixel < 150) begin
                                pxl_cnt1 <= pxl_cnt1 + 1;
                            end else if(x_pixel >= 170 && x_pixel < 230) begin
                                pxl_cnt2 <= pxl_cnt2 + 1;
                            end else if(x_pixel >= 250 && x_pixel < 320) begin
                                pxl_cnt3 <= pxl_cnt3 + 1;
                            end
                        end
                    end
                    if((x_pixel == X_PX-1) && (y_pixel == Y_PX-1)) begin
                        state       <= DECISION;
                    end
                end
                DECISION: begin
                    // [수정] 히스테리시스(Hysteresis) 적용
                    // 카메라 노이즈로 인한 인식 끊김(Flickering)을 방지합니다.
                    
                    if (pxl_cnt0 > 50) region[0] <= 1'b1;
                    else if (pxl_cnt0 < 25) region[0] <= 1'b0;

                    if (pxl_cnt1 > 50) region[1] <= 1'b1;
                    else if (pxl_cnt1 < 25) region[1] <= 1'b0;

                    if (pxl_cnt2 > 50) region[2] <= 1'b1;
                    else if (pxl_cnt2 < 25) region[2] <= 1'b0;

                    if (pxl_cnt3 > 50) region[3] <= 1'b1;
                    else if (pxl_cnt3 < 25) region[3] <= 1'b0;

                    state <= IDLE;
                end
            endcase
        end
    end
endmodule