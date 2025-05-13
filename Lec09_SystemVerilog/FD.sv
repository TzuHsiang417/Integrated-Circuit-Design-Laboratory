module FD(input clk, INF.FD_inf inf);
import usertype::*;

//===========================================================================
// parameter 
//===========================================================================


//===========================================================================
// logic 
//===========================================================================
Action mode;
Restaurant_id restaurant_id;
Delivery_man_id delivery_id;
Ctm_Info customer_info;
food_ID_servings food_id;

//dram
Dram_data delivery_dram, restaurant_dram;


//err_msg
logic Deliver_man_busy;
logic Res_no_food;
logic Restaurant_busy;
logic No_cus;
logic Wr_cancel;
logic Wr_res_ID;
logic Wr_food_ID;
Error_Msg err_type;

logic[9:0] total_food;

//valid
logic id_get, res_get, food_get, cus_get;

//check C_in_valid
logic check_C_in_valid;
logic and_C_in_valid;

//output
logic output_ok;

//================================================================
//   FSM
//================================================================
STATE_FSM c_state, n_state;

always_ff @(posedge clk or negedge inf.rst_n)
begin
    if(!inf.rst_n)
        c_state <= S_STANDBY;
    else
        c_state <= n_state;
end

always_comb
begin
    case(c_state)
        S_STANDBY:          if(inf.act_valid)
                            begin
                                if(inf.D.d_act[0] == Take)          n_state = S_TAKE;
                                else if(inf.D.d_act[0] == Deliver)  n_state = S_DELIVER;
                                else if(inf.D.d_act[0] == Order)    n_state = S_ORDER;
                                else if(inf.D.d_act[0] == Cancel)   n_state = S_CANCEL;
                                else n_state = S_STANDBY;
                            end
                            else n_state = S_STANDBY;
        S_TAKE:             if(inf.id_valid)                        n_state = S_Take_read_D;
                            else if(inf.cus_valid)                  n_state = S_Take_read_R;
                            else                                    n_state = S_TAKE;
		S_ORDER:            if(inf.res_valid)                       n_state = S_Order_read_R;
                            else if(inf.food_valid)                 n_state = S_res_busy;
                            else                                    n_state = S_ORDER; 
		S_DELIVER:          if(inf.id_valid)                        n_state = S_Deliver_read_D;
                            else                                    n_state = S_DELIVER; 
		S_CANCEL:           if(inf.res_valid)                       n_state = S_Cancel_read_R;
                            else                                    n_state = S_CANCEL;
////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                  TAKE
////////////////////////////////////////////////////////////////////////////////////////////////////////////
		S_Take_read_D:      if(inf.C_out_valid)                     n_state = S_Take_wait_R;
                            else                                    n_state = S_Take_read_D;
        S_Take_wait_R:      if(restaurant_id == delivery_id && cus_get)   n_state = S_deli_busy;
                            else if(cus_get)                        n_state = S_Take_read_R;
                            else                                    n_state = S_Take_wait_R;
		S_Take_read_R:      if(inf.C_out_valid)                     n_state = S_deli_busy;
                            else                                    n_state = S_Take_read_R;
        S_deli_busy:        if(Deliver_man_busy)                    n_state = S_err;
                            else                                    n_state = S_no_food;
        S_no_food:          if(Res_no_food)                         n_state = S_err;
                            else                                    n_state = S_take_cal;
        S_take_cal:         if(restaurant_id == delivery_id)        n_state = S_take_same_id;
                            else                                    n_state = S_Take_write_D;
        S_take_same_id:                                             n_state = S_Take_write_R;
		S_Take_write_D:     if(inf.C_out_valid)                     n_state = S_Take_write_R;
                            else                                    n_state = S_Take_write_D;
		S_Take_write_R:     if(inf.C_out_valid)                     n_state = S_Output;
                            else                                    n_state = S_Take_write_R;

////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                  ORDER
////////////////////////////////////////////////////////////////////////////////////////////////////////////
		S_Order_read_R:     if(inf.C_out_valid)                     n_state = S_res_busy;
                            else                                    n_state = S_Order_read_R;
        S_res_busy:         if(Restaurant_busy && food_get)         n_state = S_err;
                            else if(food_get)                       n_state = S_order_cal;
                            else                                    n_state = S_res_busy;
        S_order_cal:                                                n_state = S_Order_write_R;
		S_Order_write_R:    if(inf.C_out_valid)                     n_state = S_Output;
                            else                                    n_state = S_Order_write_R; 

////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                  DELIVER
////////////////////////////////////////////////////////////////////////////////////////////////////////////
		S_Deliver_read_D:   if(inf.C_out_valid)                     n_state = S_no_ctm;
                            else                                    n_state = S_Deliver_read_D;
        S_no_ctm:           if(No_cus)                              n_state = S_err;
                            else                                    n_state = S_deli_cal;
        S_deli_cal:                                                 n_state = S_Deliver_write_D;
		S_Deliver_write_D:  if(inf.C_out_valid)                     n_state = S_Output;
                            else                                    n_state = S_Deliver_write_D;

////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                  CANCEL
////////////////////////////////////////////////////////////////////////////////////////////////////////////
		S_Cancel_read_R:    if(inf.C_out_valid)                     n_state = S_Cancel_same_id;
                            else                                    n_state = S_Cancel_read_R;
        S_Cancel_same_id:   if(restaurant_id == delivery_id && id_get) n_state = S_wrong_cancel;
                            else if(id_get)                         n_state = S_Cancel_read_D;
                            else                                    n_state = S_Cancel_same_id;
		S_Cancel_read_D:    if(inf.C_out_valid)                     n_state = S_wrong_cancel;
                            else                                    n_state = S_Cancel_read_D;
        S_wrong_cancel:     if(Wr_cancel || Wr_food_ID || Wr_res_ID)n_state = S_err;
                            else                                    n_state = S_cancel_cal;
        S_cancel_cal:                                               n_state = S_Cancel_write_D;
		S_Cancel_write_D:   if(inf.C_out_valid)                     n_state = S_Output;
                            else                                    n_state = S_Cancel_write_D;

////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                  OUTPUT
////////////////////////////////////////////////////////////////////////////////////////////////////////////
        S_Output:           if(output_ok)                           n_state = S_STANDBY;
                            else                                    n_state = S_Output;
        S_err:              if(output_ok)                           n_state = S_STANDBY;
                            else                                    n_state = S_Output;

        default:    n_state = S_STANDBY;
	endcase
end

//================================================================
//   INPUT circuit
//================================================================

always_ff @(posedge clk or negedge inf.rst_n)
begin
    if(!inf.rst_n)
        mode <= No_action;
    else if(inf.act_valid)
        mode <= inf.D.d_act[0];
    else
        mode <= mode;
end

always_ff @(posedge clk or negedge inf.rst_n)
begin
    if(!inf.rst_n)
        restaurant_id <= 0;
    else if(inf.res_valid)
        restaurant_id <= inf.D.d_res_id[0];
    else if(inf.cus_valid)
        restaurant_id <= inf.D.d_ctm_info[0].res_ID;
    else
        restaurant_id <= restaurant_id;
end

always_ff @(posedge clk or negedge inf.rst_n)
begin
    if(!inf.rst_n)
        delivery_id <= 0;
    else if(inf.id_valid)
        delivery_id <= inf.D.d_id[0];
    else
        delivery_id <= delivery_id;
end

always_ff @(posedge clk or negedge inf.rst_n)
begin
    if(!inf.rst_n)
        customer_info <= 0;
    else if(inf.cus_valid)
        customer_info <= inf.D.d_ctm_info[0];
    else
        customer_info <= customer_info;
end

always_ff @(posedge clk or negedge inf.rst_n)
begin
    if(!inf.rst_n)
        food_id <= 0;
    else if(inf.food_valid)
        food_id <= inf.D.d_food_ID_ser[0];
    else
        food_id <= food_id;
end

//================================================================
//   get INPUT from DRAM and CALCULATION
//================================================================

always_ff @(posedge clk or negedge inf.rst_n)
begin
    if(!inf.rst_n)
        delivery_dram <= 0;
    else if((c_state == S_Take_read_D || c_state == S_Deliver_read_D || c_state == S_Cancel_read_D) && inf.C_out_valid)
        delivery_dram <= {inf.C_data_r[7:0], inf.C_data_r[15:8], inf.C_data_r[23:16], inf.C_data_r[31:24], inf.C_data_r[39:32], inf.C_data_r[47:40], inf.C_data_r[55:48], inf.C_data_r[63:56]};
    else if(c_state == S_Cancel_same_id && restaurant_id == delivery_id && id_get)
        delivery_dram <= restaurant_dram;
    else if(c_state == S_take_cal)
    begin
        if(customer_info.ctm_status == VIP && delivery_dram.d_del_data.ctm_info1.ctm_status != VIP)
        begin
            delivery_dram.d_del_data.ctm_info1 <= customer_info;
            delivery_dram.d_del_data.ctm_info2 <= delivery_dram.d_del_data.ctm_info1;
        end
        else
        begin
            if(delivery_dram.d_del_data.ctm_info1.ctm_status != None)
                delivery_dram.d_del_data.ctm_info2 <= customer_info;
            else
                delivery_dram.d_del_data.ctm_info1 <= customer_info;
        end
    end
    else if(c_state == S_take_same_id || (c_state == S_STANDBY && restaurant_id == delivery_id))
        delivery_dram.d_res_data <= restaurant_dram.d_res_data;
    else if(c_state == S_deli_cal)
    begin
        delivery_dram.d_del_data.ctm_info1 <= delivery_dram.d_del_data.ctm_info2;
        delivery_dram.d_del_data.ctm_info2 <= 0;
    end
    else if(c_state == S_cancel_cal)
    begin
        if(delivery_dram.d_del_data.ctm_info1.res_ID == restaurant_id && delivery_dram.d_del_data.ctm_info1.food_ID == food_id.d_food_ID && delivery_dram.d_del_data.ctm_info2.res_ID == restaurant_id && delivery_dram.d_del_data.ctm_info2.food_ID == food_id.d_food_ID)
        begin
            delivery_dram.d_del_data.ctm_info1 <= 0;
            delivery_dram.d_del_data.ctm_info2 <= 0;
        end
        else if(delivery_dram.d_del_data.ctm_info1.res_ID == restaurant_id && delivery_dram.d_del_data.ctm_info1.food_ID == food_id.d_food_ID)
        begin
            delivery_dram.d_del_data.ctm_info1 <= delivery_dram.d_del_data.ctm_info2;
            delivery_dram.d_del_data.ctm_info2 <= 0;
        end
        else
            delivery_dram.d_del_data.ctm_info2 <= 0;
    end
    else
        delivery_dram <= delivery_dram;
end

always_ff @(posedge clk or negedge inf.rst_n)
begin
    if(!inf.rst_n)
        restaurant_dram <= 0;
    else if(c_state == S_deli_busy && restaurant_id == delivery_id && cus_get)
        restaurant_dram <= delivery_dram;
    else if((c_state == S_Take_read_R || c_state == S_Order_read_R || c_state == S_Cancel_read_R) && inf.C_out_valid)
        restaurant_dram <= {inf.C_data_r[7:0], inf.C_data_r[15:8], inf.C_data_r[23:16], inf.C_data_r[31:24], inf.C_data_r[39:32], inf.C_data_r[47:40], inf.C_data_r[55:48], inf.C_data_r[63:56]};
    else if(c_state == S_take_cal)
    begin
        case (customer_info.food_ID)
            FOOD1:  restaurant_dram.d_res_data.ser_FOOD1 <= restaurant_dram.d_res_data.ser_FOOD1 - customer_info.ser_food;
            FOOD2:  restaurant_dram.d_res_data.ser_FOOD2 <= restaurant_dram.d_res_data.ser_FOOD2 - customer_info.ser_food;
            FOOD3:  restaurant_dram.d_res_data.ser_FOOD3 <= restaurant_dram.d_res_data.ser_FOOD3 - customer_info.ser_food;
            default:restaurant_dram <= restaurant_dram; 
        endcase
    end
    else if(c_state == S_order_cal)
    begin
        case (food_id.d_food_ID)
            FOOD1:  restaurant_dram.d_res_data.ser_FOOD1 <= restaurant_dram.d_res_data.ser_FOOD1 + food_id.d_ser_food;
            FOOD2:  restaurant_dram.d_res_data.ser_FOOD2 <= restaurant_dram.d_res_data.ser_FOOD2 + food_id.d_ser_food;
            FOOD3:  restaurant_dram.d_res_data.ser_FOOD3 <= restaurant_dram.d_res_data.ser_FOOD3 + food_id.d_ser_food;
            default:restaurant_dram <= restaurant_dram; 
        endcase
    end
    else if(c_state == S_take_same_id || (c_state == S_STANDBY && restaurant_id == delivery_id))
        restaurant_dram.d_del_data <= delivery_dram.d_del_data;
    else
        restaurant_dram <= restaurant_dram;
end

//================================================================
//   OUTPUT to bridge
//================================================================

always_comb
begin
    if(c_state == S_Take_read_D || c_state == S_Take_write_D || c_state == S_Deliver_read_D || c_state == S_Deliver_write_D || c_state == S_Cancel_read_D || c_state == S_Cancel_write_D)
        inf.C_addr = delivery_id;
    else if(c_state == S_Take_read_R || c_state == S_Take_write_R || c_state == S_Order_read_R || c_state == S_Order_write_R || c_state == S_Cancel_read_R)
        inf.C_addr = restaurant_id;
    else
        inf.C_addr = 0;
end

always_comb
begin
    if(c_state == S_Take_write_D || c_state == S_Deliver_write_D || c_state == S_Cancel_write_D)
        inf.C_data_w = {delivery_dram[7:0], delivery_dram[15:8], delivery_dram[23:16], delivery_dram[31:24], delivery_dram[39:32], delivery_dram[47:40], delivery_dram[55:48], delivery_dram[63:56]};
    else if(c_state == S_Take_write_R || c_state == S_Order_write_R)
        inf.C_data_w = {restaurant_dram[7:0], restaurant_dram[15:8], restaurant_dram[23:16], restaurant_dram[31:24], restaurant_dram[39:32], restaurant_dram[47:40], restaurant_dram[55:48], restaurant_dram[63:56]};
    else
        inf.C_data_w = 0;
end

always_ff @(posedge clk or negedge inf.rst_n)
begin
    if(!inf.rst_n)
        inf.C_in_valid <= 0;
    else if((c_state == S_Take_read_D || c_state == S_Take_write_D || c_state == S_Deliver_read_D || c_state == S_Deliver_write_D || c_state == S_Cancel_write_D
            || c_state == S_Take_write_R || c_state == S_Order_read_R || c_state == S_Order_write_R || c_state == S_Cancel_read_R || c_state == S_Take_read_R || c_state == S_Cancel_read_D) /*&& !check_C_in_valid*/)
        inf.C_in_valid <= and_C_in_valid;
    else
        inf.C_in_valid <= 0;
end

always_ff @(posedge clk or negedge inf.rst_n)
begin
    if(!inf.rst_n)
        check_C_in_valid <= 0;
    else if(inf.C_out_valid)
        check_C_in_valid <= 0;
    else if(inf.C_in_valid)
        check_C_in_valid <= 1;
    else
        check_C_in_valid <= check_C_in_valid;
end

assign and_C_in_valid = (!inf.C_in_valid) & (!check_C_in_valid);

always_comb
begin
    if(c_state == S_Take_read_D || c_state == S_Take_read_R || c_state == S_Order_read_R || c_state == S_Deliver_read_D || c_state == S_Cancel_read_R || c_state == S_Cancel_read_D)
        inf.C_r_wb = 1;
    else
        inf.C_r_wb = 0;
end

//================================================================
//   err checking
//================================================================

assign Deliver_man_busy = (delivery_dram.d_del_data.ctm_info1.ctm_status != None && delivery_dram.d_del_data.ctm_info2.ctm_status != None);
always_comb
begin
    if(customer_info.food_ID == FOOD1 && customer_info.ser_food > restaurant_dram.d_res_data.ser_FOOD1)
        Res_no_food = 1;
    else if(customer_info.food_ID == FOOD2 && customer_info.ser_food > restaurant_dram.d_res_data.ser_FOOD2)
        Res_no_food = 1;
    else if(customer_info.food_ID == FOOD3 && customer_info.ser_food > restaurant_dram.d_res_data.ser_FOOD3)
        Res_no_food = 1;
    else
        Res_no_food = 0;
end

always_ff @(posedge clk or negedge inf.rst_n) 
begin
    if(!inf.rst_n)
        err_type <= No_Err;
    else if(c_state == S_STANDBY)
        err_type <= No_Err;
    else if(c_state == S_deli_busy && Deliver_man_busy)
        err_type <= D_man_busy;
    else if(c_state == S_no_food && Res_no_food)
        err_type <= No_Food;
    else if(c_state == S_res_busy && Restaurant_busy)
        err_type <= Res_busy;
    else if(c_state == S_no_ctm && No_cus)
        err_type <= No_customers;
    else if(c_state == S_wrong_cancel && Wr_cancel)
        err_type <= Wrong_cancel;
    else if(c_state == S_wrong_cancel && Wr_res_ID)
        err_type <= Wrong_res_ID;
    else if(c_state == S_wrong_cancel && Wr_food_ID)
        err_type <= Wrong_food_ID;
    else
        err_type <= err_type;
end

//assign Restaurant_busy = (restaurant_dram.d_res_data.ser_FOOD1 + restaurant_dram.d_res_data.ser_FOOD2 + restaurant_dram.d_res_data.ser_FOOD3 + food_id.d_ser_food > restaurant_dram.d_res_data.limit_num_orders);
always_comb
begin
    if(total_food > restaurant_dram.d_res_data.limit_num_orders)
        Restaurant_busy = 1;
    else
        Restaurant_busy = 0;
end

assign total_food = (restaurant_dram.d_res_data.ser_FOOD1 + restaurant_dram.d_res_data.ser_FOOD2) + (restaurant_dram.d_res_data.ser_FOOD3 + food_id.d_ser_food);

assign No_cus = (delivery_dram.d_del_data.ctm_info1.ctm_status == None && delivery_dram.d_del_data.ctm_info2.ctm_status == None);

assign Wr_cancel = (delivery_dram.d_del_data.ctm_info1.ctm_status == None && delivery_dram.d_del_data.ctm_info2.ctm_status == None);
//assign Wr_res_ID = (delivery_dram.d_del_data.ctm_info1.res_ID != restaurant_id && delivery_dram.d_del_data.ctm_info2.res_ID != restaurant_id);
always_comb
begin
    if((delivery_dram.d_del_data.ctm_info1.res_ID != restaurant_id || delivery_dram.d_del_data.ctm_info1.ctm_status == None) && (delivery_dram.d_del_data.ctm_info2.res_ID != restaurant_id || delivery_dram.d_del_data.ctm_info2.ctm_status == None))
        Wr_res_ID = 1;
    else
        Wr_res_ID = 0;
end

always_comb
begin
    if(((delivery_dram.d_del_data.ctm_info1.res_ID != restaurant_id || delivery_dram.d_del_data.ctm_info1.food_ID != food_id.d_food_ID) || delivery_dram.d_del_data.ctm_info1.ctm_status == None) 
        && ((delivery_dram.d_del_data.ctm_info2.res_ID != restaurant_id || delivery_dram.d_del_data.ctm_info2.food_ID != food_id.d_food_ID) || delivery_dram.d_del_data.ctm_info2.ctm_status == None))
        Wr_food_ID = 1;
    else
        Wr_food_ID = 0;
end
//================================================================
//   VALID checking
//================================================================

always_ff @(posedge clk or negedge inf.rst_n)
begin
    if(!inf.rst_n)
        id_get <= 0;
    else if(c_state == S_STANDBY)
        id_get <= 0;
    else if(inf.id_valid)
        id_get <= 1;
    else
        id_get <= id_get;
end

always_ff @(posedge clk or negedge inf.rst_n)
begin
    if(!inf.rst_n)
        res_get <= 0;
    else if(c_state == S_STANDBY)
        res_get <= 0;
    else if(inf.res_valid)
        res_get <= 1;
    else
        res_get <= res_get;
end

always_ff @(posedge clk or negedge inf.rst_n)
begin
    if(!inf.rst_n)
        food_get <= 0;
    else if(c_state == S_STANDBY)
        food_get <= 0;
    else if(inf.food_valid)
        food_get <= 1;
    else
        food_get <= food_get;
end

always_ff @(posedge clk or negedge inf.rst_n)
begin
    if(!inf.rst_n)
        cus_get <= 0;
    else if(c_state == S_STANDBY)
        cus_get <= 0;
    else if(inf.cus_valid)
        cus_get <= 1;
    else
        cus_get <= cus_get;
end

//================================================================
//   OUTPUT circuit
//================================================================
always_ff @(posedge clk or negedge inf.rst_n)
begin
    if(!inf.rst_n)
        inf.out_valid <= 0;
    else if((c_state == S_Output || c_state == S_err) && output_ok)
        inf.out_valid <= 1;
    else
        inf.out_valid <= 0;
end

always_ff @(posedge clk or negedge inf.rst_n)
begin
    if(!inf.rst_n)
        inf.complete <= 0;
    else if(c_state == S_err && output_ok)
        inf.complete <= 0;
    else
        inf.complete <= 1;
end

always_ff @(posedge clk or negedge inf.rst_n)
begin
    if(!inf.rst_n)
        inf.err_msg <= 0;
    else if(c_state == S_err && output_ok)
        inf.err_msg <= err_type;
    else
        inf.err_msg <= No_Err;
end

always_ff @(posedge clk or negedge inf.rst_n)
begin
    if(!inf.rst_n)
        inf.out_info <= 0;
    else if(c_state == S_Output && output_ok)
    begin
        if(mode == Take)
            inf.out_info <= {delivery_dram.d_del_data, restaurant_dram.d_res_data};
        else if(mode == Deliver)
            inf.out_info <= {delivery_dram.d_del_data, 32'd0};
        else if(mode == Order)
            inf.out_info <= {32'd0, restaurant_dram.d_res_data};
        else
            inf.out_info <= {delivery_dram.d_del_data, 32'd0};
    end
    else
        inf.out_info <= 0;
end

always_comb
begin
    if((mode == Take && cus_get) || (mode == Deliver && id_get) || (mode == Order && food_get) || (mode == Cancel && id_get))
        output_ok = 1;
    else
        output_ok = 0;
end

endmodule