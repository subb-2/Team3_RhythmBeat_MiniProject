`timescale 1ns / 1ps

module VGAcam(
    input  logic clk_100M,
    input  logic clk_25M,
    input  logic reset,

    output logic       xclk,
    input  logic       pclk,
    input  logic       href,
    input  logic       vsync,
    input  logic [7:0] pdata,

    output logic       h_sync,
    output logic       v_sync,
    output logic [3:0] port_red,
    output logic [3:0] port_green,
    output logic [3:0] port_blue,

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

    output logic [3:0] region,

    output logic scl,
    inout  logic sda
);

    logic [9:0] x_pixel;
    logic [9:0] y_pixel;
    logic de;

    logic [$clog2(320*240)-1:0] imgPxlAddr;
    logic [15:0] imgPxlData;

    logic we;
    logic [$clog2(320*240)-1:0] wAddr;
    logic [15:0] wData;

    logic rclk;

    assign xclk = clk_25M;

    OV7670_SCCB_Controller U_SCCB_Data_Ctrl(
        .clk(clk_100M),
        .reset(reset),
        .scl(scl),
        .sda(sda)
    );

    VGA_Decoder U_VGA_Decoder(
        .clk(clk_100M),
        .reset(reset),
        .rclk(rclk),
        .h_sync(h_sync),
        .v_sync(v_sync),
        .x_pixel(x_pixel),
        .y_pixel(y_pixel),
        .de(de)
    );

    OV7670MemController U_OV7670MemController(
        .pclk(pclk),
        .reset(reset),
        .href(href),
        .vsync(vsync),
        .pdata(pdata),
        .we(we),
        .wAddr(wAddr),
        .wData(wData)
    );
    frameBuffer_CAM0 U_FrameBuffer (
        .wclk(pclk),
        .we(we),
        .wAddr(wAddr),
        .wData(wData),
        .rclk(rclk),
        .rAddr(imgPxlAddr),
        .rData(imgPxlData)
    );
    framePrinter U_framePrinter(
        .clk(rclk),
        .reset(reset),
        .vsync(vsync),
        .x_pixel(x_pixel),
        .y_pixel(y_pixel),
        .imgPxlData(imgPxlData),
        .imgPxlAddr(imgPxlAddr),
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
        .RGBport({port_red, port_green, port_blue}),
        .region(region)
    );
endmodule
