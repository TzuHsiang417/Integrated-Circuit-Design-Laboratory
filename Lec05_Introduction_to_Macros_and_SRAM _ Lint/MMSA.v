module MMSA(
// input signals
    clk,
    rst_n,
    in_valid,
	in_valid2,
    matrix,
	matrix_size,
    i_mat_idx,
    w_mat_idx,
	
// output signals
    out_valid,
    out_value
);
//---------------------------------------------------------------------
//   INPUT AND OUTPUT DECLARATION
//---------------------------------------------------------------------
input        clk, rst_n, in_valid, in_valid2;
input [15:0] matrix;
input [1:0]  matrix_size;
input [3:0]  i_mat_idx, w_mat_idx;

output reg       	     out_valid;
output reg signed [39:0] out_value;
//---------------------------------------------------------------------
//   PARAMETER
//---------------------------------------------------------------------


//---------------------------------------------------------------------
//   WIRE AND REG DECLARATION
//---------------------------------------------------------------------

reg [7:0] Xn_address[15:0];
reg [15:0] Xn_WEN;

wire [15:0] CEN;
wire [15:0] OEN;

reg [7:0] Wn_address[15:0];
reg [15:0] Wn_WEN;

reg [4:0] size_store;

wire [7:0] W_in_address_cal, X_in_address_cal, cal_tmp;
wire [3:0] W_in_mem_cal, X_in_mem_cal;
wire [15:0] X_Q_wire [15:0];
wire [15:0] W_Q_wire [15:0];

reg [15:0] MAC_X_in [15:0];
reg [15:0] MAC_W_in [15:0];
wire [39:0] ans;

reg [11:0] address_counter;

//---------------------------------------------------------------------
//   FSM State Declaration             
//---------------------------------------------------------------------

reg [1:0] c_state, n_state;
reg [11:0] counter;
reg [5:0] counter2;
parameter STANDBY = 2'b00, READ_X = 2'b01, RESULT = 2'b10, READ_W = 2'b11;

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
        STANDBY:    if(in_valid) n_state = READ_X;
                    else n_state = STANDBY;
        READ_X:     if(counter == 16 * size_store * size_store - 1'b1) n_state = READ_W;
                    else n_state = READ_X;
        READ_W:     if(counter == 16 * size_store * size_store - 1'b1) n_state = RESULT;
                    else n_state = READ_W;
        RESULT:     if(counter == 12'd16 && counter2 == 3*size_store-1) n_state = STANDBY;
                    else n_state = RESULT;
        default:    n_state = STANDBY;
	endcase
end

always @(posedge clk or negedge rst_n) 
begin
    if(!rst_n)
        counter <= 0;
    else if((c_state == READ_X && n_state == READ_W) || (c_state == READ_W && n_state == RESULT))
        counter <= 0;
	else if(c_state == READ_X || c_state == READ_W || n_state == READ_X || in_valid2 == 1)
        counter <= counter + 1'b1;
    else if(c_state == STANDBY)
        counter <= 0;
    else 
        counter <= counter;
end

always @(posedge clk or negedge rst_n) 
begin
    if(!rst_n)
        counter2 <= 0;
    else if(in_valid2 == 1 || c_state != RESULT)
        counter2 <= 0;
	else if(c_state == RESULT)
        counter2 <= counter2 + 1'b1;
    else 
        counter2 <= counter2;
end

//---------------------------------------------------------------------
//   MEMORY
//---------------------------------------------------------------------

assign CEN = 0;
assign OEN = 0;

X_mem X_row0(.Q(X_Q_wire[0]), .CLK(clk), .CEN(CEN[0]), .WEN(Xn_WEN[0]), .A(Xn_address[0]), .D(matrix), .OEN(OEN[0]));
X_mem X_row1(.Q(X_Q_wire[1]), .CLK(clk), .CEN(CEN[1]), .WEN(Xn_WEN[1]), .A(Xn_address[1]), .D(matrix), .OEN(OEN[1]));
X_mem X_row2(.Q(X_Q_wire[2]), .CLK(clk), .CEN(CEN[2]), .WEN(Xn_WEN[2]), .A(Xn_address[2]), .D(matrix), .OEN(OEN[2]));
X_mem X_row3(.Q(X_Q_wire[3]), .CLK(clk), .CEN(CEN[3]), .WEN(Xn_WEN[3]), .A(Xn_address[3]), .D(matrix), .OEN(OEN[3]));
X_mem X_row4(.Q(X_Q_wire[4]), .CLK(clk), .CEN(CEN[4]), .WEN(Xn_WEN[4]), .A(Xn_address[4]), .D(matrix), .OEN(OEN[4]));
X_mem X_row5(.Q(X_Q_wire[5]), .CLK(clk), .CEN(CEN[5]), .WEN(Xn_WEN[5]), .A(Xn_address[5]), .D(matrix), .OEN(OEN[5]));
X_mem X_row6(.Q(X_Q_wire[6]), .CLK(clk), .CEN(CEN[6]), .WEN(Xn_WEN[6]), .A(Xn_address[6]), .D(matrix), .OEN(OEN[6]));
X_mem X_row7(.Q(X_Q_wire[7]), .CLK(clk), .CEN(CEN[7]), .WEN(Xn_WEN[7]), .A(Xn_address[7]), .D(matrix), .OEN(OEN[7]));
X_mem X_row8(.Q(X_Q_wire[8]), .CLK(clk), .CEN(CEN[8]), .WEN(Xn_WEN[8]), .A(Xn_address[8]), .D(matrix), .OEN(OEN[8]));
X_mem X_row9(.Q(X_Q_wire[9]), .CLK(clk), .CEN(CEN[9]), .WEN(Xn_WEN[9]), .A(Xn_address[9]), .D(matrix), .OEN(OEN[9]));
X_mem X_row10(.Q(X_Q_wire[10]), .CLK(clk), .CEN(CEN[10]), .WEN(Xn_WEN[10]), .A(Xn_address[10]), .D(matrix), .OEN(OEN[10]));
X_mem X_row11(.Q(X_Q_wire[11]), .CLK(clk), .CEN(CEN[11]), .WEN(Xn_WEN[11]), .A(Xn_address[11]), .D(matrix), .OEN(OEN[11]));
X_mem X_row12(.Q(X_Q_wire[12]), .CLK(clk), .CEN(CEN[12]), .WEN(Xn_WEN[12]), .A(Xn_address[12]), .D(matrix), .OEN(OEN[12]));
X_mem X_row13(.Q(X_Q_wire[13]), .CLK(clk), .CEN(CEN[13]), .WEN(Xn_WEN[13]), .A(Xn_address[13]), .D(matrix), .OEN(OEN[13]));
X_mem X_row14(.Q(X_Q_wire[14]), .CLK(clk), .CEN(CEN[14]), .WEN(Xn_WEN[14]), .A(Xn_address[14]), .D(matrix), .OEN(OEN[14]));
X_mem X_row15(.Q(X_Q_wire[15]), .CLK(clk), .CEN(CEN[15]), .WEN(Xn_WEN[15]), .A(Xn_address[15]), .D(matrix), .OEN(OEN[15]));


X_mem W_row0(.Q(W_Q_wire[0]), .CLK(clk), .CEN(CEN[0]), .WEN(Wn_WEN[0]), .A(Wn_address[0]), .D(matrix), .OEN(OEN[0]));
X_mem W_row1(.Q(W_Q_wire[1]), .CLK(clk), .CEN(CEN[1]), .WEN(Wn_WEN[1]), .A(Wn_address[1]), .D(matrix), .OEN(OEN[1]));
X_mem W_row2(.Q(W_Q_wire[2]), .CLK(clk), .CEN(CEN[2]), .WEN(Wn_WEN[2]), .A(Wn_address[2]), .D(matrix), .OEN(OEN[2]));
X_mem W_row3(.Q(W_Q_wire[3]), .CLK(clk), .CEN(CEN[3]), .WEN(Wn_WEN[3]), .A(Wn_address[3]), .D(matrix), .OEN(OEN[3]));
X_mem W_row4(.Q(W_Q_wire[4]), .CLK(clk), .CEN(CEN[4]), .WEN(Wn_WEN[4]), .A(Wn_address[4]), .D(matrix), .OEN(OEN[4]));
X_mem W_row5(.Q(W_Q_wire[5]), .CLK(clk), .CEN(CEN[5]), .WEN(Wn_WEN[5]), .A(Wn_address[5]), .D(matrix), .OEN(OEN[5]));
X_mem W_row6(.Q(W_Q_wire[6]), .CLK(clk), .CEN(CEN[6]), .WEN(Wn_WEN[6]), .A(Wn_address[6]), .D(matrix), .OEN(OEN[6]));
X_mem W_row7(.Q(W_Q_wire[7]), .CLK(clk), .CEN(CEN[7]), .WEN(Wn_WEN[7]), .A(Wn_address[7]), .D(matrix), .OEN(OEN[7]));
X_mem W_row8(.Q(W_Q_wire[8]), .CLK(clk), .CEN(CEN[8]), .WEN(Wn_WEN[8]), .A(Wn_address[8]), .D(matrix), .OEN(OEN[8]));
X_mem W_row9(.Q(W_Q_wire[9]), .CLK(clk), .CEN(CEN[9]), .WEN(Wn_WEN[9]), .A(Wn_address[9]), .D(matrix), .OEN(OEN[9]));
X_mem W_row10(.Q(W_Q_wire[10]), .CLK(clk), .CEN(CEN[10]), .WEN(Wn_WEN[10]), .A(Wn_address[10]), .D(matrix), .OEN(OEN[10]));
X_mem W_row11(.Q(W_Q_wire[11]), .CLK(clk), .CEN(CEN[11]), .WEN(Wn_WEN[11]), .A(Wn_address[11]), .D(matrix), .OEN(OEN[11]));
X_mem W_row12(.Q(W_Q_wire[12]), .CLK(clk), .CEN(CEN[12]), .WEN(Wn_WEN[12]), .A(Wn_address[12]), .D(matrix), .OEN(OEN[12]));
X_mem W_row13(.Q(W_Q_wire[13]), .CLK(clk), .CEN(CEN[13]), .WEN(Wn_WEN[13]), .A(Wn_address[13]), .D(matrix), .OEN(OEN[13]));
X_mem W_row14(.Q(W_Q_wire[14]), .CLK(clk), .CEN(CEN[14]), .WEN(Wn_WEN[14]), .A(Wn_address[14]), .D(matrix), .OEN(OEN[14]));
X_mem W_row15(.Q(W_Q_wire[15]), .CLK(clk), .CEN(CEN[15]), .WEN(Wn_WEN[15]), .A(Wn_address[15]), .D(matrix), .OEN(OEN[15]));

//---------------------------------------------------------------------
//   DESIGN
//---------------------------------------------------------------------

//*****************input circuit*****************//
always @(posedge clk or negedge rst_n) 
begin
    if(!rst_n)
        size_store <= 5'd2;
    else if(counter == 12'd0 && n_state == READ_X)
    begin
        if(matrix_size == 2'b11)
            size_store <= 16;
        else if(matrix_size == 2'b10)
            size_store <= 8;
        else if(matrix_size == 2'b01)
            size_store <= 4;
        else
            size_store <= 2;
    end
    else if(c_state == STANDBY)
        size_store <= 5'd2;
    else
        size_store <= size_store;
end

always @(*) 
begin
    if(counter == size_store * size_store * 16 - 1)
        address_counter = 0;
    else
        address_counter = counter + 1'b1;
end

assign cal_tmp = address_counter / (size_store * size_store);
assign X_in_address_cal = cal_tmp * size_store + (address_counter % size_store);
assign W_in_address_cal = address_counter / size_store;

genvar i;
generate
    for(i=0; i<16; i=i+1)
    begin
        always @(posedge clk or negedge rst_n) 
        begin
            if(!rst_n)
                Xn_address[i] <= 8'b0;
            else if(c_state == READ_X || n_state == READ_X)
                Xn_address[i] <= X_in_address_cal;
            else if(c_state == STANDBY)
                Xn_address[i] <= 8'b0;
            else if(c_state == RESULT && in_valid2 == 1)
                Xn_address[i] <= size_store * i_mat_idx;
            else if(c_state == RESULT && in_valid2 == 0)
                Xn_address[i] <= Xn_address[i] + 1'b1; 
            else
                Xn_address[i] <= Xn_address[i];
        end
    end
endgenerate

assign X_in_mem_cal = (address_counter % (size_store * size_store)) / size_store;
assign W_in_mem_cal = address_counter % size_store;

genvar j;
generate
    for(j=0; j<16; j=j+1)
    begin
        always @(posedge clk or negedge rst_n) 
        begin
            if(!rst_n)
                Xn_WEN[j] <= 1'b0;
            else if((c_state == READ_X || n_state == READ_X) && n_state != READ_W)
            begin
                if(j == X_in_mem_cal)
                    Xn_WEN[j] <= 1'b0;
                else
                    Xn_WEN[j] <= 1'b1;
            end
            else if(c_state == STANDBY)
            begin
                if(j == 0)
                    Xn_WEN[j] <= 1'b0;
                else
                    Xn_WEN[j] <= 1'b1;
            end
            else
                Xn_WEN[j] <= 1'b1;
        end
    end 
endgenerate

genvar k;
generate
    for(k=0; k<16; k=k+1)
    begin
        always @(posedge clk or negedge rst_n) 
        begin
            if(!rst_n)
                Wn_address[k] <= 7'b0;
            else if(c_state == READ_W || n_state == READ_W)
                Wn_address[k] <= W_in_address_cal;
            else if(c_state == STANDBY)
                Wn_address[k] <= 7'b0;
            else if(c_state == RESULT && in_valid2 == 1)
                Wn_address[k] <= size_store * w_mat_idx;
            else if(c_state == RESULT && in_valid2 == 0)
                Wn_address[k] <= Wn_address[k] + 1'b1; 
            else
                Wn_address[k] <= Wn_address[k];
        end
    end
endgenerate

genvar m;
generate
    for(m=0; m<16; m=m+1)
    begin
        always @(posedge clk or negedge rst_n) 
        begin
            if(!rst_n)
                Wn_WEN[m] <= 1'b0;
            else if((c_state == READ_W || n_state == READ_W) && n_state != RESULT)
            begin
                if(m == W_in_mem_cal)
                    Wn_WEN[m] <= 1'b0;
                else
                    Wn_WEN[m] <= 1'b1;
            end
            else if(c_state == STANDBY)
            begin
                if(m == 0)
                    Wn_WEN[m] <= 1'b0;
                else
                    Wn_WEN[m] <= 1'b1;
            end
            else
                Wn_WEN[m] <= 1'b1;
        end
    end 
endgenerate

genvar mac_i;
generate
    for(mac_i=0; mac_i<16; mac_i=mac_i+1)
    begin
        always @(*) 
        begin
            if(c_state == RESULT && counter2 < size_store+1'b1 && counter2 > 0 && mac_i < size_store)
                MAC_X_in[mac_i] = X_Q_wire[mac_i];
            else
                MAC_X_in[mac_i] = 0;
        end
    end
endgenerate

genvar mac_j;
generate
    for(mac_j=0; mac_j<16; mac_j=mac_j+1)
    begin
        always @(*) 
        begin
            if(c_state == RESULT && counter2 < size_store+1'b1 && counter2 > 0 && mac_j < size_store)
                MAC_W_in[mac_j] = W_Q_wire[mac_j];
            else
                MAC_W_in[mac_j] = 0;
        end
    end
endgenerate

MAC mac (.counter(counter2), .clk(clk), .size_store(size_store), .in_valid2(in_valid2),
            .in0(MAC_X_in[0]), .in1(MAC_X_in[1]), .in2(MAC_X_in[2]), .in3(MAC_X_in[3]), .in4(MAC_X_in[4]), .in5(MAC_X_in[5]), .in6(MAC_X_in[6]), .in7(MAC_X_in[7]), 
            .in8(MAC_X_in[8]), .in9(MAC_X_in[9]), .in10(MAC_X_in[10]), .in11(MAC_X_in[11]), .in12(MAC_X_in[12]), .in13(MAC_X_in[13]), .in14(MAC_X_in[14]), .in15(MAC_X_in[15]), 
            .w0(MAC_W_in[0]), .w1(MAC_W_in[1]), .w2(MAC_W_in[2]), .w3(MAC_W_in[3]), .w4(MAC_W_in[4]), .w5(MAC_W_in[5]), .w6(MAC_W_in[6]), .w7(MAC_W_in[7]), 
            .w8(MAC_W_in[8]), .w9(MAC_W_in[9]), .w10(MAC_W_in[10]), .w11(MAC_W_in[11]), .w12(MAC_W_in[12]), .w13(MAC_W_in[13]), .w14(MAC_W_in[14]), .w15(MAC_W_in[15]), 
            .ans(ans));

//*****************output circuit*****************//
always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        out_valid <= 0;
    else if(counter2 > size_store && counter2 < 3*size_store)
        out_valid <= 1;
    else
        out_valid <= 0;
end

always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        out_value <= 0;
    else if(counter2 > size_store && counter2 < 3*size_store)
        out_value <= ans;
    else
        out_value <= 0;
end

endmodule

module MAC(counter, clk, size_store, in_valid2, in0, in1, in2, in3, in4, in5, in6, in7, in8, in9, in10, in11, in12, in13, in14, in15, 
            w0, w1, w2, w3, w4, w5, w6, w7, w8, w9, w10, w11, w12, w13, w14, w15, ans);

    input clk, in_valid2;
    input [5:0] counter;
    input [4:0] size_store;
    input signed[15:0] in0, in1, in2, in3, in4, in5, in6, in7, in8, in9, in10, in11, in12, in13, in14, in15;
    input signed[15:0] w0, w1, w2, w3, w4, w5, w6, w7, w8, w9, w10, w11, w12, w13, w14, w15;
    output signed[39:0] ans;

    wire signed[15:0] w_in[15:0];
    wire signed[15:0] X_in [15:0];

    reg signed [39:0] add_value[15:0];
    reg signed [39:0] ans_matrix[15:0][15:0];
    
    assign w_in[0] = w0;
    assign w_in[1] = w1;
    assign w_in[2] = w2;
    assign w_in[3] = w3;
    assign w_in[4] = w4;
    assign w_in[5] = w5;
    assign w_in[6] = w6;
    assign w_in[7] = w7;
    assign w_in[8] = w8;
    assign w_in[9] = w9;
    assign w_in[10] = w10;
    assign w_in[11] = w11;
    assign w_in[12] = w12;
    assign w_in[13] = w13;
    assign w_in[14] = w14;
    assign w_in[15] = w15;

    assign X_in[0] = in0;
    assign X_in[1] = in1;
    assign X_in[2] = in2;
    assign X_in[3] = in3;
    assign X_in[4] = in4;
    assign X_in[5] = in5;
    assign X_in[6] = in6;
    assign X_in[7] = in7;
    assign X_in[8] = in8;
    assign X_in[9] = in9;
    assign X_in[10] = in10;
    assign X_in[11] = in11;
    assign X_in[12] = in12;
    assign X_in[13] = in13;
    assign X_in[14] = in14;
    assign X_in[15] = in15;
    

    genvar ans_i, ans_j;
    generate
        for(ans_i=0; ans_i<16; ans_i=ans_i+1)
        begin
            for(ans_j=0; ans_j<16; ans_j=ans_j+1)
            begin
                always @(posedge clk) 
                begin
                    if(in_valid2 == 1)
                        ans_matrix[ans_i][ans_j] <= 0;
                    else
                        ans_matrix[ans_i][ans_j] <= ans_matrix[ans_i][ans_j] + X_in[ans_i] * w_in[ans_j];
                end
            end
        end
    endgenerate

    genvar add_i;
    generate
        for(add_i=0; add_i<16; add_i=add_i+1)
        begin
            always @(*) 
            begin
                if(counter - size_store - 1 >= add_i && (add_i + 16 > counter - size_store - 1))
                    add_value[add_i] = ans_matrix[counter - size_store - 1 - add_i][add_i];
                else
                    add_value[add_i] = 0;
            end
        end
    endgenerate

    assign ans = add_value[0] + add_value[1] + add_value[2] + add_value[3] + add_value[4] + add_value[5] + add_value[6] + add_value[7] +
                add_value[8] + add_value[9] + add_value[10] + add_value[11] + add_value[12] + add_value[13] + add_value[14] + add_value[15]; 

endmodule