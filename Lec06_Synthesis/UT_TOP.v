//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   File Name   : UT_TOP.v
//   Module Name : UT_TOP
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

//synopsys translate_off
`include "B2BCD_IP.v"
//synopsys translate_on

module UT_TOP (
    // Input signals
    clk, rst_n, in_valid, in_time,
    // Output signals
    out_valid, out_display, out_day
);

// ===============================================================
// Input & Output Declaration
// ===============================================================
input clk, rst_n, in_valid;
input [30:0] in_time;
output reg out_valid;
output reg [3:0] out_display;
output reg [2:0] out_day;

// ===============================================================
// Parameter & Integer Declaration
// ===============================================================



//---------------------------------------------------------------------
//   FSM State Declaration             
//---------------------------------------------------------------------

reg [1:0] c_state, n_state;
reg [6:0] counter, counter2;
parameter STANDBY = 2'b00, READ = 2'b01, RESULT = 2'b10, CAL = 2'b11;

always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        c_state <= STANDBY;
    else
        c_state <= n_state;
end

always @(*)
begin
    case(c_state)
        STANDBY:    if(in_valid) n_state = READ;
                    else n_state = STANDBY;
        READ:       if(counter == 6'd4) n_state = RESULT;
                    else n_state = READ;
        RESULT:     if(counter2 == 15) n_state = STANDBY;
                    else n_state = RESULT;
        default:    n_state = STANDBY;
	endcase
end

always @(posedge clk or negedge rst_n) 
begin
    if(!rst_n)
        counter <= 5'd0;
	else if(c_state == READ || c_state == RESULT || n_state == READ)
        counter <= counter + 1'b1;
    else if(c_state == STANDBY)
        counter <= 5'd0;
    else 
        counter <= counter;
end


//================================================================
// Wire & Reg Declaration
//================================================================
reg [30:0] UTC;

reg [14:0] total_day;

reg [25:0] div_out1;
reg [19:0] div_out2;
reg [14:0] div_out3;
reg [5:0] rem_out1, rem_out2, rem_out3;

reg [10:0] year, month, date, hour, min, sec, index;
reg [9:0] cmp_month, cmp_day;

reg [10:0] bcd_in;
wire [15:0] bcd_out;
reg [15:0] display, day;

reg Flag;
//================================================================
// DESIGN
//================================================================

//---------------------------------------------------------------------
//   INPUT circuit
//---------------------------------------------------------------------
always @(posedge clk or negedge rst_n) 
begin
    if(!rst_n)
        UTC <= 0;
    else if(in_valid)
        UTC <= in_time;
    else
        UTC <= UTC;
end

//---------------------------------------------------------------------
//   CALCULATION circuit
//---------------------------------------------------------------------
always @(posedge clk)
begin
    div_out1 <= UTC / 60;
    rem_out1 <= UTC % 60;
end

always @(posedge clk)
begin
    div_out2 <= div_out1 / 60;
    rem_out2 <= div_out1 % 60;
end

always @(posedge clk)
begin
    div_out3 <= div_out2 / 24;
    rem_out3 <= div_out2 % 24;
end

always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        year <= 0;
    else if(c_state == STANDBY)
        year <= 0;
    else if(c_state == RESULT)
    begin
        if((year+2)%4 == 0 && total_day > 365)
            year <= year + 1'b1;
        else if((year+2)%4 != 0 && total_day > 364)
            year <= year + 1'b1;
        else
            year <= year;
    end
    else
        year <= year;
end

always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        total_day <= 0;
    else if(c_state == STANDBY)
        total_day <= 0;
    else if(counter == 4)
        total_day <= div_out3;
    else if(c_state == RESULT)
    begin
        if((year+2)%4 == 0 && total_day > 365)
            total_day <= total_day - 366;
        else if((year+2)%4 != 0 && total_day > 364)
            total_day <= total_day - 365;
        else
            total_day <= total_day;
    end
    else
        total_day <= total_day;
end



always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        date <= 0;
    else if(c_state == RESULT)
    begin
        if((year+2)%4 == 0 && total_day <= 365)
            date <= total_day - cmp_day + 1'b1;
        else if((year+2)%4 != 0 && total_day <= 364)
            date <= total_day - cmp_day + 1'b1;
        else
            date <= date;
    end
    else
        date <= date;
end

always @(*)
begin
    if((year+2)%4 != 0)
    begin
        if(total_day < 31)
        begin
            cmp_day = 0;
            cmp_month = 1;
        end
        else if(total_day < 59)
        begin
            cmp_day = 31;
            cmp_month = 2;
        end
        else if(total_day < 90)
        begin
            cmp_day = 59;
            cmp_month = 3;
        end
        else if(total_day < 120)
        begin
            cmp_day = 90;
            cmp_month = 4;
        end
        else if(total_day < 151)
        begin
            cmp_day = 120;
            cmp_month = 5;
        end
        else if(total_day < 181)
        begin
            cmp_day = 151;
            cmp_month = 6;
        end
        else if(total_day < 212)
        begin
            cmp_day = 181;
            cmp_month = 7;
        end
        else if(total_day < 243)
        begin
            cmp_day = 212;
            cmp_month = 8;
        end
        else if(total_day < 273)
        begin
            cmp_day = 243;
            cmp_month = 9;
        end
        else if(total_day < 304)
        begin
            cmp_day = 273;
            cmp_month = 10;
        end
        else if(total_day < 334)
        begin
            cmp_day = 304;
            cmp_month = 11;
        end
        else
        begin
            cmp_day = 334;
            cmp_month = 12;
        end
    end
    else
    begin
        if(total_day < 31)
        begin
            cmp_day = 0;
            cmp_month = 1;
        end
        else if(total_day < 60)
        begin
            cmp_day = 31;
            cmp_month = 2;
        end
        else if(total_day < 91)
        begin
            cmp_day = 60;
            cmp_month = 3;
        end
        else if(total_day < 121)
        begin
            cmp_day = 91;
            cmp_month = 4;
        end
        else if(total_day < 152)
        begin
            cmp_day = 121;
            cmp_month = 5;
        end
        else if(total_day < 182)
        begin
            cmp_day = 152;
            cmp_month = 6;
        end
        else if(total_day < 213)
        begin
            cmp_day = 182;
            cmp_month = 7;
        end
        else if(total_day < 244)
        begin
            cmp_day = 213;
            cmp_month = 8;
        end
        else if(total_day < 274)
        begin
            cmp_day = 244;
            cmp_month = 9;
        end
        else if(total_day < 305)
        begin
            cmp_day = 274;
            cmp_month = 10;
        end
        else if(total_day < 335)
        begin
            cmp_day = 305;
            cmp_month = 11;
        end
        else
        begin
            cmp_day = 335;
            cmp_month = 12;
        end
    end
end

always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        Flag <= 0;
    else if(c_state == STANDBY)
        Flag <= 1'b0;
    else if(c_state == RESULT)
    begin
        if((year+2)%4 == 0 && total_day < 366)
            Flag <= 1'b1;
        else if((year+2)%4 != 0 && total_day < 365)
            Flag <= 1'b1;
        else
            Flag <= Flag;
    end
    else
        Flag <= Flag;
end

always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        counter2 <= 0;
    else if(c_state == STANDBY)
        counter2 <= 1'b0;
    else if(Flag)
        counter2 <= counter2 + 1'b1;
    else
        counter2 <= counter2;
end



always @(posedge clk or negedge rst_n) /////////////////////////////////////
begin
    if(!rst_n)
        month <= 0;
    else if(Flag)
        month <= cmp_month;
    else
        month <= month;
    
end


always @(posedge clk or negedge rst_n) 
begin
    if(!rst_n)
        hour <= 0;
    else if(counter == 4)
        hour <= rem_out3;
    else
        hour <= hour;
end

always @(posedge clk or negedge rst_n) 
begin
    if(!rst_n)
        min <= 0;
    else if(counter == 3)
        min <= rem_out2;
    else
        min <= min;
end

always @(posedge clk or negedge rst_n) 
begin
    if(!rst_n)
        sec <= 0;
    else if(counter == 2)
        sec <= rem_out1;
    else
        sec <= sec;
end

always @(posedge clk or negedge rst_n) 
begin
    if(!rst_n)
        index <= 0;
    else if(counter == 4)
        index <= div_out3 % 7;
    else if(counter == 6)
        index <= (index+4)%7;
    else
        index <= index;
end

always @(*)
begin
    if(Flag)
    begin
        case(counter2)
            5'd1:   bcd_in = year[10:0] + 1970;
            //5'd1:  bcd_in = index[10:0];
            5'd5:  bcd_in = month[10:0];
            5'd7:  bcd_in = date[10:0];
            5'd9:  bcd_in = hour[10:0];
            5'd11:  bcd_in = min[10:0];
            5'd13:  bcd_in = sec[10:0];
            default:bcd_in = 0;
        endcase
    end
    else
    begin
        if(counter == 6)
            bcd_in = index;
        else
            bcd_in = 0;
    end
end

B2BCD_IP #(.WIDTH(11), .DIGIT(4)) bcd (.Binary_code(bcd_in), .BCD_code(bcd_out));

always @(posedge clk or negedge rst_n) 
begin
    if(!rst_n)
        display <= 0;
    else if(counter2 == 1 || counter2 == 5 || counter2 == 7 || counter2 == 9 || counter2 == 11 || counter2 == 13)
        display <= bcd_out;
    else
        display <= display;
end

always @(posedge clk or negedge rst_n) 
begin
    if(!rst_n)
        day <= 0;
    else if(counter == 6)
        day <= bcd_out;
    else
        day <= day;
end

always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        out_valid <= 0;
    else if(counter2 >= 5'd2 && counter2 <= 5'd15)
        out_valid <= 1;
    else
        out_valid <= 0;
end

always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        out_display <= 0;
    else if(counter2 >= 5'd2 && counter2 <= 5'd15)
    begin
        case(counter2)
        5'd2:  out_display <= display[15:12];
        5'd3:  out_display <= display[11:8];
        5'd4:  out_display <= display[7:4];
        5'd5:  out_display <= display[3:0];
        5'd6:  out_display <= display[7:4];
        5'd7:  out_display <= display[3:0];
        5'd8:  out_display <= display[7:4];
        5'd9:  out_display <= display[3:0];
        5'd10:  out_display <= display[7:4];
        5'd11:  out_display <= display[3:0];
        5'd12:  out_display <= display[7:4];
        5'd13:  out_display <= display[3:0];
        5'd14:  out_display <= display[7:4];
        5'd15:  out_display <= display[3:0];
        default:out_display <= 0;
    endcase
    end
    else
        out_display <= 0;
end

always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        out_day <= 0;
    else if(counter2 >= 5'd2 && counter2 <= 5'd15)
        out_day <= index;
    else
        out_day <= 0;
end

endmodule

module div_FF (in1, in2, out1, out2, clk);
input clk;
input [30:0] in1;
input [5:0] in2;
output reg [30:0] out1;
output reg [5:0] out2;

always @(posedge clk)
begin
    out1 <= in1;
    out2 <= in2;
end

endmodule