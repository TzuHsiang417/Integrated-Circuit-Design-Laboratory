`include "synchronizer.v"
`include "syn_XOR.v"
module CDC(
	//Input Port
	clk1,
    clk2,
    clk3,
	rst_n,
	in_valid1,
	in_valid2,
	user1,
	user2,

    //Output Port
    out_valid1,
    out_valid2,
	equal,
	exceed,
	winner
); 
//---------------------------------------------------------------------
//   INPUT AND OUTPUT DECLARATION
//---------------------------------------------------------------------
input 		clk1, clk2, clk3, rst_n;
input 		in_valid1, in_valid2;
input [3:0]	user1, user2;

output reg	out_valid1, out_valid2;
output reg	equal, exceed, winner;
//---------------------------------------------------------------------
//   WIRE AND REG DECLARATION
//---------------------------------------------------------------------
//----clk1----
reg [3:0]user1_reg;
reg [3:0]user2_reg;

//----clk2----
reg [2:0] cards[12:0];
reg [5:0] num_card;
reg [3:0] new_value;
reg [3:0] new_card;
reg signed [6:0] user1_value;
reg signed [6:0] user2_value;
reg signed [6:0] user1_value_tmp;
reg signed [6:0] user2_value_tmp;
wire syn_out1, syn_out2;
reg [3:0] round_d2;
reg signed [6:0] user_diff;
reg [5:0] N_equal;
reg [5:0] N_exceed;
reg [5:0] N_equal_tmp;
reg [5:0] N_exceed_tmp;
reg [12:0] N_equal_tmp2;
reg [12:0] N_exceed_tmp2;
reg [6:0] P_equal;
reg [6:0] P_exceed;
reg [2:0] cnt;
reg cal_flag;
//----clk3----
wire output_flag;
reg [5:0] out_cnt;
reg [4:0] out_round;
reg [1:0] winner_state;
reg [6:0] ans_equal;
reg [6:0] ans_exceed;
reg signed [6:0] user1_ans;
reg signed [6:0] user2_ans;
//---------------------------------------------------------------------
//   PARAMETER
//---------------------------------------------------------------------
//----clk1----

//----clk2----

//----clk3----
parameter NO_WINNER = 2'b00, WINNER1 = 2'b01, WINNER2 = 2'b10;
//---------------------------------------------------------------------
//   DESIGN
//---------------------------------------------------------------------
//============================================
//   clk1 domain
//============================================
always@(posedge clk1 or negedge rst_n) 
begin
	if(!rst_n) 
		user1_reg <= 0;
	else if(in_valid1)
		user1_reg <= user1;
	else
		user1_reg <= user1_reg;
end

always@(posedge clk1 or negedge rst_n) 
begin
	if(!rst_n) 
		user2_reg <= 0;
	else if(in_valid2)
		user2_reg <= user2;
	else
		user2_reg <= user2_reg;
end

//============================================
//   clk2 domain
//============================================
always @(*) 
begin
	if(round_d2 < 5 || round_d2 == 10)
		new_value = user1_reg;
	else
		new_value = user2_reg;
end

always @(*) 
begin
	if(new_value == 11 || new_value == 12 || new_value == 13)
		new_card = 1;
	else
		new_card = new_value;
end

genvar i_card;
generate
	for(i_card = 0; i_card<13; i_card=i_card+1)
	begin
		always @(posedge clk2 or negedge rst_n) 
		begin
			if(!rst_n)
				cards[i_card] <= 4;
			else if(num_card == 2)
				cards[i_card] <= 4;
			else if((user1_reg == i_card+1 && syn_out1) || (user2_reg == i_card+1 && syn_out2))
				cards[i_card] <= cards[i_card] - 1'b1;
			else
				cards[i_card] <= cards[i_card];
		end
	end
endgenerate

always @(posedge clk2 or negedge rst_n) 
begin
	if(!rst_n)
		num_card <= 52;
	else if(num_card == 2)
		num_card <= 52;
	else if(syn_out1 || syn_out2)
		num_card <= num_card - 1'b1;
	else
		num_card <= num_card;
end


always@(posedge clk2 or negedge rst_n) 
begin
	if(!rst_n) 
		user1_value <= 0;
	else if(round_d2 == 10 && syn_out1)
		user1_value <= new_card;
	else if(syn_out1)
		user1_value <= user1_value + new_card;
	else
		user1_value <= user1_value;
end

always@(posedge clk2 or negedge rst_n) 
begin
	if(!rst_n) 
		user2_value <= 0;
	else if(round_d2 == 5 && syn_out2)
		user2_value <= new_card;
	else if(syn_out2)
		user2_value <= user2_value + new_card;
	else
		user2_value <= user2_value;
end

always @(posedge clk2 or negedge rst_n) 
begin
	if(!rst_n)
		round_d2 <= 0;
	else if(round_d2 == 10 && (syn_out1 || syn_out2))
		round_d2 <= 1;
	else if(syn_out1 || syn_out2)
		round_d2 <= round_d2 + 1'b1;
	else
		round_d2 <= round_d2;
end

always @(posedge clk2 or negedge rst_n) 
begin
	if(!rst_n)
		N_equal_tmp <= 0;
	else
		N_equal_tmp <= N_equal;
end

always @(posedge clk2 or negedge rst_n) 
begin
	if(!rst_n)
		N_exceed_tmp <= 0;
	else
		N_exceed_tmp <= N_exceed;
end

always @(posedge clk2 or negedge rst_n) 
begin
	if(!rst_n)
		N_equal_tmp2 <= 0;
	else
		N_equal_tmp2 <= N_equal_tmp * 100;
end

always @(posedge clk2 or negedge rst_n) 
begin
	if(!rst_n)
		N_exceed_tmp2 <= 0;
	else
		N_exceed_tmp2 <= N_exceed_tmp * 100;
end

always @(posedge clk2 or negedge rst_n) 
begin
	if(!rst_n)
		P_equal <= 0;
	else if(cnt == 2)
		P_equal <= N_equal_tmp2 / num_card;
	else
		P_equal <= P_equal;
end

always @(posedge clk2 or negedge rst_n) 
begin
	if(!rst_n)
		P_exceed <= 0;
	else if(cnt == 2)
		P_exceed <= N_exceed_tmp2 / num_card;
	else
		P_exceed <= P_exceed;
end

always @(posedge clk2 or negedge rst_n) 
begin
	if(!rst_n)
		user1_value_tmp <= 0;
	else if(cnt == 1)
		user1_value_tmp <= user1_value;
	else
		user1_value_tmp <= user1_value_tmp;
end

always @(posedge clk2 or negedge rst_n) 
begin
	if(!rst_n)
		user2_value_tmp <= 0;
	else if(cnt == 1)
		user2_value_tmp <= user2_value;
	else
		user2_value_tmp <= user2_value_tmp;
end

always @(*) 
begin
	if(round_d2 < 5 || round_d2 == 10)
		user_diff = 21 - user1_value;
	else
		user_diff = 21 - user2_value;
end

always @(posedge clk2 or negedge rst_n) 
begin
	if(!rst_n)
		cal_flag <= 0;
	/*else if(round_d2 == 10 && cnt == 0)
		cal_flag <= 1;*/
	else if(cnt == 3)
		cal_flag <= 1;
	else
		cal_flag <= 0;
end

always @(*) 
begin
	case (user_diff)
		1:		N_equal = cards[0] + cards[10] + cards[11] + cards[12];
		2:		N_equal = cards[1];
		3:		N_equal = cards[2];
		4:		N_equal = cards[3];
		5:		N_equal = cards[4];
		6:		N_equal = cards[5];
		7:		N_equal = cards[6];
		8:		N_equal = cards[7];
		9:		N_equal = cards[8];
		10:		N_equal = cards[9];
		default:N_equal = 0;
	endcase	
end

always @(*) 
begin
	case (user_diff)
		1:		N_exceed = cards[1] + (((cards[2] + cards[3]) + (cards[4] + cards[5])) + ((cards[6] + cards[7]) + (cards[8] + cards[9])));
		2:		N_exceed = ((cards[2] + cards[3]) + (cards[4] + cards[5])) + ((cards[6] + cards[7]) + (cards[8] + cards[9]));
		3:		N_exceed = (cards[3] + (cards[4] + cards[5])) + ((cards[6] + cards[7]) + (cards[8] + cards[9]));
		4:		N_exceed = (cards[4] + cards[5]) + ((cards[6] + cards[7]) + (cards[8] + cards[9]));
		5:		N_exceed = cards[5] + ((cards[6] + cards[7]) + (cards[8] + cards[9]));
		6:		N_exceed = (cards[6] + cards[7]) + (cards[8] + cards[9]);
		7:		N_exceed = cards[7] + (cards[8] + cards[9]);
		8:		N_exceed = cards[8] + cards[9];
		9:		N_exceed = cards[9];
		10:		N_exceed = 0;
		11:		N_exceed = 0;
		12:		N_exceed = 0;
		13:		N_exceed = 0;
		14:		N_exceed = 0;
		15:		N_exceed = 0;
		16:		N_exceed = 0;
		17:		N_exceed = 0;
		18:		N_exceed = 0;
		default:N_exceed = num_card;
	endcase	
end

always @(posedge clk2 or negedge rst_n) 
begin
	if(!rst_n)
		cnt <= 7;
	else if(syn_out1 || syn_out2)
		cnt <= 0;
	else if(cnt == 7)
		cnt <= cnt;
	else
		cnt <= cnt + 1'b1;
end
//============================================
//   clk3 domain
//============================================
always@(posedge clk3 or negedge rst_n) 
begin
	if(!rst_n) 
		out_cnt <= 63;
	else if(output_flag)
		out_cnt <= 0;
	else if(out_cnt == 63)
		out_cnt <= out_cnt;
	else
		out_cnt <= out_cnt + 1'b1;
end

always@(posedge clk3 or negedge rst_n) 
begin
	if(!rst_n) 
		out_round <= 0;
	else if(out_round == 10 && output_flag)
		out_round <= 1;
	else if(output_flag)
		out_round <= out_round + 1'b1;
	else
		out_round <= out_round;
end

always@(posedge clk3 or negedge rst_n) 
begin
	if(!rst_n) 
		ans_equal <= 0;
	else if(output_flag)
		ans_equal <= P_equal;
	else
		ans_equal <= ans_equal;
end

always@(posedge clk3 or negedge rst_n) 
begin
	if(!rst_n) 
		ans_exceed <= 0;
	else if(output_flag)
		ans_exceed <= P_exceed;
	else
		ans_exceed <= ans_exceed;
end

always@(posedge clk3 or negedge rst_n) 
begin
	if(!rst_n) 
		user1_ans <= 0;
	else if(output_flag)
		user1_ans <= user1_value_tmp;
	else
		user1_ans <= user1_ans;
end

always@(posedge clk3 or negedge rst_n) 
begin
	if(!rst_n) 
		user2_ans <= 0;
	else if(output_flag)
		user2_ans <= user2_value_tmp;
	else
		user2_ans <= user2_ans;
end

always @(posedge clk3 or negedge rst_n) 
begin
	if(!rst_n)
		out_valid1 <= 0;
	else if((out_round == 3 || out_round == 4 || out_round == 8 || out_round == 9) && out_cnt < 7)
		out_valid1 <= 1;
	else
		out_valid1 <= 0;
end

always @(posedge clk3 or negedge rst_n) 
begin
	if(!rst_n)
		equal <= 0;
	else if((out_round == 3 || out_round == 4 || out_round == 8 || out_round == 9) && out_cnt < 7)
	begin
		case (out_cnt)
			0: 		equal <= ans_equal[6];
			1: 		equal <= ans_equal[5];
			2: 		equal <= ans_equal[4];
			3: 		equal <= ans_equal[3];
			4: 		equal <= ans_equal[2];
			5: 		equal <= ans_equal[1];
			6: 		equal <= ans_equal[0];
			default:equal <= 0;
		endcase
	end
	else
		equal <= 0;
end

always @(posedge clk3 or negedge rst_n) 
begin
	if(!rst_n)
		exceed <= 0;
	else if((out_round == 3 || out_round == 4 || out_round == 8 || out_round == 9) && out_cnt < 7)
	begin
		case (out_cnt)
			0: 		exceed <= ans_exceed[6];
			1: 		exceed <= ans_exceed[5];
			2: 		exceed <= ans_exceed[4];
			3: 		exceed <= ans_exceed[3];
			4: 		exceed <= ans_exceed[2];
			5: 		exceed <= ans_exceed[1];
			6: 		exceed <= ans_exceed[0];
			default:exceed <= 0;
		endcase
	end
	else
		exceed <= 0;
end

always @(*) 
begin
	if((user1_ans > 21 && user2_ans > 21) || user1_ans == user2_ans)
		winner_state = NO_WINNER;
	else if(user1_ans > 21)
		winner_state = WINNER2;
	else if(user2_ans > 21)
		winner_state = WINNER1;
	else if(user1_ans > user2_ans)
		winner_state = WINNER1;
	else
		winner_state = WINNER2;	
end

always @(posedge clk3 or negedge rst_n) 
begin
	if(!rst_n)
		out_valid2 <= 0;
	else if(out_round == 10)
	begin
		if(winner_state == NO_WINNER && out_cnt < 1)
			out_valid2 <= 1;
		else if((winner_state == WINNER1 || winner_state == WINNER2) && out_cnt < 2)
			out_valid2 <= 1;
		else
			out_valid2 <= 0;
	end
	else
		out_valid2 <= 0;
end

always @(posedge clk3 or negedge rst_n) 
begin
	if(!rst_n)
		winner <= 0;
	else if(out_round == 10)
	begin
		if(winner_state == NO_WINNER && out_cnt < 1)
			winner <= 0;
		else if(winner_state == WINNER1 && out_cnt < 2)
		begin
			if(out_cnt == 0)
				winner <= 1;
			else
				winner <= 0;
		end
		else if(winner_state == WINNER2 && out_cnt < 2)
			winner <= 1;
		else
			winner <= 0;
	end
	else
		winner <= 0;
end
//---------------------------------------------------------------------
//   syn_XOR
//---------------------------------------------------------------------
syn_XOR u_syn_XOR1(.IN(in_valid1),.OUT(syn_out1),.TX_CLK(clk1),.RX_CLK(clk2),.RST_N(rst_n));
syn_XOR u_syn_XOR2(.IN(in_valid2),.OUT(syn_out2),.TX_CLK(clk1),.RX_CLK(clk2),.RST_N(rst_n));
syn_XOR u_syn_XOR3(.IN(cal_flag),.OUT(output_flag),.TX_CLK(clk2),.RX_CLK(clk3),.RST_N(rst_n));

endmodule