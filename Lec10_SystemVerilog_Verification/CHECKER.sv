module Checker(input clk, INF.CHECKER inf);
import usertype::*;

//declare other cover group
//Spec 1
covergroup Specification1 @(posedge clk iff inf.id_valid);
    coverpoint inf.D.d_id[0]{
		option.at_least = 1;
		option.auto_bin_max = 256;
	}
endgroup

//Spec2
covergroup Specification2 @(posedge clk iff inf.act_valid);
    coverpoint inf.D.d_act[0]{
		option.at_least = 10;
		bins t[] = (Take, Order, Deliver, Cancel => Take, Order, Deliver, Cancel);
	}
endgroup

//Spec3
covergroup Specification3 @(negedge clk iff inf.out_valid);
    coverpoint inf.complete{
		option.at_least = 200;
        option.auto_bin_max = 2;
		//bins c[] = {[0:1]};
	}
endgroup

//Spec4
covergroup Specification4 @(negedge clk iff inf.out_valid);
    coverpoint inf.err_msg{
		option.at_least = 20;
		bins e0 = {No_Food};
        bins e1 = {D_man_busy};
        bins e2 = {No_customers};
        bins e3 = {Res_busy};
        bins e4 = {Wrong_cancel};
        bins e5 = {Wrong_res_ID};
        bins e6 = {Wrong_food_ID};
	}
endgroup

Specification1 Spec1 = new();
Specification2 Spec2 = new();
Specification3 Spec3 = new();
Specification4 Spec4 = new();


//************************************ below assertion is to check your pattern ***************************************** 
//                                          Please finish and hand in it
// This is an example assertion given by TA, please write the required assertions below
//  assert_interval : assert property ( @(posedge clk)  inf.out_valid |=> inf.id_valid == 0 [*2])
//  else
//  begin
//  	$display("Assertion X is violated");
//  	$fatal; 
//  end
wire #(0.5) rst_reg = inf.rst_n;
//write other assertions
//========================================================================================================================================================
// Assertion 1 ( All outputs signals (including FD.sv and bridge.sv) should be zero after reset.)
//========================================================================================================================================================
always @(negedge rst_reg) 
begin
	#1;
	assertion1 : assert ((inf.out_valid === 0) && (inf.err_msg === No_Err) && (inf.complete === 0)
                        && (inf.out_info === 0) && (inf.C_addr === 0) && (inf.C_data_w === 0)
                        && (inf.C_in_valid === 0) && (inf.C_r_wb === 0) && (inf.C_out_valid === 0)
                        && (inf.C_data_r === 0) && (inf.AR_VALID === 0) && (inf.AR_ADDR === 0)
                        && (inf.R_READY === 0) && (inf.AW_VALID === 0) && (inf.AW_ADDR === 0)
                        && (inf.W_VALID === 0) && (inf.W_VALID === 0) && (inf.B_READY === 0))
	else 
    begin
		$display("Assertion 1 is violated");
		$fatal; 
	end
end

//========================================================================================================================================================
// Assertion 2 ( If action is completed, err_msg should be 4’b0.)
//========================================================================================================================================================
assertion2 : assert property (@(posedge clk) (inf.complete === 1 && inf.out_valid === 1) |-> (inf.err_msg === No_Err))
else
begin
    $display("Assertion 2 is violated");
 	$fatal; 
end

//========================================================================================================================================================
// Assertion 3 ( If action is not completed, out_info should be 64’b0.)
//========================================================================================================================================================
assertion3 : assert property (@(posedge clk) (inf.complete === 0 && inf.out_valid === 1) |-> (inf.out_info === 0))
else
begin
    $display("Assertion 3 is violated");
 	$fatal;
end

//========================================================================================================================================================
// Assertion 4 ( The gap between each input valid is at least 1 cycle and at most 5 cycles.)
//========================================================================================================================================================
Action mode;
always_ff @(posedge clk or negedge inf.rst_n)  
begin
	if(!inf.rst_n)
        mode <= No_action;
	else if(inf.act_valid==1) 	
        mode <= inf.D.d_act[0];
    else
        mode <= mode;
end

assertion4_take : assert property (@(negedge clk) ((inf.id_valid) && mode === Take) |-> (##1 (inf.cus_valid === 0) ##[1:5] (inf.cus_valid)))
else
begin
    $display("Assertion 4 is violated");
 	$fatal;
end

assertion4_order : assert property (@(negedge clk) ((inf.res_valid) && mode === Order) |-> (##1 (inf.food_valid === 0) ##[1:5] (inf.food_valid)))
else
begin
    $display("Assertion 4 is violated");
 	$fatal;
end

assertion4_cancel : assert property (@(negedge clk) ((inf.res_valid || inf.food_valid) && mode === Cancel) |-> (##1 (inf.food_valid === 0 && inf.id_valid === 0) ##[1:5] (inf.food_valid || inf.id_valid)))
else
begin
    $display("Assertion 4 is violated");
 	$fatal;
end

assertion4_mode : assert property (@(negedge clk) ((inf.act_valid)) |-> (##1 (inf.res_valid === 0 && inf.id_valid === 0 && inf.food_valid === 0 && inf.cus_valid === 0) ##[1:5] (inf.res_valid || inf.id_valid || inf.cus_valid || inf.food_valid)))
else
begin
    $display("Assertion 4 is violated");
 	$fatal;
end

//========================================================================================================================================================
// Assertion 5 ( All input valid signals won’t overlap with each other.)
//========================================================================================================================================================
assertion5_act : assert property (@(negedge clk) inf.act_valid |-> (!inf.id_valid && !inf.res_valid && !inf.cus_valid && !inf.food_valid))
else
begin
	$display("Assertion 5 is violated");
	$fatal; 
end

assertion5_id : assert property (@(negedge clk) inf.id_valid |-> (!inf.act_valid && !inf.res_valid && !inf.cus_valid && !inf.food_valid))
else
begin
	$display("Assertion 5 is violated");
	$fatal; 
end

assertion5_res : assert property (@(negedge clk) inf.res_valid |-> (!inf.id_valid && !inf.act_valid && !inf.cus_valid && !inf.food_valid))
else
begin
	$display("Assertion 5 is violated");
	$fatal; 
end

assertion5_cus : assert property (@(negedge clk) inf.cus_valid |-> (!inf.id_valid && !inf.res_valid && !inf.act_valid && !inf.food_valid))
else
begin
	$display("Assertion 5 is violated");
	$fatal; 
end

assertion5_food : assert property (@(negedge clk) inf.food_valid |-> (!inf.id_valid && !inf.res_valid && !inf.cus_valid && !inf.act_valid))
else
begin
	$display("Assertion 5 is violated");
	$fatal; 
end
//========================================================================================================================================================
// Assertion 6 ( Out_valid can only be high for exactly one cycle.)
//========================================================================================================================================================
assertion6 : assert property (@(posedge clk)  inf.out_valid |=> !inf.out_valid)
else
begin
	$display("Assertion 6 is violated");
	$fatal; 
end

//========================================================================================================================================================
// Assertion 7 ( Next operation will be valid 2-10 cycles after out_valid fall.)
//========================================================================================================================================================
assertion7 :assert property (@(posedge clk) inf.out_valid |-> (inf.act_valid === 0 ##1 inf.act_valid === 0 ##[1:9] inf.act_valid))
else begin
 	$display("Assertion 7 is violated");
 	$fatal; 
end

//========================================================================================================================================================
// Assertion 8 ( Latency should be less than 1200 cycles for each operation.)
//========================================================================================================================================================
/*assertion8 : assert property (@(posedge clk) inf.act_valid |-> ( ##[1:1200] inf.out_valid) )
else
begin
	$display("Assertion 8 is violated");
	$fatal; 
end*/


assertion8_take : assert property (@(posedge clk) ((inf.cus_valid) && mode === Take) |-> ( ##[1:1199] inf.out_valid) )
else
begin
	$display("Assertion 8 is violated");
	$fatal; 
end

assertion8_order : assert property (@(posedge clk) ((inf.food_valid) && mode === Order) |-> ( ##[1:1199] inf.out_valid) )
else
begin
	$display("Assertion 8 is violated");
	$fatal; 
end

assertion8_deli : assert property (@(posedge clk) ((inf.id_valid) && mode === Deliver) |-> ( ##[1:1199] inf.out_valid) )
else
begin
	$display("Assertion 8 is violated");
	$fatal; 
end

assertion8_cancel : assert property (@(posedge clk) ((inf.id_valid) && mode === Cancel) |-> ( ##[1:1199] inf.out_valid) )
else
begin
	$display("Assertion 8 is violated");
	$fatal; 
end

endmodule