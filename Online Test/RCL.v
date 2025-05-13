module RCL(
    clk,
    rst_n,
    in_valid,
    coef_Q,
    coef_L,
    out_valid,
    out
);

input clk, rst_n, in_valid;
input [4:0] coef_Q, coef_L;

output reg out_valid;
output reg [1:0] out;

//---------------------------------------------------------------------
//   WIRE & REG Declaration             
//---------------------------------------------------------------------
reg signed [4:0] a, b, c;
reg signed [4:0] m, n; 
reg [4:0] k;
reg signed [9:0] tmp1;
reg signed [20:0] tmp2;
reg signed [9:0] tmp3;
reg signed [10:0] dis;
reg signed [10:0] rem;

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
        STANDBY:    if(in_valid) n_state = READ;
                    else n_state = STANDBY;
        READ:       if(counter == 6'd2) n_state = RESULT;
                    else n_state = READ;
        RESULT:     if(counter == 6'd5) n_state = STANDBY;
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
//   INPUT circuit
//---------------------------------------------------------------------
always @(posedge clk or negedge rst_n) 
begin
    if(!rst_n)
        a <= 0;
    else if(in_valid && counter == 0)
        a <= coef_L;
    else if(c_state == STANDBY)
	a <= 0;
    else
        a <= a;
end

always @(posedge clk or negedge rst_n) 
begin
    if(!rst_n)
        b <= 0;
    else if(in_valid && counter == 1)
        b <= coef_L;
    else if(c_state == STANDBY)
	b <= 0;
    else
        b <= b;
end

always @(posedge clk or negedge rst_n) 
begin
    if(!rst_n)
        c <= 0;
    else if(in_valid && counter == 2)
        c <= coef_L;
    else if(c_state == STANDBY)
	c <= 0;
    else
        c <= c;
end

always @(posedge clk or negedge rst_n) 
begin
    if(!rst_n)
        m <= 0;
    else if(in_valid && counter == 0)
        m <= coef_Q;
    else if(c_state == STANDBY)
	m <= 0;
    else
        m <= m;
end

always @(posedge clk or negedge rst_n) 
begin
    if(!rst_n)
        n <= 0;
    else if(in_valid && counter == 1)
        n <= coef_Q;
    else if(c_state == STANDBY)
	n <= 0;
    else
        n <= n;
end

always @(posedge clk or negedge rst_n) 
begin
    if(!rst_n)
        k <= 0;
    else if(in_valid && counter == 2)
        k <= coef_Q;
    else if(c_state == STANDBY)
	k <= 0;
    else
        k <= k;
end

always @(posedge clk)
begin
    if(counter == 3)
 	tmp1 <= a*m + b*n +c;
    else
        tmp1 <= tmp1;
end

always @(posedge clk)
begin
    if(counter == 4)
 	tmp2 <= tmp1 * tmp1;
    else
        tmp2 <= tmp2;
end

always @(posedge clk)
begin
    if(counter == 3)
 	tmp3 <= a*a + b*b;
    else
        tmp3 <= tmp3;
end

always @(posedge clk)
begin
    if(counter == 5)
 	dis <= tmp2 / tmp3;
    else
        dis <= dis;
end

always @(posedge clk)
begin
    if(counter == 5)
 	rem <= tmp2 % tmp3;
    else
        rem <= rem;
end



always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        out_valid <= 0;
    else if(counter == 6)
        out_valid <= 1;
    else
        out_valid <= 0;
end

always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
	out <= 0;
    else if(counter == 6)
    begin
	if(dis > k)
	    out <= 0;
	else if(dis < k)
	    out <= 2;
	else
	begin
	    if(rem > 0)
		out <= 0;
	    else
		out <= 1;
	end
    end
end

endmodule
