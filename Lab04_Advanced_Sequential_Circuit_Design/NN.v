module NN(
	// Input signals
	clk,
	rst_n,
	in_valid_u,
	in_valid_w,
	in_valid_v,
	in_valid_x,
	weight_u,
	weight_w,
	weight_v,
	data_x,
	// Output signals
	out_valid,
	out
);

//---------------------------------------------------------------------
//   PARAMETER
//---------------------------------------------------------------------

// IEEE floating point paramenters
parameter inst_sig_width = 23;
parameter inst_exp_width = 8;
parameter inst_ieee_compliance = 0;
parameter inst_arch = 0;
parameter [2:0]inst_rnd = 0;

//---------------------------------------------------------------------
//   INPUT AND OUTPUT DECLARATION
//---------------------------------------------------------------------
input  clk, rst_n, in_valid_u, in_valid_w, in_valid_v, in_valid_x;
input [inst_sig_width+inst_exp_width:0] weight_u, weight_w, weight_v;
input [inst_sig_width+inst_exp_width:0] data_x;
output reg	out_valid;
output reg [inst_sig_width+inst_exp_width:0] out;

//---------------------------------------------------------------------
//   FSM State Declaration             
//---------------------------------------------------------------------

reg [1:0] c_state, n_state;
reg [4:0] counter;
parameter STANDBY = 2'b00, READ = 2'b01, RESULT = 2'b10;

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
        STANDBY:    if(in_valid_u) n_state = READ;
                    else n_state = STANDBY;
        READ:       if(counter == 6'd9) n_state = RESULT;
                    else n_state = READ;
        RESULT:     if(counter == 6'd24) n_state = STANDBY;
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


//---------------------------------------------------------------------
//   WIRE AND REG DECLARATION
//---------------------------------------------------------------------

reg [inst_sig_width+inst_exp_width:0] U_matrix [2:0][2:0];
reg [inst_sig_width+inst_exp_width:0] W_matrix [2:0][2:0];
reg [inst_sig_width+inst_exp_width:0] V_matrix [2:0][2:0];
reg [inst_sig_width+inst_exp_width:0] X_matrix [2:0][2:0];

reg [inst_sig_width+inst_exp_width:0] FF1_xt_in [2:0];
wire [inst_sig_width+inst_exp_width:0] FF1_xt_out [2:0];
reg [inst_sig_width+inst_exp_width:0] FF1_ht_in [2:0];
wire [inst_sig_width+inst_exp_width:0] FF1_ht_out [2:0];

reg [inst_sig_width+inst_exp_width:0] U_choice [2:0];
reg [inst_sig_width+inst_exp_width:0] W_choice [2:0];

wire [inst_sig_width+inst_exp_width:0] tmp_a;

wire [inst_sig_width+inst_exp_width:0] U_ans;
wire [inst_sig_width+inst_exp_width:0] W_ans;

wire [inst_sig_width+inst_exp_width:0] FF2_zt_in ;
wire [inst_sig_width+inst_exp_width:0] FF2_zt_out;

wire [inst_sig_width+inst_exp_width:0] tmp_c;

wire [inst_sig_width+inst_exp_width:0] one;
wire [inst_sig_width+inst_exp_width:0] tmp_d;

wire [inst_sig_width+inst_exp_width:0] ht;

reg [inst_sig_width+inst_exp_width:0] FF3_ht_in [2:0];
wire [inst_sig_width+inst_exp_width:0] FF3_ht_out [2:0];

reg [inst_sig_width+inst_exp_width:0] V_choice [2:0];
reg [inst_sig_width+inst_exp_width:0] h_choice;

wire [inst_sig_width+inst_exp_width:0] M_ans [2:0];

reg [inst_sig_width+inst_exp_width:0] P_choice [2:0];

wire [inst_sig_width+inst_exp_width:0] V_ans [2:0];

reg [inst_sig_width+inst_exp_width:0] y_in [2:0];
wire [inst_sig_width+inst_exp_width:0] y_out [2:0];

reg [inst_sig_width+inst_exp_width:0] Y_matrix [2:0][2:0];
//---------------------------------------------------------------------
//   INPUT circuit
//---------------------------------------------------------------------
genvar i,j;
generate
	for(i=0; i<3; i=i+1)
	begin
		for(j=0; j<3; j=j+1)
		begin
			always @(posedge clk or negedge rst_n) 
			begin
				if(!rst_n)
				begin
					U_matrix[i][j] <= 0;
					W_matrix[i][j] <= 0;
					V_matrix[i][j] <= 0;
					X_matrix[i][j] <= 0;
				end
				else if(c_state == READ || n_state == READ)
				begin
					if(3*i+j == counter)
					begin
						U_matrix[i][j] <= weight_u;
						W_matrix[i][j] <= weight_w;
						V_matrix[i][j] <= weight_v;
						X_matrix[i][j] <= data_x;
					end
					else
					begin
						U_matrix[i][j] <= U_matrix[i][j];
						W_matrix[i][j] <= W_matrix[i][j];
						V_matrix[i][j] <= V_matrix[i][j];
						X_matrix[i][j] <= X_matrix[i][j];
					end
				end
				else
				begin
					U_matrix[i][j] <= U_matrix[i][j];
					W_matrix[i][j] <= W_matrix[i][j];
					V_matrix[i][j] <= V_matrix[i][j];
					X_matrix[i][j] <= X_matrix[i][j];
				end
			end
		end
	end
endgenerate

always @(*) 
begin
	if(counter == 5'd7 || counter == 5'd8 || counter == 5'd9)
	begin
		FF1_xt_in[0] = X_matrix[0][0];
		FF1_xt_in[1] = X_matrix[0][1];
		FF1_xt_in[2] = X_matrix[0][2];
	end
	else if(counter == 5'd11 || counter == 5'd12 || counter == 5'd13)
	begin
		FF1_xt_in[0] = X_matrix[1][0];
		FF1_xt_in[1] = X_matrix[1][1];
		FF1_xt_in[2] = X_matrix[1][2];
	end
	else if(counter == 5'd15 || counter == 5'd16 || counter == 5'd17)
	begin
		FF1_xt_in[0] = X_matrix[2][0];
		FF1_xt_in[1] = X_matrix[2][1];
		FF1_xt_in[2] = X_matrix[2][2];
	end
	else
	begin
		FF1_xt_in[0] = 0;
		FF1_xt_in[1] = 0;
		FF1_xt_in[2] = 0;
	end
end

always @(*) 
begin
	if(counter == 5'd7)
	begin
		FF1_ht_in[0] = 0;
	end
	else if(counter == 5'd11 || counter == 5'd15)
	begin
		FF1_ht_in[0] = FF3_ht_out[0];
	end
	else
	begin
		FF1_ht_in[0] = FF1_ht_out[0];
	end
end

always @(*) 
begin
	if(counter == 5'd7)
	begin
		FF1_ht_in[1] = 0;
	end
	else if(counter == 5'd11 || counter == 5'd15)
	begin
		FF1_ht_in[1] = FF3_ht_out[1];
	end
	else
	begin
		FF1_ht_in[1] = FF1_ht_out[1];
	end
end

always @(*) 
begin
	if(counter == 5'd7)
	begin
		FF1_ht_in[2] = 0;
	end
	else if(counter == 5'd11 || counter == 5'd15)
	begin
		FF1_ht_in[2] = ht;
	end
	else
	begin
		FF1_ht_in[2] = FF1_ht_out[2];
	end
end

//---------------------------------------------------------------------
//   CALCULATION circuit
//---------------------------------------------------------------------
FF1 ff_a(.x1_in(FF1_xt_in[0]), .x1_out(FF1_xt_out[0]), .x2_in(FF1_xt_in[1]), .x2_out(FF1_xt_out[1]), .x3_in(FF1_xt_in[2]), .x3_out(FF1_xt_out[2]), 
			.h1_in(FF1_ht_in[0]), .h1_out(FF1_ht_out[0]), .h2_in(FF1_ht_in[1]), .h2_out(FF1_ht_out[1]), .h3_in(FF1_ht_in[2]), .h3_out(FF1_ht_out[2]), .clk(clk));

always @(*) 
begin
	if(counter == 5'd8 || counter == 5'd12 || counter == 5'd16)
	begin
		U_choice[0] = U_matrix[0][0];
		U_choice[1] = U_matrix[0][1];
		U_choice[2] = U_matrix[0][2];

		W_choice[0] = W_matrix[0][0];
		W_choice[1] = W_matrix[0][1];
		W_choice[2] = W_matrix[0][2];
	end
	else if(counter == 5'd9 || counter == 5'd13 || counter == 5'd17)
	begin
		U_choice[0] = U_matrix[1][0];
		U_choice[1] = U_matrix[1][1];
		U_choice[2] = U_matrix[1][2];

		W_choice[0] = W_matrix[1][0];
		W_choice[1] = W_matrix[1][1];
		W_choice[2] = W_matrix[1][2];
	end
	else if(counter == 5'd10 || counter == 5'd14 || counter == 5'd18)
	begin
		U_choice[0] = U_matrix[2][0];
		U_choice[1] = U_matrix[2][1];
		U_choice[2] = U_matrix[2][2];

		W_choice[0] = W_matrix[2][0];
		W_choice[1] = W_matrix[2][1];
		W_choice[2] = W_matrix[2][2];
	end
	else
	begin
		U_choice[0] = 0;
		U_choice[1] = 0;
		U_choice[2] = 0;

		W_choice[0] = 0;
		W_choice[1] = 0;
		W_choice[2] = 0;
	end
end

DW_fp_dp3 #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_arch)
U1 (.a(FF1_xt_out[0]), .b(U_choice[0]), .c(FF1_xt_out[1]), .d(U_choice[1]), .e(FF1_xt_out[2]), .f(U_choice[2]), .rnd(inst_rnd), .z(U_ans));

DW_fp_dp3 #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_arch)
W1 (.a(FF1_ht_out[0]), .b(W_choice[0]), .c(FF1_ht_out[1]), .d(W_choice[1]), .e(FF1_ht_out[2]), .f(W_choice[2]), .rnd(inst_rnd), .z(W_ans));

DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
A1 ( .a(U_ans), .b(W_ans), .rnd(inst_rnd), .z(tmp_a));

assign FF2_zt_in = {~tmp_a[31],tmp_a[30:0]};


FF2 ff_2(.zt_in(FF2_zt_in), .zt_out(FF2_zt_out), .clk(clk));

DW_fp_exp #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_arch) 
E1 (.a(FF2_zt_out), .z(tmp_c));


assign one = 32'h3f800000;

DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
A4 ( .a(tmp_c), .b(one), .rnd(inst_rnd), .z(tmp_d));

DW_fp_recip #(inst_sig_width, inst_exp_width, inst_ieee_compliance, /*inst_faithful_round*/0) 
R1 (.a(tmp_d), .rnd(inst_rnd), .z(ht));

always @(*) 
begin
	if(counter == 5'd9 || counter == 5'd13 || counter == 5'd17)
	begin
		FF3_ht_in[0] = ht;
	end
	else
	begin
		FF3_ht_in[0] = FF3_ht_out[0];
	end
end

always @(*) 
begin
	if(counter == 5'd10 || counter == 5'd14 || counter == 5'd18)
	begin
		FF3_ht_in[1] = ht;
	end
	else
	begin
		FF3_ht_in[1] = FF3_ht_out[1];
	end
end

always @(*) 
begin
	if(counter == 5'd11 || counter == 5'd15 || counter == 5'd19)
	begin
		FF3_ht_in[2] = ht;
	end
	else
	begin
		FF3_ht_in[2] = FF3_ht_out[2];
	end
end

FF3 ff_3(.h1_in(FF3_ht_in[0]), .h1_out(FF3_ht_out[0]), .h2_in(FF3_ht_in[1]), .h2_out(FF3_ht_out[1]), .h3_in(FF3_ht_in[2]), .h3_out(FF3_ht_out[2]), .clk(clk));

always @(*) 
begin
	if(counter == 5'd10 || counter == 5'd14 || counter == 5'd18)
	begin
		V_choice[0] = V_matrix[0][0];
		V_choice[1] = V_matrix[1][0];
		V_choice[2] = V_matrix[2][0];
	end
	else if(counter == 5'd11 || counter == 5'd15 || counter == 5'd19)
	begin
		V_choice[0] = V_matrix[0][1];
		V_choice[1] = V_matrix[1][1];
		V_choice[2] = V_matrix[2][1];
	end
	else if(counter == 5'd12 || counter == 5'd16 || counter == 5'd20)
	begin
		V_choice[0] = V_matrix[0][2];
		V_choice[1] = V_matrix[1][2];
		V_choice[2] = V_matrix[2][2];
	end
	else
	begin
		V_choice[0] = 0;
		V_choice[1] = 0;
		V_choice[2] = 0;
	end
end

always @(*) 
begin
	if(counter == 5'd10 || counter == 5'd14 || counter == 5'd18)
	begin
		h_choice = FF3_ht_out[0];
	end
	else if(counter == 5'd11 || counter == 5'd15 || counter == 5'd19)
	begin
		h_choice = FF3_ht_out[1];
	end
	else if(counter == 5'd12 || counter == 5'd16 || counter == 5'd20)
	begin
		h_choice = FF3_ht_out[2];
	end
	else
	begin
		h_choice = 0;
	end
end

DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
M1 ( .a(V_choice[0]), .b(h_choice), .rnd(inst_rnd), .z(M_ans[0]));

DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
M2 ( .a(V_choice[1]), .b(h_choice), .rnd(inst_rnd), .z(M_ans[1]));

DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
M3 ( .a(V_choice[2]), .b(h_choice), .rnd(inst_rnd), .z(M_ans[2]));

always @(*) 
begin
	if(counter == 5'd10 || counter == 5'd14 || counter == 5'd18)
	begin
		P_choice[0] = 0;
		P_choice[1] = 0;
		P_choice[2] = 0;
	end
	else if(counter == 5'd11 || counter == 5'd15 || counter == 5'd19)
	begin
		P_choice[0] = y_out[0];
		P_choice[1] = y_out[1];
		P_choice[2] = y_out[2];
	end
	else if(counter == 5'd12 || counter == 5'd16 || counter == 5'd20)
	begin
		P_choice[0] = y_out[0];
		P_choice[1] = y_out[1];
		P_choice[2] = y_out[2];
	end
	else
	begin
		P_choice[0] = 0;
		P_choice[1] = 0;
		P_choice[2] = 0;
	end
end

DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
P1 ( .a(P_choice[0]), .b(M_ans[0]), .rnd(inst_rnd), .z(V_ans[0]));
DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
P2 ( .a(P_choice[1]), .b(M_ans[1]), .rnd(inst_rnd), .z(V_ans[1]));
DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
P3 ( .a(P_choice[2]), .b(M_ans[2]), .rnd(inst_rnd), .z(V_ans[2]));

always @(*) //////////////////////////////////////////////////////////////////
begin
	if(counter == 5'd10 || counter == 5'd11 || counter == 5'd12 || counter == 5'd14 || counter == 5'd15 || counter == 5'd16 || counter == 5'd18 || counter == 5'd19 || counter == 5'd20)
	begin
		y_in[0] = V_ans[0];
		y_in[1] = V_ans[1];
		y_in[2] = V_ans[2];
	end
	else
	begin
		y_in[0] = y_out[0];
		y_in[1] = y_out[1];
		y_in[2] = y_out[2];
	end
end

FF4 ff_b(.y1_in(y_in[0]), .y1_out(y_out[0]), .y2_in(y_in[1]), .y2_out(y_out[1]), .y3_in(y_in[2]), .y3_out(y_out[2]), .clk(clk));

//synopsys dc_script_begin
//set_implementation rtl A1 
//set_implementation rtl A4

//set_implementation rtl R1 

//set_implementation rtl U1 

//set_implementation rtl W1 

//set_implementation rtl M1 
//set_implementation rtl M2 
//set_implementation rtl M3 

//set_implementation rtl P1 
//set_implementation rtl P2 
//set_implementation rtl P3

//set_implementation rtl E1 
 
//synopsys dc_script_end


//---------------------------------------------------------------------
//   OUTPUT circuit
//---------------------------------------------------------------------
genvar m,n;
generate
	for(m=0; m<3; m=m+1)
	begin
		for(n=0; n<3; n=n+1)
		begin
			always @(posedge clk or negedge rst_n) 
			begin
				if(!rst_n)
				begin
					Y_matrix[m][n] <= 0;
				end
				else if(counter == 5'd12)
				begin
					if(m == 0)
					begin
						if(V_ans[n][31] == 1)
							Y_matrix[m][n] <= 0;
						else
							Y_matrix[m][n] <= V_ans[n];
					end
					else
						Y_matrix[m][n] <= Y_matrix[m][n];
				end
				else if(counter == 5'd16)
				begin
					if(m == 1)
					begin
						if(V_ans[n][31] == 1)
							Y_matrix[m][n] <= 0;
						else
							Y_matrix[m][n] <= V_ans[n];
					end
					else
						Y_matrix[m][n] <= Y_matrix[m][n];
				end
				else if(counter == 5'd20)
				begin
					if(m == 2)
					begin
						if(V_ans[n][31] == 1)
							Y_matrix[m][n] <= 0;
						else
							Y_matrix[m][n] <= V_ans[n];
					end
					else
						Y_matrix[m][n] <= Y_matrix[m][n];
				end
				else
					Y_matrix[m][n] <= Y_matrix[m][n];
			end
		end
	end
endgenerate

always @(posedge clk or negedge rst_n) 
begin
	if(!rst_n)
		out <= 0;
	else if(counter == 16)
		out <= Y_matrix[0][0];
	else if(counter == 17)
		out <= Y_matrix[0][1];
	else if(counter == 18)
		out <= Y_matrix[0][2];
	else if(counter == 19)
		out <= Y_matrix[1][0];
	else if(counter == 20)
		out <= Y_matrix[1][1];
	else if(counter == 21)
		out <= Y_matrix[1][2];
	else if(counter == 22)
		out <= Y_matrix[2][0];
	else if(counter == 23)
		out <= Y_matrix[2][1];
	else if(counter == 24)
		out <= Y_matrix[2][2];
	else
		out <= 0;
end

always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        out_valid <= 0;
    else if(counter >= 5'd16 && counter <= 5'd24)
        out_valid <= 1;
    else
        out_valid <= 0;
end

endmodule

module FF1(x1_in, x1_out, x2_in, x2_out, x3_in, x3_out, h1_in, h1_out, h2_in, h2_out, h3_in, h3_out, clk);

// IEEE floating point paramenters
parameter inst_sig_width = 23;
parameter inst_exp_width = 8;
parameter inst_ieee_compliance = 0;
parameter inst_arch = 2;

input [inst_sig_width+inst_exp_width:0] x1_in;
input [inst_sig_width+inst_exp_width:0] x2_in;
input [inst_sig_width+inst_exp_width:0] x3_in;
input [inst_sig_width+inst_exp_width:0] h1_in;
input [inst_sig_width+inst_exp_width:0] h2_in;
input [inst_sig_width+inst_exp_width:0] h3_in;
input clk;

output reg[inst_sig_width+inst_exp_width:0] x1_out;
output reg[inst_sig_width+inst_exp_width:0] x2_out;
output reg[inst_sig_width+inst_exp_width:0] x3_out;
output reg[inst_sig_width+inst_exp_width:0] h1_out;
output reg[inst_sig_width+inst_exp_width:0] h2_out;
output reg[inst_sig_width+inst_exp_width:0] h3_out;
always @(posedge clk) 
begin
	x1_out <= x1_in;
	x2_out <= x2_in;
	x3_out <= x3_in;

	h1_out <= h1_in;
	h2_out <= h2_in;
	h3_out <= h3_in;
end

endmodule

module FF2(zt_in, zt_out, clk);

// IEEE floating point paramenters
parameter inst_sig_width = 23;
parameter inst_exp_width = 8;
parameter inst_ieee_compliance = 0;
parameter inst_arch = 2;

input [inst_sig_width+inst_exp_width:0] zt_in;
input clk;

output reg[inst_sig_width+inst_exp_width:0] zt_out;

always @(posedge clk) 
begin
	zt_out <= zt_in;
end

endmodule

module FF3(h1_in, h1_out, h2_in, h2_out, h3_in, h3_out, clk);

// IEEE floating point paramenters
parameter inst_sig_width = 23;
parameter inst_exp_width = 8;
parameter inst_ieee_compliance = 0;
parameter inst_arch = 2;

input [inst_sig_width+inst_exp_width:0] h1_in;
input [inst_sig_width+inst_exp_width:0] h2_in;
input [inst_sig_width+inst_exp_width:0] h3_in;
input clk;

output reg[inst_sig_width+inst_exp_width:0] h1_out;
output reg[inst_sig_width+inst_exp_width:0] h2_out;
output reg[inst_sig_width+inst_exp_width:0] h3_out;

always @(posedge clk) 
begin
	h1_out <= h1_in;
	h2_out <= h2_in;
	h3_out <= h3_in;
end

endmodule

module FF4(y1_in, y1_out, y2_in, y2_out, y3_in, y3_out, clk);

// IEEE floating point paramenters
parameter inst_sig_width = 23;
parameter inst_exp_width = 8;
parameter inst_ieee_compliance = 0;
parameter inst_arch = 2;

input [inst_sig_width+inst_exp_width:0] y1_in;
input [inst_sig_width+inst_exp_width:0] y2_in;
input [inst_sig_width+inst_exp_width:0] y3_in;
input clk;

output reg[inst_sig_width+inst_exp_width:0] y1_out;
output reg[inst_sig_width+inst_exp_width:0] y2_out;
output reg[inst_sig_width+inst_exp_width:0] y3_out;

always @(posedge clk) 
begin
	y1_out <= y1_in;
	y2_out <= y2_in;
	y3_out <= y3_in;
end

endmodule