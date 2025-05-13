`include "../00_TESTBED/pseudo_DRAM.sv"
`include "Usertype_FD.sv"

`define CYCLE_TIME 1.0

program automatic PATTERN(input clk, INF.PATTERN inf);
import usertype::*;

//========================================================================================================================================================
// PARAMETER
//========================================================================================================================================================
integer SEED = 60;
parameter start_Addr = 65536;

//========================================================================================================================================================
// INTEGER
//========================================================================================================================================================
integer i, j, k, m, n, p;
integer act_choose;
integer take_choose, deli_choose, order_choose, cancel_choose;
integer locked;
integer set_delay;
integer pattern_no;
integer if_needed;

//========================================================================================================================================================
// VARIABLE
//========================================================================================================================================================
logic [7:0] golden_DRAM [(start_Addr+0):((start_Addr+256*8)-1)];
Action golden_action;
Delivery_man_id golden_deli_id;
Restaurant_id golden_res_id;
logic [255:0] id_used;
logic[9:0] total_food;

res_info golden_res_info;
D_man_Info golden_deli_info;
Ctm_Info golden_ctm_info;
Error_Msg golden_err;
logic golden_complete;
logic [63:0] golden_out_info;
food_ID_servings golden_food;

logic [10:0] num_complete [1:0];
logic [4:0] num_err [6:0];

//========================================================================================================================================================
// CLASS
//========================================================================================================================================================
class rand_cus_status;
    rand Customer_status status;
    function new(int seed);
        this.srandom(seed);
    endfunction //new()
    constraint limit{status inside{Normal, VIP};}
endclass //rand_cus_status

class rand_food_id;
    rand Food_id food;
    function new(int seed);
        this.srandom(seed);
    endfunction //new()
    constraint limit{food inside{FOOD1, FOOD2, FOOD3};}
endclass //rand_food_id

rand_cus_status r_cus_status = new(SEED);
rand_food_id r_food_id = new(SEED);

initial 
begin
    $readmemh("../00_TESTBED/DRAM/dram.dat", golden_DRAM);

    init_integer_task;
    reset_task;

    for(i=0; i<10; i++)
    begin
        if(act_choose == 17) act_choose = 1;
        
        for(act_choose = act_choose; act_choose < 17; act_choose++)
        begin
            case(act_choose)
                0:  golden_action = Take;
                1:  golden_action = Take;
                2:  golden_action = Order;
                3:  golden_action = Take;
                4:  golden_action = Deliver;
                5:  golden_action = Take;
                6:  golden_action = Cancel;
                7:  golden_action = Order;
                8:  golden_action = Order;
                9:  golden_action = Deliver;
                10: golden_action = Order;
                11: golden_action = Cancel;
                12: golden_action = Deliver;
                13: golden_action = Deliver;
                14: golden_action = Cancel;
                15: golden_action = Cancel;
                16: golden_action = Take;
            endcase

            case(golden_action)
                Take:begin
                    take_choose = $urandom(SEED) % 4;
                    if(take_choose == 0 || take_choose == 1)
                        take_task;
                    else if(take_choose == 2)
                        take_d_man_busy_task;
                    else
                        take_no_food_task;
                end
                Order:begin
                    order_choose = $urandom(SEED) % 3;
                    if(order_choose == 0 || order_choose == 1)
                        order_task;
                    else
                        order_res_busy_task;
                end
                Deliver:begin
                    deli_choose = $urandom(SEED) % 3;
                    if(deli_choose == 0 || deli_choose == 1)
                        deliver_task;
                    else
                        deliver_no_cus_task;
                end
                Cancel:begin
                    cancel_choose = $urandom(SEED) % 5;
                    if(cancel_choose == 0 || cancel_choose == 1)
                        cancel_task;
                    else if(cancel_choose == 2)
                        cancel_wrong_cancel_task;
                    else if(cancel_choose == 3)
                        cancel_wrong_food_id_task;
                    else
                        cancel_wrong_res_id_task;
                end
            endcase
            SEED = $urandom(SEED); 
        end
    end

    locked = 1;

    while(id_used != 256'hffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff)
    begin
        act_choose = 0;
        while(id_used[act_choose] != 0)
        begin
            act_choose++;
        end

        if(act_choose >= 0 && act_choose <= 43)
            take_task;
        else if(act_choose >= 44 && act_choose <= 63)
            take_d_man_busy_task;
        else if(act_choose >= 64 && act_choose <= 83)
            take_no_food_task;
        else if(act_choose >= 84 && act_choose <= 128)
            deliver_task;
        else if(act_choose >= 129 && act_choose <= 148)
            deliver_no_cus_task;
        else if(act_choose >= 149 && act_choose <= 193)
            cancel_task;
        else if(act_choose >= 194 && act_choose <= 213)
            cancel_wrong_cancel_task;
        else if(act_choose >= 214 && act_choose <= 233)
            cancel_wrong_res_id_task;
        else if(act_choose >= 234 && act_choose <= 255)
            cancel_wrong_food_id_task;
    end

    locked = 2;

    take_task;
    if_needed = 1;
    take_task;
    take_task;
    take_task;
    take_task;

    if_needed = 0;

    order_task;
    if_needed = 1;
    order_task;
    order_task;
    order_task;
    order_task;

    if_needed = 0;

    while(num_err[0] < 22)
    begin
        take_no_food_task;
    end

    while(num_err[1] < 22)
    begin
        take_d_man_busy_task;
    end

    while(num_err[2] < 22)
    begin
        deliver_no_cus_task;
    end

    while(num_err[3] < 22)
    begin
        order_res_busy_task;
    end

    while(num_err[4] < 22)
    begin
        cancel_wrong_cancel_task;
    end

    while(num_err[5] < 22)
    begin
        cancel_wrong_res_id_task;
    end

    while(num_err[6] < 22)
    begin
        cancel_wrong_food_id_task;
    end

    while(num_complete[1] < 200) 
    begin
        act_choose = $urandom(SEED) % 4;

        case(act_choose)
            0:  take_task;
            1:  order_task;
            2:  deliver_task;
            3:  cancel_task;
        endcase
    end

    while(num_complete[0] < 200) 
    begin
        act_choose = $urandom(SEED) % 7;

        case(act_choose)
            0:  take_d_man_busy_task;
            1:  order_res_busy_task;
            2:  deliver_no_cus_task;
            3:  cancel_wrong_cancel_task;
            4:  take_no_food_task;
            5:  cancel_wrong_food_id_task;
            6:  cancel_wrong_res_id_task;
        endcase
    end

    /*$display("********************************************************************");
    $display("                        \033[0;38;5;219mCongratulations!\033[m      ");
    $display("                 \033[0;38;5;219mYou have passed all patterns!\033[m");
    $display("                 \033[0;38;5;219mTotal time: %d \033[m",$time);
    $display("********************************************************************");
    $display("                 \033[0;38;5;219mTotal pattern: %d \033[m",pattern_no);
    $display("                 \033[0;38;5;219mTotal complete: %d \033[m",num_complete[1]);
    $display("                 \033[0;38;5;219mTotal uncomplete: %d \033[m",num_complete[0]);
    $display("********************************************************************");*/


    @(negedge clk);
    $finish;
    
end

task reset_task;
begin
    // reset signal
    inf.rst_n = 1;
    inf.D = 'bx;
    inf.id_valid = 0;
    inf.act_valid = 0;
    inf.res_valid = 0;
    inf.cus_valid = 0;
    inf.food_valid = 0;

    #(2.0); inf.rst_n = 0;
    
    #(1.0);
    /*if(inf.out_valid !== 0 || inf.err_msg !== 0|| inf.complete !== 0 || inf.out_info !== 0)
    begin
        $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
        $display ("                                                                SPEC 3 FAIL!                                                                ");
        $display ("                                   All output signals should be reset after the reset signal is asserted.                                   ");
        $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
        $finish;
    end*/

    #(3.0); inf.rst_n = 1;
end    
endtask

task init_integer_task;
begin
    act_choose = 0;
    id_used = 0;
    locked = 0;
    num_err[0] = 0;
    num_err[1] = 0;
    num_err[2] = 0;
    num_err[3] = 0;
    num_err[4] = 0;
    num_err[5] = 0;
    num_err[6] = 0;

    num_complete[0] = 0;
    num_complete[1] = 0;
    pattern_no = 0;
    if_needed = 0;
end
endtask

task get_deli_info;
begin
    golden_deli_info.ctm_info1 = {golden_DRAM[start_Addr + golden_deli_id * 8 + 4], golden_DRAM[start_Addr + golden_deli_id * 8 + 5]};
    golden_deli_info.ctm_info2 = {golden_DRAM[start_Addr + golden_deli_id * 8 + 6], golden_DRAM[start_Addr + golden_deli_id * 8 + 7]};

    /*$display("************************************************************");
    $display("golden_deli_id = %d", golden_deli_id);
    $display("golden_DRAM[%h] = %h", start_Addr + golden_deli_id * 8 + 4, golden_deli_info);
    $display("%h %h %h %h", golden_DRAM[start_Addr + golden_deli_id * 8 + 0], golden_DRAM[start_Addr + golden_deli_id * 8 + 1], golden_DRAM[start_Addr + golden_deli_id * 8 + 2], golden_DRAM[start_Addr + golden_deli_id * 8 + 3]);
    $display("%h %h %h %h", golden_DRAM[start_Addr + golden_deli_id * 8 + 4], golden_DRAM[start_Addr + golden_deli_id * 8 + 5], golden_DRAM[start_Addr + golden_deli_id * 8 + 6], golden_DRAM[start_Addr + golden_deli_id * 8 + 7]);
    $display("ctm1: %d  %d  %d  %d", golden_deli_info.ctm_info1.ctm_status, golden_deli_info.ctm_info1.res_ID, golden_deli_info.ctm_info1.food_ID, golden_deli_info.ctm_info1.ser_food);
    $display("ctm1: %d  %d  %d  %d", golden_deli_info.ctm_info2.ctm_status, golden_deli_info.ctm_info2.res_ID, golden_deli_info.ctm_info2.food_ID, golden_deli_info.ctm_info2.ser_food);*/
end
endtask

task get_res_info;
begin
    golden_res_info.limit_num_orders = golden_DRAM[start_Addr + golden_res_id * 8];
    golden_res_info.ser_FOOD1 = golden_DRAM[start_Addr + golden_res_id * 8 + 1];
    golden_res_info.ser_FOOD2 = golden_DRAM[start_Addr + golden_res_id * 8 + 2];
    golden_res_info.ser_FOOD3 = golden_DRAM[start_Addr + golden_res_id * 8 + 3];

    /*$display("golden_res_id = %d", golden_res_id);
    $display("golden_DRAM[%h] = %h", start_Addr + golden_res_id * 8, golden_res_info);
    $display("%h %h %h %h", golden_DRAM[start_Addr + golden_res_id * 8 + 0], golden_DRAM[start_Addr + golden_res_id * 8 + 1], golden_DRAM[start_Addr + golden_res_id * 8 + 2], golden_DRAM[start_Addr + golden_res_id * 8 + 3]);
    $display("%h %h %h %h", golden_DRAM[start_Addr + golden_res_id * 8 + 4], golden_DRAM[start_Addr + golden_res_id * 8 + 5], golden_DRAM[start_Addr + golden_res_id * 8 + 6], golden_DRAM[start_Addr + golden_res_id * 8 + 7]);
    $display("limit_of_orders   = %h", golden_res_info.limit_num_orders);
    $display("servings_of_FOOD1 = %h", golden_res_info.ser_FOOD1);
    $display("servings_of_FOOD2 = %h", golden_res_info.ser_FOOD2);
    $display("servings_of_FOOD3 = %h", golden_res_info.ser_FOOD3);*/
end
endtask

task write_back_DRAM_task;
begin
    golden_DRAM[start_Addr + golden_deli_id * 8 + 4] = golden_deli_info.ctm_info1[15:8];
    golden_DRAM[start_Addr + golden_deli_id * 8 + 5] = golden_deli_info.ctm_info1[7:0];
    golden_DRAM[start_Addr + golden_deli_id * 8 + 6] = golden_deli_info.ctm_info2[15:8];
    golden_DRAM[start_Addr + golden_deli_id * 8 + 7] = golden_deli_info.ctm_info2[7:0];

    golden_DRAM[start_Addr + golden_res_id * 8] = golden_res_info.limit_num_orders;
    golden_DRAM[start_Addr + golden_res_id * 8 + 1] = golden_res_info.ser_FOOD1;
    golden_DRAM[start_Addr + golden_res_id * 8 + 2] = golden_res_info.ser_FOOD2;
    golden_DRAM[start_Addr + golden_res_id * 8 + 3] = golden_res_info.ser_FOOD3;
end
endtask

task take_task;
begin
    pattern_no++;
    
    if(locked == 0)
    begin
        do begin
            golden_deli_id = $urandom(SEED) % 44;
            SEED = $urandom(SEED);
        end while(id_used[golden_deli_id] != 0);
    end
    else if(locked == 1)
        golden_deli_id = act_choose;
    else
    begin
        if(if_needed == 1)
            golden_deli_id = golden_deli_id;
        else
            golden_deli_id = $urandom(SEED) % 44;
    end

    id_used[golden_deli_id] = 1;
    golden_res_id = $urandom(SEED) % 76;

    get_deli_info;
    get_res_info;

    r_cus_status.randomize();
    golden_ctm_info.ctm_status = r_cus_status.status;
    golden_ctm_info.res_ID = golden_res_id;
    r_food_id.randomize();
    golden_ctm_info.food_ID = r_food_id.food;
    golden_ctm_info.ser_food = 1;

    operation_delay_task;


    take_operation_task;
    wait_out_valid_task;
    take_out_task;
    write_back_DRAM_task;
    complete_check_task;
    err_check_task;
end
endtask

task take_d_man_busy_task;
begin
    pattern_no++;

    if(locked == 0)
    begin
        do begin
            golden_deli_id = $urandom(SEED) % 20 + 44;
            SEED = $urandom(SEED);
        end while(id_used[golden_deli_id] != 0);
    end
    else if(locked == 1)
        golden_deli_id = act_choose;
    else
    begin
        golden_deli_id = $urandom(SEED) % 20 + 44;
    end

    id_used[golden_deli_id] = 1;
    golden_res_id = $urandom(SEED) % 33 + 76;

    get_deli_info;
    get_res_info;

    r_cus_status.randomize();
    golden_ctm_info.ctm_status = r_cus_status.status;
    golden_ctm_info.res_ID = golden_res_id;
    r_food_id.randomize();
    golden_ctm_info.food_ID = r_food_id.food;
    golden_ctm_info.ser_food = 1;

    operation_delay_task;

    take_operation_task;
    wait_out_valid_task;
    take_out_task;
    write_back_DRAM_task;
    complete_check_task;
    err_check_task;
end
endtask

task take_no_food_task;
begin
    pattern_no++;
    
    if(locked == 0)
    begin
        do begin
            golden_deli_id = $urandom(SEED) % 20 + 64;
            SEED = $urandom(SEED);
        end while(id_used[golden_deli_id] != 0);
    end
    else if(locked == 1)
        golden_deli_id = act_choose;
    else
        golden_deli_id = $urandom(SEED) % 20 + 64;

    id_used[golden_deli_id] = 1;
    golden_res_id = $urandom(SEED) % 41 + 109;

    get_deli_info;
    get_res_info;

    r_cus_status.randomize();
    golden_ctm_info.ctm_status = r_cus_status.status;
    golden_ctm_info.res_ID = golden_res_id;
    r_food_id.randomize();
    golden_ctm_info.food_ID = r_food_id.food;
    if(golden_ctm_info.food_ID == FOOD1)
        golden_ctm_info.ser_food = golden_res_info.ser_FOOD1 + 1;
    else if(golden_ctm_info.food_ID == FOOD2)
        golden_ctm_info.ser_food = golden_res_info.ser_FOOD2 + 1;
    else if(golden_ctm_info.food_ID == FOOD3)
        golden_ctm_info.ser_food = golden_res_info.ser_FOOD3 + 1;

    operation_delay_task;

    take_operation_task;
    wait_out_valid_task;
    take_out_task;
    write_back_DRAM_task;
    complete_check_task;
    err_check_task;
end
endtask

task take_operation_task;
begin
    inf.act_valid = 1;
    inf.D = 0;
    inf.D.d_act[0] = Take;
    @(negedge clk);
    inf.act_valid = 0;
    inf.D = 'bx;

    set_delay_task;

    inf.id_valid = 1;
    inf.D = 0;
    inf.D.d_id[0] = golden_deli_id;
    @(negedge clk);
    inf.id_valid = 0;
    inf.D = 'bx;

    set_delay_task;

    inf.cus_valid = 1;
    inf.D = 0;
    inf.D.d_ctm_info[0] = golden_ctm_info;
    @(negedge clk);
    inf.cus_valid = 0;
    inf.D = 'bx;
end
endtask

task take_out_task;
begin
    golden_err = No_Err;
    golden_out_info = 0;

    if(golden_deli_info.ctm_info1.ctm_status != None && golden_deli_info.ctm_info2.ctm_status != None)
        golden_err = D_man_busy;
    else if(golden_ctm_info.food_ID == FOOD1 && golden_ctm_info.ser_food > golden_res_info.ser_FOOD1)
        golden_err = No_Food;
    else if(golden_ctm_info.food_ID == FOOD2 && golden_ctm_info.ser_food > golden_res_info.ser_FOOD2)
        golden_err = No_Food;
    else if(golden_ctm_info.food_ID == FOOD3 && golden_ctm_info.ser_food > golden_res_info.ser_FOOD3)
        golden_err = No_Food;

    if(golden_err != No_Err)
        golden_complete = 0;
    else
        golden_complete = 1;

    if(golden_complete)
    begin
        if(golden_ctm_info.ctm_status == VIP && golden_deli_info.ctm_info1.ctm_status != VIP)
        begin
            golden_deli_info.ctm_info2 = golden_deli_info.ctm_info1;
            golden_deli_info.ctm_info1 = golden_ctm_info;
        end
        else
        begin
            if(golden_deli_info.ctm_info1.ctm_status != None)
                golden_deli_info.ctm_info2 = golden_ctm_info;
            else
                golden_deli_info.ctm_info1 = golden_ctm_info;
        end

        case(golden_ctm_info.food_ID)
            FOOD1:  golden_res_info.ser_FOOD1 = golden_res_info.ser_FOOD1 - golden_ctm_info.ser_food;
            FOOD2:  golden_res_info.ser_FOOD2 = golden_res_info.ser_FOOD2 - golden_ctm_info.ser_food;
            FOOD3:  golden_res_info.ser_FOOD3 = golden_res_info.ser_FOOD3 - golden_ctm_info.ser_food;
        endcase

        golden_out_info = {golden_deli_info, golden_res_info};
    end

    if((inf.complete!==golden_complete) || (inf.err_msg!==golden_err) || (inf.out_info!==golden_out_info))
    begin
        $display("Wrong Answer");
        $finish;
    end
end
endtask

task order_task;
begin
    pattern_no++;

    if(if_needed == 1)
        golden_res_id = golden_res_id;
    else
        golden_res_id = $urandom(SEED) % 76 + 150;
            
    //golden_res_id = $urandom(SEED) % 76 + 150;
    SEED = $urandom(SEED);

    get_res_info;

    r_food_id.randomize();
    golden_food.d_food_ID = r_food_id.food;
    golden_food.d_ser_food = 1;

    operation_delay_task;

    order_operation_task;
    wait_out_valid_task;
    order_out_task;
    write_back_DRAM_task;
    complete_check_task;
    err_check_task;
end
endtask

task order_res_busy_task;
begin
    pattern_no++;

    golden_res_id = $urandom(SEED) % 30 + 226;
    SEED = $urandom(SEED);

    get_res_info;

    r_food_id.randomize();
    golden_food.d_food_ID = r_food_id.food;
    golden_food.d_ser_food = 100;

    operation_delay_task;

    order_operation_task;
    wait_out_valid_task;
    order_out_task;
    write_back_DRAM_task;
    complete_check_task;
    err_check_task;
end
endtask

task order_operation_task;
begin
    inf.act_valid = 1;
    inf.D = 0;
    inf.D.d_act[0] = Order;
    @(negedge clk);
    inf.act_valid = 0;
    inf.D = 'bx;

    set_delay_task;

    inf.res_valid = 1;
    inf.D = 0;
    inf.D.d_res_id[0] = golden_res_id;
    @(negedge clk);
    inf.res_valid = 0;
    inf.D = 'bx;

    set_delay_task;

    inf.food_valid = 1;
    inf.D = 0;
    inf.D.d_food_ID_ser[0] = golden_food;
    @(negedge clk);
    inf.food_valid = 0;
    inf.D = 'bx;
end
endtask

task order_out_task;
begin
    golden_err = No_Err;
    golden_out_info = 0;

    total_food = (golden_res_info.ser_FOOD1 + golden_res_info.ser_FOOD2) + (golden_res_info.ser_FOOD3 + golden_food.d_ser_food);

    if(total_food > golden_res_info.limit_num_orders)
        golden_err = Res_busy;

    if(golden_err != No_Err)
        golden_complete = 0;
    else
        golden_complete = 1;

    if(golden_complete)
    begin
        case (golden_food.d_food_ID)
            FOOD1:  golden_res_info.ser_FOOD1 = golden_res_info.ser_FOOD1 + golden_food.d_ser_food;
            FOOD2:  golden_res_info.ser_FOOD2 = golden_res_info.ser_FOOD2 + golden_food.d_ser_food;
            FOOD3:  golden_res_info.ser_FOOD3 = golden_res_info.ser_FOOD3 + golden_food.d_ser_food;
        endcase

        golden_out_info = {32'b0, golden_res_info};
    end

    if((inf.complete!==golden_complete) || (inf.err_msg!==golden_err) || (inf.out_info!==golden_out_info))
    begin

        $display("Wrong Answer");
        $finish;
    end
end
endtask

task deliver_task;
begin
    pattern_no++;

    if(locked == 0)
    begin
        do begin
            golden_deli_id = $urandom(SEED) % 45 + 84;
            SEED = $urandom(SEED);
        end while(id_used[golden_deli_id] != 0);
    end
    else if(locked == 1)
        golden_deli_id = act_choose;
    else
        golden_deli_id = $urandom(SEED) % 45 + 84;

    id_used[golden_deli_id] = 1;

    get_deli_info;

    operation_delay_task;

    deli_operation_task;
    wait_out_valid_task;
    deli_out_task;
    write_back_DRAM_task;
    complete_check_task;
    err_check_task;
end
endtask

task deliver_no_cus_task;
begin
    pattern_no++;

    if(locked == 0)
    begin
        do begin
            golden_deli_id = $urandom(SEED) % 20 + 129;
            SEED = $urandom(SEED);
        end while(id_used[golden_deli_id] != 0);
    end
    else if(locked == 1)
        golden_deli_id = act_choose;
    else
        golden_deli_id = $urandom(SEED) % 20 + 129;

    id_used[golden_deli_id] = 1;

    get_deli_info;

    operation_delay_task;

    deli_operation_task;
    wait_out_valid_task;
    deli_out_task;
    write_back_DRAM_task;
    complete_check_task;
    err_check_task;
end
endtask

task deli_operation_task;
begin
    inf.act_valid = 1;
    inf.D = 0;
    inf.D.d_act[0] = Deliver;
    @(negedge clk);
    inf.act_valid = 0;
    inf.D = 'bx;

    set_delay_task;

    inf.id_valid = 1;
    inf.D = 0;
    inf.D.d_id[0] = golden_deli_id;
    @(negedge clk);
    inf.id_valid = 0;
    inf.D = 'bx;
end
endtask

task deli_out_task;
begin
    golden_err = No_Err;
    golden_out_info = 0;

    if(golden_deli_info.ctm_info1.ctm_status == None && golden_deli_info.ctm_info2.ctm_status == None)
        golden_err = No_customers;

    if(golden_err != No_Err)
        golden_complete = 0;
    else
        golden_complete = 1;

    if(golden_complete)
    begin
        golden_deli_info.ctm_info1 = golden_deli_info.ctm_info2;
        golden_deli_info.ctm_info2 = 0;

        golden_out_info = {golden_deli_info, 32'b0};
    end

    if((inf.complete!==golden_complete) || (inf.err_msg!==golden_err) || (inf.out_info!==golden_out_info))
    begin

        $display("Wrong Answer");
        $finish;
    end
end
endtask

task cancel_task;
begin
    pattern_no++;
    if(locked == 0)
    begin
        do begin
            golden_deli_id = $urandom(SEED) % 45 + 149;
            SEED = $urandom(SEED);
        end while(id_used[golden_deli_id] != 0);
    end
    else if(locked == 1)
        golden_deli_id = act_choose;
    else
        golden_deli_id = $urandom(SEED) % 45 + 149;

    id_used[golden_deli_id] = 1;

    get_deli_info;

    m = $urandom(SEED) % 2;

    if(m == 0)
    begin
        golden_res_id = golden_deli_info.ctm_info1.res_ID;
        golden_food.d_food_ID = golden_deli_info.ctm_info1.food_ID;
        golden_food.d_ser_food = 0;
    end
    else
    begin
        if(golden_deli_info.ctm_info2.ctm_status != None)
        begin
            golden_res_id = golden_deli_info.ctm_info2.res_ID;
            golden_food.d_food_ID = golden_deli_info.ctm_info2.food_ID;
            golden_food.d_ser_food = 0;
        end
        else
        begin
            golden_res_id = golden_deli_info.ctm_info1.res_ID;
            golden_food.d_food_ID = golden_deli_info.ctm_info1.food_ID;
            golden_food.d_ser_food = 0;
        end
    end

    get_res_info;

    operation_delay_task;

    cancel_operation_task;
    wait_out_valid_task;
    cancel_out_task;
    write_back_DRAM_task;
    complete_check_task;
    err_check_task;
end
endtask

task cancel_wrong_cancel_task;
begin
    pattern_no++;

    if(locked == 0)
    begin
        do begin
            golden_deli_id = $urandom(SEED) % 20 + 194;
            SEED = $urandom(SEED);
        end while(id_used[golden_deli_id] != 0);
    end
    else if(locked == 1)
        golden_deli_id = act_choose;
    else
        golden_deli_id = $urandom(SEED) % 20 + 194;

    id_used[golden_deli_id] = 1;

    get_deli_info;

    golden_res_id = 87;
    golden_food.d_food_ID = FOOD1;
    golden_food.d_ser_food = 0;

    get_res_info;

    operation_delay_task;

    cancel_operation_task;
    wait_out_valid_task;
    cancel_out_task;
    write_back_DRAM_task;
    complete_check_task;
    err_check_task;
end
endtask

task cancel_wrong_res_id_task;
begin
    pattern_no++;

    if(locked == 0)
    begin
        do begin
            golden_deli_id = $urandom(SEED) % 20 + 214;
            SEED = $urandom(SEED);
        end while(id_used[golden_deli_id] != 0);
    end
    else if(locked == 1)
        golden_deli_id = act_choose;
    else
        golden_deli_id = $urandom(SEED) % 20 + 214;

    id_used[golden_deli_id] = 1;

    get_deli_info;

    m = $urandom(SEED) % 2;

    while(golden_res_id == golden_deli_info.ctm_info1.res_ID || golden_res_id == golden_deli_info.ctm_info1.res_ID)
    begin
        golden_res_id = $urandom(SEED) % 256;
        SEED = $urandom(SEED);
    end 

    golden_food.d_food_ID = FOOD1;
    golden_food.d_ser_food = 0;

    operation_delay_task;

    cancel_operation_task;
    wait_out_valid_task;
    cancel_out_task;
    write_back_DRAM_task;
    complete_check_task;
    err_check_task;
end
endtask

task cancel_wrong_food_id_task;
begin
    pattern_no++;

    if(locked == 0)
    begin
        do begin
            golden_deli_id = $urandom(SEED) % 20 + 214;
            SEED = $urandom(SEED);
        end while(id_used[golden_deli_id] != 0);
    end
    else if(locked == 1)
        golden_deli_id = act_choose;
    else
        golden_deli_id = $urandom(SEED) % 20 + 214;

    id_used[golden_deli_id] = 1;

    get_deli_info;

    m = $urandom(SEED) % 2;

    if(m == 0)
    begin
        golden_res_id = golden_deli_info.ctm_info1.res_ID;
        golden_food.d_ser_food = 0;
    end
    else
    begin
        if(golden_deli_info.ctm_info2.ctm_status != None)
        begin
            golden_res_id = golden_deli_info.ctm_info2.res_ID;
            golden_food.d_ser_food = 0;
        end
        else
        begin
            golden_res_id = golden_deli_info.ctm_info1.res_ID;
            golden_food.d_ser_food = 0;
        end
    end

    get_res_info;

    while(golden_food.d_food_ID == golden_deli_info.ctm_info1.food_ID || golden_food.d_food_ID == golden_deli_info.ctm_info2.food_ID)
    begin
        r_food_id.randomize();
        golden_food.d_food_ID = r_food_id.food;
    end

    operation_delay_task;

    cancel_operation_task;
    wait_out_valid_task;
    cancel_out_task;
    write_back_DRAM_task;
    complete_check_task;
    err_check_task;
end
endtask

task cancel_operation_task;
begin
    inf.act_valid = 1;
    inf.D = 0;
    inf.D.d_act[0] = Cancel;
    @(negedge clk);
    inf.act_valid = 0;
    inf.D = 'bx;

    set_delay_task;

    inf.res_valid = 1;
    inf.D = 0;
    inf.D.d_res_id[0] = golden_res_id;
    @(negedge clk);
    inf.res_valid = 0;
    inf.D = 'bx;

    set_delay_task;

    inf.food_valid = 1;
    inf.D = 0;
    inf.D.d_food_ID_ser[0] = golden_food;
    @(negedge clk);
    inf.food_valid = 0;
    inf.D = 'bx;

    set_delay_task;

    inf.id_valid = 1;
    inf.D = 0;
    inf.D.d_id[0] = golden_deli_id;
    @(negedge clk);
    inf.id_valid = 0;
    inf.D = 'bx;
end
endtask

task cancel_out_task;
begin
    golden_err = No_Err;
    golden_out_info = 0;

    if(golden_deli_info.ctm_info1.ctm_status == None && golden_deli_info.ctm_info2.ctm_status == None)
        golden_err = Wrong_cancel;
    else if((golden_deli_info.ctm_info1.res_ID != golden_res_id || golden_deli_info.ctm_info1.ctm_status == None) && (golden_deli_info.ctm_info2.res_ID != golden_res_id || golden_deli_info.ctm_info2.ctm_status == None))
        golden_err = Wrong_res_ID;
    else if(((golden_deli_info.ctm_info1.res_ID != golden_res_id || golden_deli_info.ctm_info1.food_ID != golden_food.d_food_ID) || golden_deli_info.ctm_info1.ctm_status == None) 
        && ((golden_deli_info.ctm_info2.res_ID != golden_res_id || golden_deli_info.ctm_info2.food_ID != golden_food.d_food_ID) || golden_deli_info.ctm_info2.ctm_status == None))
        golden_err = Wrong_food_ID;

    if(golden_err != No_Err)
        golden_complete = 0;
    else
        golden_complete = 1;

    if(golden_complete)
    begin
        if(golden_deli_info.ctm_info1.res_ID == golden_res_id && golden_deli_info.ctm_info1.food_ID == golden_food.d_food_ID && golden_deli_info.ctm_info2.res_ID == golden_res_id && golden_deli_info.ctm_info2.food_ID == golden_food.d_food_ID)
        begin
            golden_deli_info.ctm_info1 = 0;
            golden_deli_info.ctm_info2 = 0;
        end
        else if(golden_deli_info.ctm_info1.res_ID == golden_res_id && golden_deli_info.ctm_info1.food_ID == golden_food.d_food_ID)
        begin
            golden_deli_info.ctm_info1 = golden_deli_info.ctm_info2;
            golden_deli_info.ctm_info2 = 0;
        end
        else
            golden_deli_info.ctm_info2 = 0;

        golden_out_info = {golden_deli_info, 32'd0};
    end

    

    if((inf.complete!==golden_complete) || (inf.err_msg!==golden_err) || (inf.out_info!==golden_out_info))
    begin

        $display("Wrong Answer");
        $finish;
    end
end
endtask

task set_delay_task;
begin
    set_delay = ($urandom(SEED) % 5) + 1;
    SEED = $urandom(SEED);
    for(j=0; j<1; j++)
        @(negedge clk);
end
endtask

task operation_delay_task;
begin
    set_delay = ($urandom(SEED) % 9) + 2;
    SEED = $urandom(SEED);
    for(k=0; k<2; k++)
        @(negedge clk);
end
endtask

task wait_out_valid_task;
begin
    while(!inf.out_valid)
    begin
        @(negedge clk);
    end
end
endtask

task complete_check_task;
begin
    if(golden_complete == 1)
        num_complete[1]++;
    else
        num_complete[0]++;
end
endtask

task err_check_task;
begin
    if(golden_err == No_Food)
        num_err[0]++;
    else if(golden_err == D_man_busy)
        num_err[1]++;
    else if(golden_err == No_customers)
        num_err[2]++;
    else if(golden_err == Res_busy)
        num_err[3]++;
    else if(golden_err == Wrong_cancel)
        num_err[4]++;
    else if(golden_err == Wrong_res_ID)
        num_err[5]++;
    else if(golden_err == Wrong_food_ID)
        num_err[6]++;
end
endtask

endprogram