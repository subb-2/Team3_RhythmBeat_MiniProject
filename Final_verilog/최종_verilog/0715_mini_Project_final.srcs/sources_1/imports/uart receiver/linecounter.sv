`timescale 1ns / 1ps

module line_count(

    input           clk,
    input           reset,

    // ram output
    input           i_note,
    input   [03:00] i_lane,
    input           i_vs,
        
    // game output
    output  [03:00] o_pos0, 
    output  [03:00] o_pos1,
    output  [03:00] o_pos2,
    output  [03:00] o_pos3,
    output  [03:00] o_pos4,
    output  [03:00] o_pos5,
    output  [03:00] o_pos6,
    output  [03:00] o_pos7,
    output  [03:00] o_pos8,
    output  [03:00] o_pos9,
    output  [03:00] o_pos10,
    output  [03:00] o_pos11,
    output  [03:00] o_pos12,
    output  [03:00] o_pos13,
    output  [03:00] o_pos14,
    output  [03:00] o_pos15,
    output  [09:00] o_lcnt0,
    output  [09:00] o_lcnt1,
    output  [09:00] o_lcnt2,
    output  [09:00] o_lcnt3,
    output  [09:00] o_lcnt4,
    output  [09:00] o_lcnt5,
    output  [09:00] o_lcnt6,
    output  [09:00] o_lcnt7,
    output  [09:00] o_lcnt8,
    output  [09:00] o_lcnt9,
    output  [09:00] o_lcnt10,
    output  [09:00] o_lcnt11,
    output  [09:00] o_lcnt12,
    output  [09:00] o_lcnt13,
    output  [09:00] o_lcnt14,
    output  [09:00] o_lcnt15

);


    //parameter [07:00] FRAME_NUM = 179;
    //parameter [06:00] LINE_VALUE = 480 / FRAME_NUM;
    //parameter [06:00] LINE_VALUE = 63;
    parameter [1:0] LINE_VALUE = 2;

    reg [03:00] cnt;

    reg [03:00] r_pos0;
    reg [03:00] r_pos1;
    reg [03:00] r_pos2;
    reg [03:00] r_pos3;
    reg [03:00] r_pos4;
    reg [03:00] r_pos5;
    reg [03:00] r_pos6;
    reg [03:00] r_pos7;
    reg [03:00] r_pos8;
    reg [03:00] r_pos9;
    reg [03:00] r_pos10;
    reg [03:00] r_pos11;
    reg [03:00] r_pos12;
    reg [03:00] r_pos13;
    reg [03:00] r_pos14;
    reg [03:00] r_pos15;

    reg [09:00] r_lcnt0;
    reg [09:00] r_lcnt1;
    reg [09:00] r_lcnt2;
    reg [09:00] r_lcnt3;
    reg [09:00] r_lcnt4;
    reg [09:00] r_lcnt5;
    reg [09:00] r_lcnt6;
    reg [09:00] r_lcnt7;
    reg [09:00] r_lcnt8;
    reg [09:00] r_lcnt9;
    reg [09:00] r_lcnt10;
    reg [09:00] r_lcnt11;
    reg [09:00] r_lcnt12;
    reg [09:00] r_lcnt13;
    reg [09:00] r_lcnt14;
    reg [09:00] r_lcnt15;

    reg         r_en0;
    reg         r_en1;
    reg         r_en2;
    reg         r_en3;
    reg         r_en4;
    reg         r_en5;
    reg         r_en6;
    reg         r_en7;
    reg         r_en8;
    reg         r_en9;
    reg         r_en10;
    reg         r_en11;
    reg         r_en12;
    reg         r_en13;
    reg         r_en14;
    reg         r_en15;

    reg         r_vs_dly0;
    
    wire        w_vs_dly0_f;

    assign o_pos0   =   r_pos0;
    assign o_pos1   =   r_pos1;
    assign o_pos2   =   r_pos2;
    assign o_pos3   =   r_pos3;
    assign o_pos4   =   r_pos4;
    assign o_pos5   =   r_pos5;
    assign o_pos6   =   r_pos6;
    assign o_pos7   =   r_pos7;
    assign o_pos8   =   r_pos8;
    assign o_pos9   =   r_pos9;
    assign o_pos10  =   r_pos10;
    assign o_pos11  =   r_pos11;
    assign o_pos12  =   r_pos12;
    assign o_pos13  =   r_pos13;
    assign o_pos14  =   r_pos14;
    assign o_pos15  =   r_pos15;



    assign o_lcnt0  =   r_lcnt0;
    assign o_lcnt1  =   r_lcnt1;
    assign o_lcnt2  =   r_lcnt2;
    assign o_lcnt3  =   r_lcnt3;
    assign o_lcnt4  =   r_lcnt4;
    assign o_lcnt5  =   r_lcnt5;
    assign o_lcnt6  =   r_lcnt6;
    assign o_lcnt7  =   r_lcnt7;
    assign o_lcnt8  =   r_lcnt8;
    assign o_lcnt9  =   r_lcnt9;
    assign o_lcnt10 =   r_lcnt10;
    assign o_lcnt11 =   r_lcnt11;
    assign o_lcnt12 =   r_lcnt12;
    assign o_lcnt13 =   r_lcnt13;
    assign o_lcnt14 =   r_lcnt14;
    assign o_lcnt15 =   r_lcnt15;
    

    
    always @ (posedge clk or posedge reset) begin
        if(reset) begin
            r_vs_dly0 <= 0;
        end
        else begin
            r_vs_dly0 <= i_vs;
        end
    end


    assign w_vs_dly0_r =  i_vs && ~r_vs_dly0;
    assign w_vs_dly0_f = ~i_vs &&  r_vs_dly0; 


    always @ (posedge clk or posedge reset) begin
        if(reset) begin
            cnt <= 0;
        end
        else if(i_note) begin
            cnt <= cnt + 1'b1;
        end
        else begin
            cnt <= cnt;
        end
    end

always @ (posedge clk or posedge reset) begin
        if(reset) begin
            r_pos0 <= 0;
        end
        else if(cnt == 0 && i_note) begin
            r_pos0 <= i_lane;
        end
        else begin
            r_pos0 <= r_pos0;
        end
    end

    always @ (posedge clk or posedge reset) begin
        if(reset) begin
            r_pos1 <= 0;
        end
        else if(cnt == 1 && i_note) begin
            r_pos1 <= i_lane;
        end
        else begin
            r_pos1 <= r_pos1;
        end
    end  

    always @ (posedge clk or posedge reset) begin
        if(reset) begin
            r_pos2 <= 0;
        end
        else if(cnt == 2 && i_note) begin
            r_pos2 <= i_lane;
        end
        else begin
            r_pos2 <= r_pos2;
        end
    end  

    always @ (posedge clk or posedge reset) begin
        if(reset) begin
            r_pos3 <= 0;
        end
        else if(cnt == 3 && i_note) begin
            r_pos3 <= i_lane;
        end
        else begin
            r_pos3 <= r_pos3;
        end
    end

    always @ (posedge clk or posedge reset) begin
        if(reset) begin
            r_pos4 <= 0;
        end
        else if(cnt == 4 && i_note) begin
            r_pos4 <= i_lane;
        end
        else begin
            r_pos4 <= r_pos4;
        end
    end

    always @ (posedge clk or posedge reset) begin
        if(reset) begin
            r_pos5 <= 0;
        end
        else if(cnt == 5 && i_note) begin
            r_pos5 <= i_lane;
        end
        else begin
            r_pos5 <= r_pos5;
        end
    end

    always @ (posedge clk or posedge reset) begin
        if(reset) begin
            r_pos6 <= 0;
        end
        else if(cnt == 6 && i_note) begin
            r_pos6 <= i_lane;
        end
        else begin
            r_pos6 <= r_pos6;
        end
    end

    always @ (posedge clk or posedge reset) begin
        if(reset) begin
            r_pos7 <= 0;
        end
        else if(cnt == 7 && i_note) begin
            r_pos7 <= i_lane;
        end
        else begin
            r_pos7 <= r_pos7;
        end
    end

    always @ (posedge clk or posedge reset) begin
        if(reset) begin
            r_pos8 <= 0;
        end
        else if(cnt == 8 && i_note) begin
            r_pos8 <= i_lane;
        end
        else begin
            r_pos8 <= r_pos8;
        end
    end

    always @ (posedge clk or posedge reset) begin
        if(reset) begin
            r_pos9 <= 0;
        end
        else if(cnt == 9 && i_note) begin
            r_pos9 <= i_lane;
        end
        else begin
            r_pos9 <= r_pos9;
        end
    end

    always @ (posedge clk or posedge reset) begin
        if(reset) begin
            r_pos10 <= 0;
        end
        else if(cnt == 10 && i_note) begin
            r_pos10 <= i_lane;
        end
        else begin
            r_pos10 <= r_pos10;
        end
    end

    always @ (posedge clk or posedge reset) begin
        if(reset) begin
            r_pos11 <= 0;
        end
        else if(cnt == 11 && i_note) begin
            r_pos11 <= i_lane;
        end
        else begin
            r_pos11 <= r_pos11;
        end
    end

    always @ (posedge clk or posedge reset) begin
        if(reset) begin
            r_pos12 <= 0;
        end
        else if(cnt == 12 && i_note) begin
            r_pos12 <= i_lane;
        end
        else begin
            r_pos12 <= r_pos12;
        end
    end

    always @ (posedge clk or posedge reset) begin
        if(reset) begin
            r_pos13 <= 0;
        end
        else if(cnt == 13 && i_note) begin
            r_pos13 <= i_lane;
        end
        else begin
            r_pos13 <= r_pos13;
        end
    end

    always @ (posedge clk or posedge reset) begin
        if(reset) begin
            r_pos14 <= 0;
        end
        else if(cnt == 14 && i_note) begin
            r_pos14 <= i_lane;
        end
        else begin
            r_pos14 <= r_pos14;
        end
    end

    always @ (posedge clk or posedge reset) begin
        if(reset) begin
            r_pos15 <= 0;
        end
        else if(cnt == 15 && i_note) begin
            r_pos15 <= i_lane;
        end
        else begin
            r_pos15 <= r_pos15;
        end
    end
    
    always @ (posedge clk or posedge reset) begin
        if(reset) begin
            r_en0 <= 0;
        end
        else if(r_lcnt0 >= 480) begin
            r_en0 <= 0;
        end
        else if(cnt == 0 && i_note) begin
            r_en0 <= 1;
        end
        else begin
            r_en0 <= r_en0;
        end
    end

    always @ (posedge clk or posedge reset) begin
        if(reset) begin
            r_en1 <= 0;
        end
        else if(r_lcnt1 >= 480) begin
            r_en1 <= 0;
        end
        else if(cnt == 1 && i_note) begin
            r_en1 <= 1;
        end
        else begin
            r_en1 <= r_en1;
        end
    end

    always @ (posedge clk or posedge reset) begin
        if(reset) begin
            r_en2 <= 0;
        end
        else if(r_lcnt2 >= 480) begin
            r_en2 <= 0;
        end
        else if(cnt == 2 && i_note) begin
            r_en2 <= 1;
        end
        else begin
            r_en2 <= r_en2;
        end
    end

    always @ (posedge clk or posedge reset) begin
        if(reset) begin
            r_en3 <= 0;
        end
        else if(r_lcnt3 >= 480) begin
            r_en3 <= 0;
        end
        else if(cnt == 3 && i_note) begin
            r_en3 <= 1;
        end
        else begin
            r_en3 <= r_en3;
        end
    end

    always @ (posedge clk or posedge reset) begin
        if(reset) begin
            r_en4 <= 0;
        end
        else if(r_lcnt4 >= 480) begin
            r_en4 <= 0;
        end
        else if(cnt == 4 && i_note) begin
            r_en4 <= 1;
        end
        else begin
            r_en4 <= r_en4;
        end
    end

    always @ (posedge clk or posedge reset) begin
        if(reset) begin
            r_en5 <= 0;
        end
        else if(r_lcnt5 >= 480) begin
            r_en5 <= 0;
        end
        else if(cnt == 5 && i_note) begin
            r_en5 <= 1;
        end
        else begin
            r_en5 <= r_en5;
        end
    end

    always @ (posedge clk or posedge reset) begin
        if(reset) begin
            r_en6 <= 0;
        end
        else if(r_lcnt6 >= 480) begin
            r_en6 <= 0;
        end
        else if(cnt == 6 && i_note) begin
            r_en6 <= 1;
        end
        else begin
            r_en6 <= r_en6;
        end
    end

    always @ (posedge clk or posedge reset) begin
        if(reset) begin
            r_en7 <= 0;
        end
        else if(r_lcnt7 >= 480) begin
            r_en7 <= 0;
        end
        else if(cnt == 7 && i_note) begin
            r_en7 <= 1;
        end
        else begin
            r_en7 <= r_en7;
        end
    end

    always @ (posedge clk or posedge reset) begin
        if(reset) begin
            r_en8 <= 0;
        end
        else if(r_lcnt8 >= 480) begin
            r_en8 <= 0;
        end
        else if(cnt == 8 && i_note) begin
            r_en8 <= 1;
        end
        else begin
            r_en8 <= r_en8;
        end
    end

    always @ (posedge clk or posedge reset) begin
        if(reset) begin
            r_en9 <= 0;
        end
        else if(r_lcnt9 >= 480) begin
            r_en9 <= 0;
        end
        else if(cnt == 9 && i_note) begin
            r_en9 <= 1;
        end
        else begin
            r_en9 <= r_en9;
        end
    end

    always @ (posedge clk or posedge reset) begin
        if(reset) begin
            r_en10 <= 0;
        end
        else if(r_lcnt10 >= 480) begin
            r_en10 <= 0;
        end
        else if(cnt == 10 && i_note) begin
            r_en10 <= 1;
        end
        else begin
            r_en10 <= r_en10;
        end
    end

    always @ (posedge clk or posedge reset) begin
        if(reset) begin
            r_en11 <= 0;
        end
        else if(r_lcnt11 >= 480) begin
            r_en11 <= 0;
        end
        else if(cnt == 11 && i_note) begin
            r_en11 <= 1;
        end
        else begin
            r_en11 <= r_en11;
        end
    end

    always @ (posedge clk or posedge reset) begin
        if(reset) begin
            r_en12 <= 0;
        end
        else if(r_lcnt12 >= 480) begin
            r_en12 <= 0;
        end
        else if(cnt == 12 && i_note) begin
            r_en12 <= 1;
        end
        else begin
            r_en12 <= r_en12;
        end
    end

    always @ (posedge clk or posedge reset) begin
        if(reset) begin
            r_en13 <= 0;
        end
        else if(r_lcnt13 >= 480) begin
            r_en13 <= 0;
        end
        else if(cnt == 13 && i_note) begin
            r_en13 <= 1;
        end
        else begin
            r_en13 <= r_en13;
        end
    end

    always @ (posedge clk or posedge reset) begin
        if(reset) begin
            r_en14 <= 0;
        end
        else if(r_lcnt14 >= 480) begin
            r_en14 <= 0;
        end
        else if(cnt == 14 && i_note) begin
            r_en14 <= 1;
        end
        else begin
            r_en14 <= r_en14;
        end
    end

    always @ (posedge clk or posedge reset) begin
        if(reset) begin
            r_en15 <= 0;
        end
        else if(r_lcnt15 >= 480) begin
            r_en15 <= 0;
        end
        else if(cnt == 15 && i_note) begin
            r_en15 <= 1;
        end
        else begin
            r_en15 <= r_en15;
        end
    end
    
    always @ (posedge clk or posedge reset) begin
        if(reset) begin
            r_lcnt0 <= 0;
        end
        else if(!r_en0) begin           //  !r_en OR r_lcnt0 >= 480 
            r_lcnt0 <= 0;
        end
        else if(r_en0 && w_vs_dly0_f) begin
            r_lcnt0 <= r_lcnt0 + LINE_VALUE;
        end
        else begin
            r_lcnt0 <= r_lcnt0;
        end
    end

    always @ (posedge clk or posedge reset) begin
        if(reset) begin
            r_lcnt1 <= 0;
        end
        else if(!r_en1) begin           //  !r_en OR r_lcnt1 >= 480 
            r_lcnt1 <= 0;
        end
        else if(r_en1 && w_vs_dly0_f) begin
            r_lcnt1 <= r_lcnt1 + LINE_VALUE;
        end
        else begin
            r_lcnt1 <= r_lcnt1;
        end
    end

    always @ (posedge clk or posedge reset) begin
        if(reset) begin
            r_lcnt2 <= 0;
        end
        else if(!r_en2) begin           //  !r_en OR r_lcnt2 >= 480 
            r_lcnt2 <= 0;
        end
        else if(r_en2 && w_vs_dly0_f) begin
            r_lcnt2 <= r_lcnt2 + LINE_VALUE;
        end
        else begin
            r_lcnt2 <= r_lcnt2;
        end
    end

    always @ (posedge clk or posedge reset) begin
        if(reset) begin
            r_lcnt3 <= 0;
        end
        else if(!r_en3) begin           //  !r_en OR r_lcnt3 >= 480 
            r_lcnt3 <= 0;
        end
        else if(r_en3 && w_vs_dly0_f) begin
            r_lcnt3 <= r_lcnt3 + LINE_VALUE;
        end
        else begin
            r_lcnt3 <= r_lcnt3;
        end
    end

    always @ (posedge clk or posedge reset) begin
        if(reset) begin
            r_lcnt4 <= 0;
        end
        else if(!r_en4) begin           //  !r_en OR r_lcnt4 >= 480 
            r_lcnt4 <= 0;
        end
        else if(r_en4 && w_vs_dly0_f) begin
            r_lcnt4 <= r_lcnt4 + LINE_VALUE;
        end
        else begin
            r_lcnt4 <= r_lcnt4;
        end
    end

    always @ (posedge clk or posedge reset) begin
        if(reset) begin
            r_lcnt5 <= 0;
        end
        else if(!r_en5) begin           //  !r_en OR r_lcnt5 >= 480 
            r_lcnt5 <= 0;
        end
        else if(r_en5 && w_vs_dly0_f) begin
            r_lcnt5 <= r_lcnt5 + LINE_VALUE;
        end
        else begin
            r_lcnt5 <= r_lcnt5;
        end
    end

    always @ (posedge clk or posedge reset) begin
        if(reset) begin
            r_lcnt6 <= 0;
        end
        else if(!r_en6) begin           //  !r_en OR r_lcnt6 >= 480 
            r_lcnt6 <= 0;
        end
        else if(r_en6 && w_vs_dly0_f) begin
            r_lcnt6 <= r_lcnt6 + LINE_VALUE;
        end
        else begin
            r_lcnt6 <= r_lcnt6;
        end
    end

    always @ (posedge clk or posedge reset) begin
        if(reset) begin
            r_lcnt7 <= 0;
        end
        else if(!r_en7) begin           //  !r_en OR r_lcnt7 >= 480 
            r_lcnt7 <= 0;
        end
        else if(r_en7 && w_vs_dly0_f) begin
            r_lcnt7 <= r_lcnt7 + LINE_VALUE;
        end
        else begin
            r_lcnt7 <= r_lcnt7;
        end
    end

    always @ (posedge clk or posedge reset) begin
        if(reset) begin
            r_lcnt8 <= 0;
        end
        else if(!r_en8) begin           //  !r_en OR r_lcnt8 >= 480 
            r_lcnt8 <= 0;
        end
        else if(r_en8 && w_vs_dly0_f) begin
            r_lcnt8 <= r_lcnt8 + LINE_VALUE;
        end
        else begin
            r_lcnt8 <= r_lcnt8;
        end
    end

    always @ (posedge clk or posedge reset) begin
        if(reset) begin
            r_lcnt9 <= 0;
        end
        else if(!r_en9) begin           //  !r_en OR r_lcnt9 >= 480 
            r_lcnt9 <= 0;
        end
        else if(r_en9 && w_vs_dly0_f) begin
            r_lcnt9 <= r_lcnt9 + LINE_VALUE;
        end
        else begin
            r_lcnt9 <= r_lcnt9;
        end
    end

    always @ (posedge clk or posedge reset) begin
        if(reset) begin
            r_lcnt10 <= 0;
        end
        else if(!r_en10) begin           //  !r_en OR r_lcnt10 >= 480 
            r_lcnt10 <= 0;
        end
        else if(r_en10 && w_vs_dly0_f) begin
            r_lcnt10 <= r_lcnt10 + LINE_VALUE;
        end
        else begin
            r_lcnt10 <= r_lcnt10;
        end
    end

    always @ (posedge clk or posedge reset) begin
        if(reset) begin
            r_lcnt11 <= 0;
        end
        else if(!r_en11) begin           //  !r_en OR r_lcnt11 >= 480 
            r_lcnt11 <= 0;
        end
        else if(r_en11 && w_vs_dly0_f) begin
            r_lcnt11 <= r_lcnt11 + LINE_VALUE;
        end
        else begin
            r_lcnt11 <= r_lcnt11;
        end
    end

    always @ (posedge clk or posedge reset) begin
        if(reset) begin
            r_lcnt12 <= 0;
        end
        else if(!r_en12) begin           //  !r_en OR r_lcnt12 >= 480 
            r_lcnt12 <= 0;
        end
        else if(r_en12 && w_vs_dly0_f) begin
            r_lcnt12 <= r_lcnt12 + LINE_VALUE;
        end
        else begin
            r_lcnt12 <= r_lcnt12;
        end
    end

    always @ (posedge clk or posedge reset) begin
        if(reset) begin
            r_lcnt13 <= 0;
        end
        else if(!r_en13) begin           //  !r_en OR r_lcnt13 >= 480 
            r_lcnt13 <= 0;
        end
        else if(r_en13 && w_vs_dly0_f) begin
            r_lcnt13 <= r_lcnt13 + LINE_VALUE;
        end
        else begin
            r_lcnt13 <= r_lcnt13;
        end
    end

    always @ (posedge clk or posedge reset) begin
        if(reset) begin
            r_lcnt14 <= 0;
        end
        else if(!r_en14) begin           //  !r_en OR r_lcnt14 >= 480 
            r_lcnt14 <= 0;
        end
        else if(r_en14 && w_vs_dly0_f) begin
            r_lcnt14 <= r_lcnt14 + LINE_VALUE;
        end
        else begin
            r_lcnt14 <= r_lcnt14;
        end
    end

    always @ (posedge clk or posedge reset) begin
        if(reset) begin
            r_lcnt15 <= 0;
        end
        else if(!r_en15) begin           //  !r_en OR r_lcnt15 >= 480 
            r_lcnt15 <= 0;
        end
        else if(r_en15 && w_vs_dly0_f) begin
            r_lcnt15 <= r_lcnt15 + LINE_VALUE;
        end
        else begin
            r_lcnt15 <= r_lcnt15;
        end
    end



endmodule