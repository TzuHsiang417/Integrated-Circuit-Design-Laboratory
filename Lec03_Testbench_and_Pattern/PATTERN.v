`ifdef RTL
    `define CYCLE_TIME 10.0
`endif
`ifdef GATE
    `define CYCLE_TIME 10.0
`endif

module PATTERN(
  clk,
  rst_n,
  in_valid,
  guy,
  in0,
  in1,
  in2,
  in3,
  in4,
  in5,
  in6,
  in7,
  
  out_valid,
  out
);

output reg       clk, rst_n;
output reg       in_valid;
output reg [2:0] guy;
output reg [1:0] in0, in1, in2, in3, in4, in5, in6, in7;
input            out_valid;
input      [1:0] out;

real CYCLE = `CYCLE_TIME;
always #(CYCLE/2.0) clk = ~clk;

parameter STOP = 2'd0, RIGHT = 2'd1, LEFT = 2'd2, JUMP = 2'd3;
parameter NO_OBSTACLES = 2'b00, LOW_PLACES = 2'b01, HIGH_PLACES = 2'b10, FULL_OBSTACLES = 2'b11;

integer map[63:0][7:0];
integer guy_tmp;
integer i, j, k, l, m, t, n;
integer obstacle_position, rand_position, position_diff, obstacle_cycle;
integer latency, latency2;
reg obstacle_state;

reg [1:0] out_tmp[62:0];
integer out_position, vertical_position;

integer SEED = 87;


initial 
begin
    $display("************************************************************1");
    //SEED = 221;
    reset_task;
    
    for(n=0; n<300; n=n+1)
    begin
        SEED = SEED + n;
        create_map_task;
        input_task;
        wait_out_valid_task;
        result_task;
        check_out_reset_task;
        $display("\033[0;34mPASS PATTERN NO.%4d,\033[m \033[0;32mexecution cycle : %3d\033[m",n ,latency+1);
    end

    YOU_PASS_task;
    $finish;
end

task reset_task; 
begin 
    rst_n = 'b1;
    in_valid = 'b0;
    in0 = 'bx;
    in1 = 'bx;
    in2 = 'bx;
    in3 = 'bx;
    in4 = 'bx;
    in5 = 'bx;
    in6 = 'bx;
    in7 = 'bx;
    guy = 'bx;

    force clk = 0;

    #CYCLE; rst_n = 0; 
    #CYCLE; rst_n = 1;
    
    if(out_valid !== 1'b0 || out !=='b0)  //out!==0
    begin
        $display("************************************************************");   
        $display("                     SPEC 3 IS FAIL!                        ");   
        $display("*  Output signal should be 0 after initial RESET  at %8t   *",$time);
        $display("************************************************************");
        //repeat(2) #CYCLE;
        $finish;
    end
    
	#CYCLE; release clk;
end 
endtask

task create_map_task;
begin
    
    for(i=0; i<64; i=i+1)
    begin
        for (j=0; j<8; j=j+1) 
        begin
            map[i][j] = 0;
        end
    end 

    guy_tmp = $urandom(SEED) % 8;

    map[0][0] = 0; map[0][1] = 0; map[0][2] = 0; map[0][3] = 0;
    map[0][4] = 0; map[0][5] = 0; map[0][6] = 0; map[0][7] = 0;

    for(k=0; k<63; k=k)
    begin
        if(k == 0)
            obstacle_position = guy_tmp;
        else
            obstacle_position = rand_position;//map[k][rand_position];

        rand_position = $urandom(SEED) % 8;

        if(obstacle_position > rand_position)
            position_diff = obstacle_position - rand_position;
        else
            position_diff = rand_position - obstacle_position;
        
        obstacle_state = $urandom(SEED) % (2);
        
        if(obstacle_state === 1'b0)  //low obstacles
        begin
            if(position_diff <= 1)
                obstacle_cycle = k + 2;
            else
                obstacle_cycle = k + 1 + position_diff;
        end
        else if(obstacle_state === 1'b1) //high obstacles
        begin
            if(position_diff <= 2)
                obstacle_cycle = k + 2;
            else
                obstacle_cycle = k + position_diff;
        end 

        obstacle_cycle = obstacle_cycle + $urandom(SEED) % (10);

        if(obstacle_cycle <= 63)
        begin
            for(k=k; k<obstacle_cycle; k=k)
            begin
                k = k + 1;
                if(k != obstacle_cycle)
                begin
                    map[k][0] = 0; map[k][1] = 0; map[k][2] = 0; map[k][3] = 0;
                    map[k][4] = 0; map[k][5] = 0; map[k][6] = 0; map[k][7] = 0;
                end
                else
                begin
                    map[k][0] = 3; map[k][1] = 3; map[k][2] = 3; map[k][3] = 3;
                    map[k][4] = 3; map[k][5] = 3; map[k][6] = 3; map[k][7] = 3;
                    
                    if(obstacle_state === 1'b0)
                        map[k][rand_position] = 2'b01;
                    else
                        map[k][rand_position] = 2'b10;
                end
            end
        end
        else
        begin
            for(k=k; k<63; k=k)
            begin
                k = k + 1;
                map[k][0] = 0; map[k][1] = 0; map[k][2] = 0; map[k][3] = 0;
                map[k][4] = 0; map[k][5] = 0; map[k][6] = 0; map[k][7] = 0;
            end
        end
        SEED = $urandom(SEED);
    end
end
endtask

task input_task; 
begin
    
    t = $urandom_range(3, 5);
	repeat(t) @(negedge clk);
	in_valid = 1'b1;
    
    for(l=0; l<64; l=l+1)
    begin
        if(l == 0)
            guy = guy_tmp;
        else
            guy = 'bx;
        
        in0 = map[l][0]; in1 = map[l][1]; in2 = map[l][2]; in3 = map[l][3];
        in4 = map[l][4]; in5 = map[l][5]; in6 = map[l][6]; in7 = map[l][7];
        check_out_reset_task;
        check_in_out_valid_task;
        @(negedge clk);
    end

    in_valid = 1'b0;
	in0 = 'bx; in1 = 'bx; in2 = 'bx; in3 = 'bx;
    in4 = 'bx; in5 = 'bx; in6 = 'bx; in7 = 'bx;
    
end 
endtask 

task check_out_reset_task;
begin
    if(out_valid === 1'b0 && out !== 'b0)
    begin
        $display("************************************************************");   
        $display("                     SPEC 4 IS FAIL!                        ");   
        $display("*  The out should be reset when out_valid is LOW  at %8t   *",$time);
        $display("************************************************************");
        //repeat(2) #CYCLE;
        $finish;
    end
end
endtask

task check_in_out_valid_task;
begin
    if(in_valid === 1'b1 && out_valid !== 1'b0)
    begin
        $display("************************************************************");   
        $display("                     SPEC 5 IS FAIL!                        ");   
        $display("*Out_valid should not be high when in_valid is high  at %8t *",$time);
        $display("************************************************************");
        //repeat(2) #CYCLE;
        $finish;
    end
end
endtask

task wait_out_valid_task; 
begin
    latency = -1;
    while(out_valid !== 1'b1) 
    begin
        latency = latency + 1;
        check_out_reset_task;
        if( latency == 3000) 
        begin
            $display("********************************************************");     
            $display("                    SPEC 6 IS FAIL!                     ");
            $display("*  The execution latency is over 3000 cycles  at %8t   *",$time);//over max
            $display("********************************************************");
            //repeat(2)@(negedge clk);
            $finish;
        end
        @(negedge clk);
   end
end 
endtask

task result_task;
begin 
    m = 0;
    latency2 = -1;
    out_position = guy_tmp;
    vertical_position = 0;
    while(out_valid === 1'b1)
    begin
        out_tmp[m] = out;
        if(out === RIGHT)
            out_position = out_position + 1;
        else if(out === LEFT)
            out_position = out_position - 1;
        if(out === JUMP)
            vertical_position = vertical_position + 1;
        else if(vertical_position > 0)
            vertical_position = vertical_position - 1;

        latency2 = latency2 + 1;
        if( latency2 > 62) 
        begin
            $display("********************************************************");     
            $display("                    SPEC 7 IS FAIL!                     ");
            $display("*   The execution latency is over 63 cycles  at %8t    *",$time);//over max
            $display("********************************************************");
            //repeat(2)@(negedge clk);
            $finish;
        end

        SPEC8_3_task;
        SPEC8_2_task;
        SPEC8_1_task;

        m = m + 1;
        #CYCLE;
    end
    check_out_reset_task;
    if( latency2 != 62) 
    begin
        $display("********************************************************");     
        $display("                    SPEC 7 IS FAIL!                     ");
        $display("* The execution latency is less than 63 cycles  at %8t *",$time);//over max
        $display("********************************************************");
        //repeat(2)@(negedge clk);
        $finish;
    end

end
endtask

task SPEC8_1_task;
begin
    if(map[m+1][out_position] == FULL_OBSTACLES || out_position < 0 || out_position > 7)
    begin
        $display("************************************************************");   
        $display("                    SPEC 8-1 IS FAIL!                       ");   
        $display("*The guy hits the obstacles or leaves the platform  at %8t *",$time);
        $display("************************************************************");
        $finish;
    end
    else if(map[m+1][out_position] === LOW_PLACES && vertical_position == 0)
    begin
        $display("************************************************************");   
        $display("                    SPEC 8-1 IS FAIL!                       ");   
        $display("*The guy hits the obstacles or leaves the platform  at %8t *",$time);
        $display("************************************************************");
        $finish;
    end
    else if(map[m+1][out_position] === HIGH_PLACES && vertical_position == 1)
    begin
        $display("************************************************************");   
        $display("                    SPEC 8-1 IS FAIL!                       ");   
        $display("*The guy hits the obstacles or leaves the platform  at %8t *",$time);
        $display("************************************************************");
        $finish;
    end
end
endtask

task SPEC8_2_task;
begin
    if(m>=2 && out_tmp[m-2] == JUMP && map[m-2][out_position] == LOW_PLACES && map[m][out_position] == NO_OBSTACLES)
    begin
        if(out != STOP)
        begin
            $display("************************************************************");   
            $display("                    SPEC 8-2 IS FAIL!                       ");   
            $display("*           The guy jumps from high to low place,          *");
            $display("*        so the out must be 2'b00 for 2 cycles   at %8t    *",$time);
            $display("************************************************************");
            $finish;
        end
    end
    else if(m>=1 && out_tmp[m-1] == JUMP && map[m-1][out_position] == LOW_PLACES && map[m][out_position] == NO_OBSTACLES && map[m+1][out_position] == NO_OBSTACLES)
    begin
        if(out != STOP)
        begin
            $display("************************************************************");   
            $display("                    SPEC 8-3 IS FAIL!                       ");   
            $display("*             The guy jumps to the same height,            *");
            $display("*        so the out must be 2'b00 for 1 cycles   at %8t    *",$time);
            $display("************************************************************");
            $finish;
        end
    end
end
endtask

task SPEC8_3_task;
begin
    if(m>=1 && out_tmp[m-1] == JUMP && map[m-1][out_position] == LOW_PLACES && map[m][out_position] == NO_OBSTACLES && map[m+1][out_position] != NO_OBSTACLES)
    begin
        if(out != STOP)
        begin
            $display("************************************************************");   
            $display("                    SPEC 8-3 IS FAIL!                       ");   
            $display("*             The guy jumps to the same height,            *");
            $display("*        so the out must be 2'b00 for 1 cycles   at %8t    *",$time);
            $display("************************************************************");
            $finish;
        end
    end
end
endtask

task YOU_PASS_task; 
begin
    $display ("--------------------------------------------------------------------");
    $display ("                         Congratulations!                           ");
    $display ("                   You have passed the pattern!                     ");
    $display ("--------------------------------------------------------------------");        
    repeat(2)@(negedge clk);
    $finish;
end 
endtask

endmodule

