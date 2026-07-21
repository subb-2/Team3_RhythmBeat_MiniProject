module frameBuffer_CAM0(
    // wirte side
    input  logic wclk,
    input  logic we,
    input  logic [$clog2(320*240)-1:0] wAddr, //QVGA size
    input  logic [15:0] wData,
    // read side
    input  logic                       rclk,
    input  logic [$clog2(320*240)-1:0] rAddr,
    output logic [15:0] rData
);

    logic [15:0] mem[0:(320*240)-1];

    // write side
    always_ff @(posedge wclk) begin
       if(we) mem[wAddr] <= wData; 
    end

    // read side
    always_ff @(posedge rclk) begin
        rData <= mem[rAddr];
    end
    // assign rData = mem[rAddr];

endmodule


module frameBuffer_CAM1(
    // wirte side - cam
    input  logic wclk,
    input  logic we,
    input  logic [$clog2(320*240)-1:0] wAddr, //QVGA size
    input  logic [15:0] wData,
    // read side - cam
    input  logic                       rclk,
    input  logic [$clog2(320*240)-1:0] rAddr,
    output logic [15:0] rData,
    // write side - cap
    input  logic wclk_cap,
    input  logic we_cap,
    input  logic [$clog2(80*110)-1:0] wAddr_cap,
    input  logic [11:0] wData_cap,
    // read side - uart
    input  logic rclk_cap,
    input  logic [$clog2(80*110)-1:0] rAddr_cap,
    output logic [11:0] rData_cap
);

    logic [15:0] mem[0:(320*240)-1];
    logic [11:0] captureRAM[0:(80*110)-1];

    // write side
    always_ff @(posedge wclk) begin
       if(we) mem[wAddr] <= wData; 
    end
    always_ff @(posedge wclk_cap) begin
        if(we_cap) captureRAM[wAddr_cap] <= wData_cap;
    end

    // read side
    always_ff @(posedge rclk) begin
        rData <= mem[rAddr];
    end
    always_ff @(posedge rclk_cap) begin
        rData_cap <= captureRAM[rAddr_cap];
    end

endmodule


module frameBuffer(
    // wirte side - cam0
    input  logic wclk_0,
    input  logic we_0,
    input  logic [$clog2(320*240)-1:0] wAddr_0, //QVGA size
    input  logic [15:0] wData_0,
    // read side - cam0
    input  logic                       rclk_0,
    input  logic [$clog2(320*240)-1:0] rAddr_0,
    output logic [15:0] rData_0,
    // wirte side - cam1
    input  logic wclk_1,
    input  logic we_1,
    input  logic [$clog2(320*240)-1:0] wAddr_1, //QVGA size
    input  logic [15:0] wData_1,
    // read side - cam1
    input  logic                       rclk_1,
    input  logic [$clog2(320*240)-1:0] rAddr_1,
    output logic [15:0] rData_1,
    // write side - cap
    input  logic wclk_cap,
    input  logic we_cap,
    input  logic [$clog2(80*110)-1:0] wAddr_cap,
    input  logic [11:0] wData_cap,
    // read side - uart
    input  logic rclk_cap,
    input  logic [$clog2(80*110)-1:0] rAddr_cap,
    output logic [11:0] rData_cap
);

    logic [15:0] cam0RAM[0:(320*240)-1];
    logic [15:0] cam1RAM[0:(320*240)-1];
    logic [11:0] captureRAM[0:(80*110)-1];

    // write side
    always_ff @(posedge wclk_0) begin
       if(we_0) cam0RAM[wAddr_0] <= wData_0; 
    end
    always_ff @(posedge wclk_1) begin
       if(we_1) cam1RAM[wAddr_1] <= wData_1; 
    end
    always_ff @(posedge wclk_cap) begin
        if(we_cap) captureRAM[wAddr_cap] <= wData_cap;
    end

    // read side
    always_ff @(posedge rclk_0) begin
        rData_0 <= cam0RAM[rAddr_0];
    end
    always_ff @(posedge rclk_1) begin
        rData_1 <= cam1RAM[rAddr_1];
    end
    always_ff @(posedge rclk_cap) begin
        rData_cap <= captureRAM[rAddr_cap];
    end

endmodule