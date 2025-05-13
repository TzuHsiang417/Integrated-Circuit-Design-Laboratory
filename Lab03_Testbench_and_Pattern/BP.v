module BP(clk, rst_n, in_valid, guy, in0, in1, in2, in3, in4, in5, in6, in7, out_valid, out);

input clk, rst_n;
input in_valid;
input [2:0] guy;
input [1:0] in0, in1, in2, in3, in4, in5, in6, in7;
output reg out_valid;
output reg [1:0] out;
 
reg [2:0] last_obstacle;
reg [2:0] current_obstacle;
reg [5:0] current_cycle, last_obstacle_cycle;
reg [1:0] obstacle_type;
reg [1:0] out_tmp [0:62];
reg [2:0] act_num;
reg [1:0] action;
//reg [5:0] cnt;
reg [1:0] in_tmp;

wire [5:0] passed_cycle;

reg [1:0] c_state, n_state;

parameter STANDBY = 2'b00, READ = 2'b01, RESULT = 2'b10;
parameter NO_OBSTACLES = 2'b00, LOW_PLACES = 2'b01, HIGH_PLACES = 2'b10, FULL_OBSTACLES = 2'b11;
parameter STOP = 2'd0, RIGHT = 2'd1, LEFT = 2'd2, JUMP = 2'd3;

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
        READ:       if(current_cycle == 6'd63) n_state = RESULT;
                    else n_state = READ;
        RESULT:     if(current_cycle == 6'd62) n_state = STANDBY;
                    else n_state = RESULT;
        default:    n_state = STANDBY;
    endcase
end

always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        in_tmp <= 0;
    else if(c_state == READ)
        in_tmp <= in0;
    else
        in_tmp <= 0;
end

always @(posedge clk or negedge rst_n) 
begin
    if(!rst_n)
        current_obstacle <= 0;
    else if(c_state == STANDBY && n_state == READ && current_cycle == 0)
        current_obstacle <= guy;
    else if(c_state == STANDBY)
        current_obstacle <= 0;
    else if(c_state == READ && in0 != NO_OBSTACLES)
    begin
        if(in0 != FULL_OBSTACLES)
            current_obstacle <= 3'd0;
        else if(in1 != FULL_OBSTACLES)
            current_obstacle <= 3'd1;
        else if(in2 != FULL_OBSTACLES)
            current_obstacle <= 3'd2;
        else if(in3 != FULL_OBSTACLES)
            current_obstacle <= 3'd3;
        else if(in4 != FULL_OBSTACLES)
            current_obstacle <= 3'd4;
        else if(in5 != FULL_OBSTACLES)
            current_obstacle <= 3'd5;
        else if(in6 != FULL_OBSTACLES)
            current_obstacle <= 3'd6;
        else
            current_obstacle <= 3'd7;
    end
    /*else if(current_cycle == 6'd62)
        current_obstacle <= current_obstacle;*/
    else
        current_obstacle <= current_obstacle;
end

always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        last_obstacle <= 0;
    else if(c_state == STANDBY)
        last_obstacle <= 0;
    else if(c_state == READ && (in0 != NO_OBSTACLES || current_cycle == 6'd62))
        last_obstacle <= current_obstacle;
    else
        last_obstacle <= last_obstacle;
end

always @(posedge clk or negedge rst_n) 
begin
    if(!rst_n)
        current_cycle <= 6'd0;
    else if(c_state == STANDBY)
        current_cycle <= 6'd0;
    else if(c_state == READ || c_state == RESULT)
        current_cycle <= current_cycle + 1'b1;
    else 
        current_cycle <= current_cycle;
end

always @(negedge clk or negedge rst_n) 
begin
    if(!rst_n)
        last_obstacle_cycle <= 0;
    else if(c_state == STANDBY)
        last_obstacle_cycle <= 0;
    else if(c_state == READ && in_tmp != NO_OBSTACLES)
        last_obstacle_cycle <= current_cycle;
    else 
        last_obstacle_cycle <= last_obstacle_cycle;
end

always @(posedge clk or negedge rst_n) 
begin
    if(!rst_n)
        obstacle_type <= 0;
    else if(c_state == STANDBY)
        obstacle_type <= 0;
    else if(c_state == READ && in0 != 0)
    begin
        if(in0 != FULL_OBSTACLES)
            obstacle_type <= in0;
        else if(in1 != FULL_OBSTACLES)
            obstacle_type <= in1;
        else if(in2 != FULL_OBSTACLES)
            obstacle_type <= in2;
        else if(in3 != FULL_OBSTACLES)
            obstacle_type <= in3;
        else if(in4 != FULL_OBSTACLES)
            obstacle_type <= in4;
        else if(in5 != FULL_OBSTACLES)
            obstacle_type <= in5;
        else if(in6 != FULL_OBSTACLES)
            obstacle_type <= in6;
        else
            obstacle_type <= in7;
    end
    else
        obstacle_type <= obstacle_type;
end

always @(*)
begin
    if(current_obstacle > last_obstacle)
        act_num = current_obstacle - last_obstacle;
    else
        act_num = last_obstacle - current_obstacle;
end

always @(*)
begin
    if(current_obstacle > last_obstacle)
        action = RIGHT;
    else if(current_obstacle < last_obstacle)
        action = LEFT;
    else
        action = STOP;
end

assign passed_cycle = current_cycle - last_obstacle_cycle;

genvar i;
generate
    for (i=0; i<63; i=i+1) 
    begin
        always @(negedge clk or negedge rst_n)
        begin
            if(!rst_n)
                out_tmp[i] <= 0;
            else if(c_state == STANDBY)
                out_tmp[i] <= 0;
            else if(c_state == READ && (in_tmp != NO_OBSTACLES || current_cycle == 6'd63))
            begin
                if((last_obstacle_cycle <= i) && ((last_obstacle_cycle + act_num) > i))
                    out_tmp[i] <= action;
                else if(((current_cycle - 1'b1) <= i) && (current_cycle > i))
                begin
                    if(obstacle_type == LOW_PLACES)
                        out_tmp[i] <= JUMP;
                    else
                        out_tmp[i] <= STOP;
                end
                else if(((last_obstacle_cycle + act_num) <= i) && ((current_cycle - 1'b1) > i))
                    out_tmp[i] <= STOP;
                else
                    out_tmp[i] <= out_tmp[i];
            end
            else
                out_tmp[i] <= out_tmp[i];
        end
    end 
endgenerate

always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        out_valid <= 0;
    else if(n_state == RESULT)
        out_valid <= 1;
    else
        out_valid <= 0;
end

always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        out <= 0;
    else if(n_state == RESULT)
    begin
        out <= out_tmp[current_cycle + 1'b1];
    end
    else
        out <= 0;
end


endmodule
