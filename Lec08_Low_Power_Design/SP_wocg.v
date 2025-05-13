module SP(
	// Input signals
	clk,
	rst_n,
	cg_en,
	in_valid,
	in_data,
	in_mode,
	// Output signals
	out_valid,
	out_data
);

// INPUT AND OUTPUT DECLARATION  
input		clk;
input		rst_n;
input		in_valid;
input		cg_en;
input [8:0] in_data;
input [2:0] in_mode;

output reg 		  out_valid;
output reg signed[9:0] out_data;

//================================================================
// Wire & Reg Declaration
//================================================================

reg [8:0] data [8:0];
reg [2:0] mode;

//GRAY
wire [8:0] gray_out;
reg [8:0] current_data;
reg [8:0] step1_out [8:0];

//ADDSUB
reg signed [8:0] step2_in [8:0];
wire signed [8:0] max, min, midpoint, hod;
reg signed [8:0] addsub_in, addsub_out;
reg signed [8:0] step2_out [8:0];

//SMA
reg signed [8:0] step3_in [8:0];
reg signed [8:0] left, middle, right;
reg signed [8:0] sma_out;
reg signed [8:0] step3_out [8:0];

//result
reg signed [8:0] step4_in [8:0];
reg signed [8:0] result_in [8:0];
reg sort_choice;

//---------------------------------------------------------------------
//   FSM State Declaration             
//---------------------------------------------------------------------

reg [2:0] c_state, n_state;
reg [3:0] counter;
parameter STANDBY = 3'b000, READ = 3'b001, GRAY = 3'b010, ADDSUB = 3'b011, SMA = 3'b100, FIND = 3'b101, RESULT = 3'b110;

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
        READ:       if(counter == 4'd8 && mode[0] == 1) n_state = GRAY;
					else if(counter == 4'd8 && mode[1] == 1) n_state = ADDSUB;
					else if(counter == 4'd8 && mode[2] == 1) n_state = SMA;
					else if(counter == 4'd8) n_state = RESULT;
                    else n_state = READ;
		GRAY:		if(counter == 4'd8 && mode[1] == 1) n_state = ADDSUB;
					else if(counter == 4'd8 && mode[2] == 1) n_state = SMA;
					else if(counter == 4'd8) n_state = RESULT;
					else n_state = GRAY;
		ADDSUB:		if(counter == 4'd9 && mode[2] == 1) n_state = SMA;
					else if(counter == 4'd9) n_state = RESULT;
					else n_state = ADDSUB;
		SMA:		if(counter == 4'd9) n_state = RESULT;
					else n_state = SMA;
		FIND:		if(counter == 7) n_state = RESULT;
					else n_state = FIND;
        RESULT:     if(counter == 4'd13) n_state = STANDBY;
                    else n_state = RESULT;
        default:    n_state = STANDBY;
	endcase
end

always @(posedge clk or negedge rst_n) 
begin
    if(!rst_n)
        counter <= 4'd0;
	else if(c_state != n_state && (c_state == READ || c_state == GRAY || c_state == ADDSUB || c_state == SMA || c_state == FIND))
		counter <= 4'd0;
	else if(n_state == READ || c_state == GRAY || c_state == ADDSUB || c_state == SMA || c_state == FIND || c_state == RESULT)
        counter <= counter + 1'b1;
    else if(c_state == STANDBY)
        counter <= 4'd0;
    else 
        counter <= counter;
end

//---------------------------------------------------------------------
//   INPUT circuit
//---------------------------------------------------------------------
genvar i_data;
generate
	for(i_data=0; i_data<9; i_data=i_data+1) 
	begin
		always @(posedge clk or negedge rst_n)
		begin
			if(!rst_n)
				data[i_data] <= 0;
			else if(in_valid && i_data == counter)
				data[i_data] <= in_data;
			else if(c_state == STANDBY)
				data[i_data] <= 0;
			else
				data[i_data] <= data[i_data];
		end
	end
endgenerate

always @(posedge clk or negedge rst_n)
begin
	if(!rst_n)
		mode <= 0;
	else if(in_valid && counter == 0)
		mode <= in_mode;
	else if(c_state == STANDBY)
		mode <= 0;
	else
		mode <= mode;
end

//================================================================
// GRAY code
//================================================================

always @(*) 
begin
	if(counter == 0)
		current_data = data[0];
	else if(counter == 1)
		current_data = data[1];
	else if(counter == 2)
		current_data = data[2];
	else if(counter == 3)
		current_data = data[3];
	else if(counter == 4)
		current_data = data[4];
	else if(counter == 5)
		current_data = data[5];
	else if(counter == 6)
		current_data = data[6];
	else if(counter == 7)
		current_data = data[7];
	else
		current_data = data[8];
end

assign gray_out[8] = current_data[8];
assign gray_out[7] = current_data[7];
assign gray_out[6] = gray_out[7] ^ current_data[6];
assign gray_out[5] = gray_out[6] ^ current_data[5];
assign gray_out[4] = gray_out[5] ^ current_data[4];
assign gray_out[3] = gray_out[4] ^ current_data[3];
assign gray_out[2] = gray_out[3] ^ current_data[2];
assign gray_out[1] = gray_out[2] ^ current_data[1];
assign gray_out[0] = gray_out[1] ^ current_data[0];

genvar i_step1;
generate
	for(i_step1=0; i_step1<9; i_step1=i_step1+1)
	begin
		always @(posedge clk or negedge rst_n)
		begin
			if(!rst_n)
				step1_out[i_step1] <= 0;
			else if(c_state == GRAY && i_step1 == counter)
				step1_out[i_step1] <= gray_out;
			else
				step1_out[i_step1] <= step1_out[i_step1];
		end
	end
endgenerate

//================================================================
// ADDSUB
//================================================================
genvar i_step2;
generate
	for(i_step2=0; i_step2<9; i_step2=i_step2+1)
	begin
		always @(*)
		begin
			if(mode[0] == 1)
			begin
				if(step1_out[i_step2][8] == 1)
					step2_in[i_step2] = {step1_out[i_step2][8], ~step1_out[i_step2][7:0]} + 1'b1;
				else
					step2_in[i_step2] = step1_out[i_step2];
			end
			else
				step2_in[i_step2] = data[i_step2];
		end
	end
endgenerate


sel_max sel1(.in1(step2_in[0]), .in2(step2_in[1]), .in3(step2_in[2]), .in4(step2_in[3]),
            .in5(step2_in[4]), .in6(step2_in[5]), .in7(step2_in[6]), .in8(step2_in[7]),
            .in9(step2_in[8]), .out(max));
sel_min sel2(.in1(step2_in[0]), .in2(step2_in[1]), .in3(step2_in[2]), .in4(step2_in[3]),
            .in5(step2_in[4]), .in6(step2_in[5]), .in7(step2_in[6]), .in8(step2_in[7]),
            .in9(step2_in[8]), .out(min));
assign midpoint = (max + min) / 2;
assign hod = (max - min) / 2;

always @(*)
begin
	if(counter == 0)
		addsub_in = step2_in[0];
	else if(counter == 1)
		addsub_in = step2_in[1];
	else if(counter == 2)
		addsub_in = step2_in[2];
	else if(counter == 3)
		addsub_in = step2_in[3];
	else if(counter == 4)
		addsub_in = step2_in[4];
	else if(counter == 5)
		addsub_in = step2_in[5];
	else if(counter == 6)
		addsub_in = step2_in[6];
	else if(counter == 7)
		addsub_in = step2_in[7];
	else
		addsub_in = step2_in[8];
end

always @(posedge clk or negedge rst_n) 
begin
	if(!rst_n)
		addsub_out <= 0;
	else
	begin
		if(addsub_in == midpoint)
			addsub_out <= addsub_in;
		else if(addsub_in > midpoint)
			addsub_out <= addsub_in - hod;
		else
			addsub_out <= addsub_in + hod;
	end
end

genvar i_add;
generate
	for(i_add=0; i_add<9; i_add=i_add+1)
	begin
		always @(posedge clk or negedge rst_n)
		begin
			if(!rst_n)
				step2_out[i_add] <= 0;
			else if(c_state == ADDSUB && i_add == counter - 1'b1)
				step2_out[i_add] <= addsub_out;
			else
				step2_out[i_add] <= step2_out[i_add];
		end
	end
endgenerate

//================================================================
// SMA
//================================================================

genvar i_step3;
generate
	for(i_step3=0; i_step3<9; i_step3=i_step3+1)
	begin
		always @(*)
		begin
			if(mode[1] == 1)
				step3_in[i_step3] = step2_out[i_step3];
			else
				step3_in[i_step3] = step2_in[i_step3];
		end
	end
endgenerate



always @(*)
begin
	if(counter == 0)
		left = step3_in[8];
	else if(counter == 1)
		left = step3_in[0];
	else if(counter == 2)
		left = step3_in[1];
	else if(counter == 3)
		left = step3_in[2];
	else if(counter == 4)
		left = step3_in[3];
	else if(counter == 5)
		left = step3_in[4];
	else if(counter == 6)
		left = step3_in[5];
	else if(counter == 7)
		left = step3_in[6];
	else
		left = step3_in[7];
end

always @(*)
begin
	if(counter == 0)
		middle = step3_in[0];
	else if(counter == 1)
		middle = step3_in[1];
	else if(counter == 2)
		middle = step3_in[2];
	else if(counter == 3)
		middle = step3_in[3];
	else if(counter == 4)
		middle = step3_in[4];
	else if(counter == 5)
		middle = step3_in[5];
	else if(counter == 6)
		middle = step3_in[6];
	else if(counter == 7)
		middle = step3_in[7];
	else
		middle = step3_in[8];
end

always @(*)
begin
	if(counter == 0)
		right = step3_in[1];
	else if(counter == 1)
		right = step3_in[2];
	else if(counter == 2)
		right = step3_in[3];
	else if(counter == 3)
		right = step3_in[4];
	else if(counter == 4)
		right = step3_in[5];
	else if(counter == 5)
		right = step3_in[6];
	else if(counter == 6)
		right = step3_in[7];
	else if(counter == 7)
		right = step3_in[8];
	else
		right = step3_in[0];
end

always @(posedge clk or negedge rst_n)
begin
	if(!rst_n)
		sma_out <= 0;
	else
		sma_out <= (left + middle + right) / 3;
end

genvar i_sma;
generate
	for(i_sma = 0; i_sma < 9; i_sma = i_sma + 1) 
	begin
		always @(posedge clk or negedge rst_n)
		begin
			if(!rst_n)
				step3_out[i_sma] <= 0;
			else if(c_state == SMA && i_sma == counter - 1)
				step3_out[i_sma] <= sma_out;
			else
				step3_out[i_sma] <= step3_out[i_sma];
		end
	end
endgenerate

//================================================================
// result
//================================================================

genvar i_step4;
generate
	for(i_step4=0; i_step4<9; i_step4=i_step4+1)
	begin
		always @(*)
		begin
			if(mode[2] == 1)
				step4_in[i_step4] = step3_out[i_step4];
			else
				step4_in[i_step4] = step3_in[i_step4];
		end
	end
endgenerate

always @(posedge clk or negedge rst_n) 
begin
	if(!rst_n)
		sort_choice <= 0;
	else if(c_state == RESULT && counter == 0)
		sort_choice <= 0;
	else
		sort_choice <= ~sort_choice;	
end

integer i_r1;
always @(posedge clk or negedge rst_n)
begin
	if(!rst_n)
	begin
		for(i_r1=0; i_r1<9; i_r1=i_r1+1)
		begin
			result_in[i_r1] <= 0;
		end
	end
	else if(c_state == STANDBY)
	begin
		for(i_r1=0; i_r1<9; i_r1=i_r1+1)
		begin
			result_in[i_r1] <= 0;
		end
	end
	else if(c_state == RESULT && counter == 0)
	begin
		for(i_r1=0; i_r1<9; i_r1=i_r1+1)
		begin
			result_in[i_r1] <= step4_in[i_r1];
		end
	end
	else if(c_state == RESULT && !sort_choice)
	begin
		for(i_r1=0; i_r1<8; i_r1=i_r1+2)
		begin
			if(result_in[i_r1] > result_in[i_r1+1])
			begin
				result_in[i_r1] <= result_in[i_r1+1];
				result_in[i_r1+1] <= result_in[i_r1];
			end
			else
			begin
				result_in[i_r1] <= result_in[i_r1];
				result_in[i_r1+1] <= result_in[i_r1+1];
			end
		end
	end
	else if(c_state == RESULT && sort_choice)
	begin
		for(i_r1=1; i_r1<9; i_r1=i_r1+2)
		begin
			if(result_in[i_r1] > result_in[i_r1+1])
			begin
				result_in[i_r1] <= result_in[i_r1+1];
				result_in[i_r1+1] <= result_in[i_r1];
			end
			else
			begin
				result_in[i_r1] <= result_in[i_r1];
				result_in[i_r1+1] <= result_in[i_r1+1];
			end
		end
	end
	else
	begin
		for(i_r1=0; i_r1<9; i_r1=i_r1+1)
		begin
			result_in[i_r1] <= result_in[i_r1];
		end
	end
end

//================================================================
// output
//================================================================

always @(posedge clk or negedge rst_n) 
begin
	if(!rst_n)
		out_valid <= 0;
	else if(c_state == RESULT && counter >= 10 && counter < 13)
		out_valid <= 1;
	else
		out_valid <= 0;	
end

always @(posedge clk or negedge rst_n) 
begin
	if(!rst_n)
		out_data <= 0;
	else if(c_state == RESULT && counter == 10)
		out_data <= result_in[8];
	else if(c_state == RESULT && counter == 11)
		out_data <= result_in[4];
	else if(c_state == RESULT && counter == 12)
		out_data <= result_in[0];
	else
		out_data <= 0;	
end

endmodule

module sel_max(
    in1,
    in2,
    in3,
    in4,
    in5,
    in6,
    in7,
    in8,
    in9,
	out
);

input signed [8:0] in1, in2, in3, in4, in5, in6, in7, in8, in9;
output reg [8:0] out;

reg signed [8:0] tmp1, tmp2, tmp3, tmp4, tmp5, tmp6, tmp7;

always @(*) 
begin
    if(in1 < in2)
        tmp1 = in2;
    else
        tmp1 = in1;    
end

always @(*) 
begin
    if(in3 < in4)
        tmp2 = in4;
    else
        tmp2 = in3;    
end

always @(*) 
begin
    if(in5 < in6)
        tmp3 = in6;
    else
        tmp3 = in5;    
end

always @(*) 
begin
    if(in7 < in8)
        tmp4 = in8;
    else
        tmp4 = in7;    
end

always @(*) 
begin
    if(tmp1 < tmp2)
        tmp5 = tmp2;
    else
        tmp5 = tmp1;    
end

always @(*) 
begin
    if(tmp3 < tmp4)
        tmp6 = tmp4;
    else
        tmp6 = tmp3;    
end

always @(*) 
begin
    if(tmp5 < tmp6)
        tmp7 = tmp6;
    else
        tmp7 = tmp5;    
end

always @(*) 
begin
    if(tmp7 < in9)
        out = in9;
    else
        out = tmp7;    
end

endmodule

module sel_min(
    in1,
    in2,
    in3,
    in4,
    in5,
    in6,
    in7,
    in8,
    in9,
	out
);

input signed [8:0] in1, in2, in3, in4, in5, in6, in7, in8, in9;
output reg [8:0] out;

reg signed [8:0] tmp1, tmp2, tmp3, tmp4, tmp5, tmp6, tmp7;

always @(*) 
begin
    if(in1 > in2)
        tmp1 = in2;
    else
        tmp1 = in1;    
end

always @(*) 
begin
    if(in3 > in4)
        tmp2 = in4;
    else
        tmp2 = in3;    
end

always @(*) 
begin
    if(in5 > in6)
        tmp3 = in6;
    else
        tmp3 = in5;    
end

always @(*) 
begin
    if(in7 > in8)
        tmp4 = in8;
    else
        tmp4 = in7;    
end

always @(*) 
begin
    if(tmp1 > tmp2)
        tmp5 = tmp2;
    else
        tmp5 = tmp1;    
end

always @(*) 
begin
    if(tmp3 > tmp4)
        tmp6 = tmp4;
    else
        tmp6 = tmp3;    
end

always @(*) 
begin
    if(tmp5 > tmp6)
        tmp7 = tmp6;
    else
        tmp7 = tmp5;    
end

always @(*) 
begin
    if(tmp7 > in9)
        out = in9;
    else
        out = tmp7;    
end

endmodule
