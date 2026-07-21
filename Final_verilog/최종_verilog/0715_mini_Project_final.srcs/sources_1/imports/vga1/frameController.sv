module frameController(
    input  logic [3:0]  note_x0,
    input  logic [3:0]  note_x1,
    input  logic [3:0]  note_x2,
    input  logic [3:0]  note_x3,
    input  logic [9:0]  note_x4,
    input  logic [9:0]  note_x5,
    input  logic [9:0]  note_x6,
    input  logic [9:0]  note_x7,
    input  logic [9:0]  note_x8,
    input  logic [9:0]  note_x9,
    input  logic [9:0]  note_x10,
    input  logic [9:0]  note_x11,
    input  logic [9:0]  note_x12,
    input  logic [9:0]  note_x13,
    input  logic [9:0]  note_x14,
    input  logic [9:0]  note_x15,
    input  logic [9:0]  note_y0,
    input  logic [9:0]  note_y1,
    input  logic [9:0]  note_y2,
    input  logic [9:0]  note_y3,
    input  logic [9:0]  note_y4,
    input  logic [9:0]  note_y5,
    input  logic [9:0]  note_y6,
    input  logic [9:0]  note_y7,
    input  logic [9:0]  note_y8,
    input  logic [9:0]  note_y9,
    input  logic [9:0]  note_y10,
    input  logic [9:0]  note_y11,
    input  logic [9:0]  note_y12,
    input  logic [9:0]  note_y13,
    input  logic [9:0]  note_y14,
    input  logic [9:0]  note_y15,
    input  logic [9:0]  x_pixel_VGA,
    input  logic [9:0]  y_pixel_VGA,
    input  logic [3:0]  region,
    input  logic [15:0] imgPxlData,
    output logic [$clog2(320*240)-1:0] imgPxlAddr,
    output logic [11:0] RGBport
);

    logic [11:0] RGB_region;
    logic [11:0] RGB_note;
    logic [11:0] RGB_game;
    logic done_cap;

    // frame upscale -VGA: 640 * 320
    logic [9:0] x_pixel, y_pixel;
    assign x_pixel = x_pixel_VGA >> 1;
    assign y_pixel = y_pixel_VGA >> 1;
    // assign imgPxlAddr = 320*(y_pixel) + (319-(x_pixel));
    assign imgPxlAddr = 320*y_pixel + x_pixel;


    Filter_Region U_Filter_REG(
        .x_pixel(x_pixel),
        .y_pixel(y_pixel),
        .region(region),
        .imgPxlData(imgPxlData),
        .imgPxlAddr(imgPxlAddr),
        .o_rgb(RGB_region)
    );
    Filter_NOTE U_Filter_NOTE(
        .note_x0(note_x0),
        .note_x1(note_x1),
        .note_x2(note_x2),
        .note_x3(note_x3),
        .note_x4(note_x4),
        .note_x5(note_x5),
        .note_x6(note_x6),
        .note_x7(note_x7),
        .note_x8(note_x8),
        .note_x9(note_x9),
        .note_x10(note_x10),
        .note_x11(note_x11),
        .note_x12(note_x12),
        .note_x13(note_x13),
        .note_x14(note_x14),
        .note_x15(note_x15),
        .note_y0(note_y0),
        .note_y1(note_y1),
        .note_y2(note_y2),
        .note_y3(note_y3),
        .note_y4(note_y4),
        .note_y5(note_y5),
        .note_y6(note_y6),
        .note_y7(note_y7),
        .note_y8(note_y8),
        .note_y9(note_y9),
        .note_y10(note_y10),
        .note_y11(note_y11),
        .note_y12(note_y12),
        .note_y13(note_y13),
        .note_y14(note_y14),
        .note_y15(note_y15),
        .x_pixel(x_pixel),
        .y_pixel(y_pixel),
        .i_rgb(RGB_region),
        .o_rgb(RGB_note)
    );
    Filter_GAME U_Filter_GAME(
        .x_pixel(x_pixel),
        .y_pixel(y_pixel),
        .i_rgb(RGB_note),
        .o_rgb(RGBport)
    );
endmodule


module mux_2x1#(
    parameter BIT_DEPTH = 16
) (
    input  logic                 sel,
    input  logic [BIT_DEPTH-1:0] in0,
    input  logic [BIT_DEPTH-1:0] in1,
    output logic [BIT_DEPTH-1:0] out
);
    assign out = sel? in0 : in1;
endmodule


module Filter_Region(
    input  logic [9:0]  x_pixel,
    input  logic [9:0]  y_pixel,
    input  logic [3:0]  region,
    input  logic [15:0] imgPxlData,
    output logic [$clog2(320*240)-1:0] imgPxlAddr,
    output logic [11:0] o_rgb
);
    // frame upscale -VGA: 640 * 320
    logic vgaArea;
    assign vgaArea = (x_pixel < 640) && (y_pixel < 480);

    always_comb begin
        if(vgaArea) begin
            case(region)
                4'b0001:      if((x_pixel >=   0) && (x_pixel <  80)) o_rgb = {{1'b1, imgPxlData[15:11]}, {1'b1, imgPxlData[10:8]}, {1'b1, imgPxlData[4:2]}};
                        else                                          o_rgb = {imgPxlData[15:12], imgPxlData[10:7], imgPxlData[4:1]};
                4'b0010:      if((x_pixel >=  80) && (x_pixel < 160)) o_rgb = {{1'b1, imgPxlData[15:11]}, {1'b1, imgPxlData[10:8]}, {1'b1, imgPxlData[4:2]}};
                        else                                          o_rgb = {imgPxlData[15:12], imgPxlData[10:7], imgPxlData[4:1]};
                4'b0100:      if((x_pixel >= 160) && (x_pixel < 240)) o_rgb = {{1'b1, imgPxlData[15:11]}, {1'b1, imgPxlData[10:8]}, {1'b1, imgPxlData[4:2]}};
                        else                                          o_rgb = {imgPxlData[15:12], imgPxlData[10:7], imgPxlData[4:1]};
                4'b1000:      if((x_pixel >= 240) && (x_pixel < 320)) o_rgb = {{1'b1, imgPxlData[15:11]}, {1'b1, imgPxlData[10:8]}, {1'b1, imgPxlData[4:2]}};
                        else                                          o_rgb = {imgPxlData[15:12], imgPxlData[10:7], imgPxlData[4:1]};
                4'b0011:      if((x_pixel >=   0) && (x_pixel <  80)) o_rgb = {{1'b1, imgPxlData[15:11]}, {1'b1, imgPxlData[10:8]}, {1'b1, imgPxlData[4:2]}};
                        else  if((x_pixel >=  80) && (x_pixel < 160)) o_rgb = {{1'b1, imgPxlData[15:11]}, {1'b1, imgPxlData[10:8]}, {1'b1, imgPxlData[4:2]}};
                        else                                          o_rgb = {imgPxlData[15:12], imgPxlData[10:7], imgPxlData[4:1]};
                4'b0101:      if((x_pixel >=   0) && (x_pixel <  80)) o_rgb = {{1'b1, imgPxlData[15:11]}, {1'b1, imgPxlData[10:8]}, {1'b1, imgPxlData[4:2]}};
                        else  if((x_pixel >= 160) && (x_pixel < 240)) o_rgb = {{1'b1, imgPxlData[15:11]}, {1'b1, imgPxlData[10:8]}, {1'b1, imgPxlData[4:2]}};
                        else                                          o_rgb = {imgPxlData[15:12], imgPxlData[10:7], imgPxlData[4:1]};
                4'b1001:      if((x_pixel >=   0) && (x_pixel <  80)) o_rgb = {{1'b1, imgPxlData[15:11]}, {1'b1, imgPxlData[10:8]}, {1'b1, imgPxlData[4:2]}};
                        else  if((x_pixel >= 240) && (x_pixel < 320)) o_rgb = {{1'b1, imgPxlData[15:11]}, {1'b1, imgPxlData[10:8]}, {1'b1, imgPxlData[4:2]}};
                        else                                          o_rgb = {imgPxlData[15:12], imgPxlData[10:7], imgPxlData[4:1]};
                4'b0110:      if((x_pixel >=  80) && (x_pixel < 160)) o_rgb = {{1'b1, imgPxlData[15:11]}, {1'b1, imgPxlData[10:8]}, {1'b1, imgPxlData[4:2]}};
                        else  if((x_pixel >= 160) && (x_pixel < 240)) o_rgb = {{1'b1, imgPxlData[15:11]}, {1'b1, imgPxlData[10:8]}, {1'b1, imgPxlData[4:2]}};
                        else                                          o_rgb = {imgPxlData[15:12], imgPxlData[10:7], imgPxlData[4:1]};
                4'b1010:      if((x_pixel >=  80) && (x_pixel < 160)) o_rgb = {{1'b1, imgPxlData[15:11]}, {1'b1, imgPxlData[10:8]}, {1'b1, imgPxlData[4:2]}};
                        else  if((x_pixel >= 240) && (x_pixel < 320)) o_rgb = {{1'b1, imgPxlData[15:11]}, {1'b1, imgPxlData[10:8]}, {1'b1, imgPxlData[4:2]}};
                        else                                          o_rgb = {imgPxlData[15:12], imgPxlData[10:7], imgPxlData[4:1]};
                4'b1100:      if((x_pixel >= 160) && (x_pixel < 240)) o_rgb = {{1'b1, imgPxlData[15:11]}, {1'b1, imgPxlData[10:8]}, {1'b1, imgPxlData[4:2]}};
                        else  if((x_pixel >= 240) && (x_pixel < 320)) o_rgb = {{1'b1, imgPxlData[15:11]}, {1'b1, imgPxlData[10:8]}, {1'b1, imgPxlData[4:2]}};
                        else                                          o_rgb = {imgPxlData[15:12], imgPxlData[10:7], imgPxlData[4:1]};
                4'b0111:      if((x_pixel >=   0) && (x_pixel <  80)) o_rgb = {{1'b1, imgPxlData[15:11]}, {1'b1, imgPxlData[10:8]}, {1'b1, imgPxlData[4:2]}};
                        else  if((x_pixel >=  80) && (x_pixel < 160)) o_rgb = {{1'b1, imgPxlData[15:11]}, {1'b1, imgPxlData[10:8]}, {1'b1, imgPxlData[4:2]}};
                        else  if((x_pixel >= 160) && (x_pixel < 240)) o_rgb = {{1'b1, imgPxlData[15:11]}, {1'b1, imgPxlData[10:8]}, {1'b1, imgPxlData[4:2]}};
                        else                                          o_rgb = {imgPxlData[15:12], imgPxlData[10:7], imgPxlData[4:1]};
                4'b1011:      if((x_pixel >=   0) && (x_pixel <  80)) o_rgb = {{1'b1, imgPxlData[15:11]}, {1'b1, imgPxlData[10:8]}, {1'b1, imgPxlData[4:2]}};
                        else  if((x_pixel >=  80) && (x_pixel < 160)) o_rgb = {{1'b1, imgPxlData[15:11]}, {1'b1, imgPxlData[10:8]}, {1'b1, imgPxlData[4:2]}};
                        else  if((x_pixel >= 240) && (x_pixel < 320)) o_rgb = {{1'b1, imgPxlData[15:11]}, {1'b1, imgPxlData[10:8]}, {1'b1, imgPxlData[4:2]}};
                        else                                          o_rgb = {imgPxlData[15:12], imgPxlData[10:7], imgPxlData[4:1]};
                4'b1101:      if((x_pixel >=   0) && (x_pixel <  80)) o_rgb = {{1'b1, imgPxlData[15:11]}, {1'b1, imgPxlData[10:8]}, {1'b1, imgPxlData[4:2]}};
                        else  if((x_pixel >= 160) && (x_pixel < 240)) o_rgb = {{1'b1, imgPxlData[15:11]}, {1'b1, imgPxlData[10:8]}, {1'b1, imgPxlData[4:2]}};
                        else  if((x_pixel >= 240) && (x_pixel < 320)) o_rgb = {{1'b1, imgPxlData[15:11]}, {1'b1, imgPxlData[10:8]}, {1'b1, imgPxlData[4:2]}};
                        else                                          o_rgb = {imgPxlData[15:12], imgPxlData[10:7], imgPxlData[4:1]};
                4'b1110:      if((x_pixel >=  80) && (x_pixel < 160)) o_rgb = {{1'b1, imgPxlData[15:11]}, {1'b1, imgPxlData[10:8]}, {1'b1, imgPxlData[4:2]}};
                        else  if((x_pixel >= 160) && (x_pixel < 240)) o_rgb = {{1'b1, imgPxlData[15:11]}, {1'b1, imgPxlData[10:8]}, {1'b1, imgPxlData[4:2]}};
                        else  if((x_pixel >= 240) && (x_pixel < 320)) o_rgb = {{1'b1, imgPxlData[15:11]}, {1'b1, imgPxlData[10:8]}, {1'b1, imgPxlData[4:2]}};
                        else                                          o_rgb = {imgPxlData[15:12], imgPxlData[10:7], imgPxlData[4:1]};
                4'b1111: o_rgb = {{1'b1, imgPxlData[15:11]}, {1'b1, imgPxlData[10:8]}, {1'b1, imgPxlData[4:2]}};
                4'b0000: o_rgb = {imgPxlData[15:12], imgPxlData[10:7], imgPxlData[4:1]};
            endcase
        end else begin
            o_rgb = 0;
        end
    end
endmodule

module Filter_NOTE(
    input  logic [3:0]  note_x0,
    input  logic [3:0]  note_x1,
    input  logic [3:0]  note_x2,
    input  logic [3:0]  note_x3,
    input  logic [9:0]  note_x4,
    input  logic [9:0]  note_x5,
    input  logic [9:0]  note_x6,
    input  logic [9:0]  note_x7,
    input  logic [9:0]  note_x8,
    input  logic [9:0]  note_x9,
    input  logic [9:0]  note_x10,
    input  logic [9:0]  note_x11,
    input  logic [9:0]  note_x12,
    input  logic [9:0]  note_x13,
    input  logic [9:0]  note_x14,
    input  logic [9:0]  note_x15,
    input  logic [9:0]  note_y0,
    input  logic [9:0]  note_y1,
    input  logic [9:0]  note_y2,
    input  logic [9:0]  note_y3,
    input  logic [9:0]  note_y4,
    input  logic [9:0]  note_y5,
    input  logic [9:0]  note_y6,
    input  logic [9:0]  note_y7,
    input  logic [9:0]  note_y8,
    input  logic [9:0]  note_y9,
    input  logic [9:0]  note_y10,
    input  logic [9:0]  note_y11,
    input  logic [9:0]  note_y12,
    input  logic [9:0]  note_y13,
    input  logic [9:0]  note_y14,
    input  logic [9:0]  note_y15,
    input  logic [9:0]  x_pixel,
    input  logic [9:0]  y_pixel,
    input  logic [11:0] i_rgb,
    output logic [11:0] o_rgb
);

    logic disp;
    logic y0_disp, y1_disp, y2_disp, y3_disp;

    assign y0_disp = (note_y0  > 1) ? ((y_pixel >= note_y0  - 2) && (y_pixel < note_y0  + 2)) : (note_y0  && (y_pixel < 2));
    assign y1_disp = (note_y1  > 1) ? ((y_pixel >= note_y1  - 2) && (y_pixel < note_y1  + 2)) : (note_y1  && (y_pixel < 2));
    assign y2_disp = (note_y2  > 1) ? ((y_pixel >= note_y2  - 2) && (y_pixel < note_y2  + 2)) : (note_y2  && (y_pixel < 2));
    assign y3_disp = (note_y3  > 1) ? ((y_pixel >= note_y3  - 2) && (y_pixel < note_y3  + 2)) : (note_y3  && (y_pixel < 2));
    assign y4_disp = (note_y4  > 1) ? ((y_pixel >= note_y4  - 2) && (y_pixel < note_y4  + 2)) : (note_y4  && (y_pixel < 2));
    assign y5_disp = (note_y5  > 1) ? ((y_pixel >= note_y5  - 2) && (y_pixel < note_y5  + 2)) : (note_y5  && (y_pixel < 2));
    assign y6_disp = (note_y6  > 1) ? ((y_pixel >= note_y6  - 2) && (y_pixel < note_y6  + 2)) : (note_y6  && (y_pixel < 2));
    assign y7_disp = (note_y7  > 1) ? ((y_pixel >= note_y7  - 2) && (y_pixel < note_y7  + 2)) : (note_y7  && (y_pixel < 2));
    assign y8_disp = (note_y8  > 1) ? ((y_pixel >= note_y8  - 2) && (y_pixel < note_y8  + 2)) : (note_y8  && (y_pixel < 2));
    assign y9_disp = (note_y9  > 1) ? ((y_pixel >= note_y9  - 2) && (y_pixel < note_y9  + 2)) : (note_y9  && (y_pixel < 2));
    assign y10_disp = (note_y10 > 1) ? ((y_pixel >= note_y10 - 2) && (y_pixel < note_y10 + 2)) : (note_y10 && (y_pixel < 2));
    assign y11_disp = (note_y11 > 1) ? ((y_pixel >= note_y11 - 2) && (y_pixel < note_y11 + 2)) : (note_y11 && (y_pixel < 2));
    assign y12_disp = (note_y12 > 1) ? ((y_pixel >= note_y12 - 2) && (y_pixel < note_y12 + 2)) : (note_y12 && (y_pixel < 2));
    assign y13_disp = (note_y13 > 1) ? ((y_pixel >= note_y13 - 2) && (y_pixel < note_y13 + 2)) : (note_y13 && (y_pixel < 2));
    assign y14_disp = (note_y14 > 1) ? ((y_pixel >= note_y14 - 2) && (y_pixel < note_y14 + 2)) : (note_y14 && (y_pixel < 2));
    assign y15_disp = (note_y15 > 1) ? ((y_pixel >= note_y15 - 2) && (y_pixel < note_y15 + 2)) : (note_y15 && (y_pixel < 2));

    always_comb begin
        disp = 1'b0;

        if(note_y0 && y0_disp) begin
            if(note_x0[3] && (x_pixel >=  20 && x_pixel <  60)) disp = 1'b1;
            if(note_x0[2] && (x_pixel >= 100 && x_pixel < 140)) disp = 1'b1;
            if(note_x0[1] && (x_pixel >= 180 && x_pixel < 220)) disp = 1'b1;
            if(note_x0[0] && (x_pixel >= 260 && x_pixel < 300)) disp = 1'b1;
        end
        if(note_y1 && y1_disp) begin
            if(note_x1[3] && (x_pixel >=  20 && x_pixel <  60)) disp = 1'b1;
            if(note_x1[2] && (x_pixel >= 100 && x_pixel < 140)) disp = 1'b1;
            if(note_x1[1] && (x_pixel >= 180 && x_pixel < 220)) disp = 1'b1;
            if(note_x1[0] && (x_pixel >= 260 && x_pixel < 300)) disp = 1'b1;
        end
        if(note_y2 && y2_disp) begin
            if(note_x2[3] && (x_pixel >=  20 && x_pixel <  60)) disp = 1'b1;
            if(note_x2[2] && (x_pixel >= 100 && x_pixel < 140)) disp = 1'b1;
            if(note_x2[1] && (x_pixel >= 180 && x_pixel < 220)) disp = 1'b1;
            if(note_x2[0] && (x_pixel >= 260 && x_pixel < 300)) disp = 1'b1;
        end
        if(note_y3 && y3_disp) begin
            if(note_x3[3] && (x_pixel >=  20 && x_pixel <  60)) disp = 1'b1;
            if(note_x3[2] && (x_pixel >= 100 && x_pixel < 140)) disp = 1'b1;
            if(note_x3[1] && (x_pixel >= 180 && x_pixel < 220)) disp = 1'b1;
            if(note_x3[0] && (x_pixel >= 260 && x_pixel < 300)) disp = 1'b1;
        end
        if(note_y4 && y4_disp) begin
            if(note_x4[3] && (x_pixel >=  20 && x_pixel <  60)) disp = 1'b1;
            if(note_x4[2] && (x_pixel >= 100 && x_pixel < 140)) disp = 1'b1;
            if(note_x4[1] && (x_pixel >= 180 && x_pixel < 220)) disp = 1'b1;
            if(note_x4[0] && (x_pixel >= 260 && x_pixel < 300)) disp = 1'b1;
        end
        if(note_y5 && y5_disp) begin
            if(note_x5[3] && (x_pixel >=  20 && x_pixel <  60)) disp = 1'b1;
            if(note_x5[2] && (x_pixel >= 100 && x_pixel < 140)) disp = 1'b1;
            if(note_x5[1] && (x_pixel >= 180 && x_pixel < 220)) disp = 1'b1;
            if(note_x5[0] && (x_pixel >= 260 && x_pixel < 300)) disp = 1'b1;
        end
        if(note_y6 && y6_disp) begin
            if(note_x6[3] && (x_pixel >=  20 && x_pixel <  60)) disp = 1'b1;
            if(note_x6[2] && (x_pixel >= 100 && x_pixel < 140)) disp = 1'b1;
            if(note_x6[1] && (x_pixel >= 180 && x_pixel < 220)) disp = 1'b1;
            if(note_x6[0] && (x_pixel >= 260 && x_pixel < 300)) disp = 1'b1;
        end
        if(note_y7 && y7_disp) begin
            if(note_x7[3] && (x_pixel >=  20 && x_pixel <  60)) disp = 1'b1;
            if(note_x7[2] && (x_pixel >= 100 && x_pixel < 140)) disp = 1'b1;
            if(note_x7[1] && (x_pixel >= 180 && x_pixel < 220)) disp = 1'b1;
            if(note_x7[0] && (x_pixel >= 260 && x_pixel < 300)) disp = 1'b1;
        end
        if(note_y8 && y8_disp) begin
            if(note_x8[3] && (x_pixel >=  20 && x_pixel <  60)) disp = 1'b1;
            if(note_x8[2] && (x_pixel >= 100 && x_pixel < 140)) disp = 1'b1;
            if(note_x8[1] && (x_pixel >= 180 && x_pixel < 220)) disp = 1'b1;
            if(note_x8[0] && (x_pixel >= 260 && x_pixel < 300)) disp = 1'b1;
        end
        if(note_y9 && y9_disp) begin
            if(note_x9[3] && (x_pixel >=  20 && x_pixel <  60)) disp = 1'b1;
            if(note_x9[2] && (x_pixel >= 100 && x_pixel < 140)) disp = 1'b1;
            if(note_x9[1] && (x_pixel >= 180 && x_pixel < 220)) disp = 1'b1;
            if(note_x9[0] && (x_pixel >= 260 && x_pixel < 300)) disp = 1'b1;
        end
        if(note_y10 && y10_disp) begin
            if(note_x10[3] && (x_pixel >=  20 && x_pixel <  60)) disp = 1'b1;
            if(note_x10[2] && (x_pixel >= 100 && x_pixel < 140)) disp = 1'b1;
            if(note_x10[1] && (x_pixel >= 180 && x_pixel < 220)) disp = 1'b1;
            if(note_x10[0] && (x_pixel >= 260 && x_pixel < 300)) disp = 1'b1;
        end
        if(note_y11 && y11_disp) begin
            if(note_x11[3] && (x_pixel >=  20 && x_pixel <  60)) disp = 1'b1;
            if(note_x11[2] && (x_pixel >= 100 && x_pixel < 140)) disp = 1'b1;
            if(note_x11[1] && (x_pixel >= 180 && x_pixel < 220)) disp = 1'b1;
            if(note_x11[0] && (x_pixel >= 260 && x_pixel < 300)) disp = 1'b1;
        end
        if(note_y12 && y12_disp) begin
            if(note_x12[3] && (x_pixel >=  20 && x_pixel <  60)) disp = 1'b1;
            if(note_x12[2] && (x_pixel >= 100 && x_pixel < 140)) disp = 1'b1;
            if(note_x12[1] && (x_pixel >= 180 && x_pixel < 220)) disp = 1'b1;
            if(note_x12[0] && (x_pixel >= 260 && x_pixel < 300)) disp = 1'b1;
        end
        if(note_y13 && y13_disp) begin
            if(note_x13[3] && (x_pixel >=  20 && x_pixel <  60)) disp = 1'b1;
            if(note_x13[2] && (x_pixel >= 100 && x_pixel < 140)) disp = 1'b1;
            if(note_x13[1] && (x_pixel >= 180 && x_pixel < 220)) disp = 1'b1;
            if(note_x13[0] && (x_pixel >= 260 && x_pixel < 300)) disp = 1'b1;
        end
        if(note_y14 && y14_disp) begin
            if(note_x14[3] && (x_pixel >=  20 && x_pixel <  60)) disp = 1'b1;
            if(note_x14[2] && (x_pixel >= 100 && x_pixel < 140)) disp = 1'b1;
            if(note_x14[1] && (x_pixel >= 180 && x_pixel < 220)) disp = 1'b1;
            if(note_x14[0] && (x_pixel >= 260 && x_pixel < 300)) disp = 1'b1;
        end
        if(note_y15 && y15_disp) begin
            if(note_x15[3] && (x_pixel >=  20 && x_pixel <  60)) disp = 1'b1;
            if(note_x15[2] && (x_pixel >= 100 && x_pixel < 140)) disp = 1'b1;
            if(note_x15[1] && (x_pixel >= 180 && x_pixel < 220)) disp = 1'b1;
            if(note_x15[0] && (x_pixel >= 260 && x_pixel < 300)) disp = 1'b1;
        end

        if(disp) o_rgb = 12'hfff;
        else     o_rgb = i_rgb;
    end
endmodule


module Filter_GAME(
    input  logic [9:0]  x_pixel,
    input  logic [9:0]  y_pixel,
    input  logic [11:0] i_rgb,
    output logic [11:0] o_rgb
);
    always_comb begin
        // seperate region
        if     ((x_pixel >=  79) && (x_pixel <  81)) o_rgb = 12'hfff;
        else if((x_pixel >= 159) && (x_pixel < 161)) o_rgb = 12'hfff;
        else if((x_pixel >= 239) && (x_pixel < 241)) o_rgb = 12'hfff;
        // detecting area
        else if((y_pixel >= 190) && (y_pixel < 220)) o_rgb = {2'b11, i_rgb[11:10], 2'b11, i_rgb[7:6], 2'b11, i_rgb[3:2]};
        else o_rgb = i_rgb;
    end
endmodule
