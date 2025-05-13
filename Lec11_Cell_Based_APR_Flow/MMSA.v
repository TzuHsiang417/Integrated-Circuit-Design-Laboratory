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
input matrix;
input [1:0]  matrix_size;
input i_mat_idx, w_mat_idx;

output reg       	    out_valid;
output reg              out_value;
//---------------------------------------------------------------------
//   PARAMETER
//---------------------------------------------------------------------


//---------------------------------------------------------------------
//   WIRE AND REG DECLARATION
//---------------------------------------------------------------------

reg [6:0] Xn_address[7:0];/////////////////////////////////
reg [7:0] Xn_WEN;/////////////////////////////////

wire CEN;
wire OEN;

reg [6:0] Wn_address[7:0];////////////////////////////////
reg [7:0] Wn_WEN;/////////////////////////////////

reg [3:0] size_store;

wire [7:0] W_in_address_cal, X_in_address_cal, cal_tmp;
wire [3:0] W_in_mem_cal, X_in_mem_cal;
wire [15:0] X_Q_wire [7:0];////////////////////////////////
wire [15:0] W_Q_wire [7:0];////////////////////////////////

reg [15:0] MAC_X_in [7:0];
reg [15:0] MAC_W_in [7:0];
wire [39:0] ans;

reg [11:0] address_counter;

reg [15:0] matrix_in;
reg [2:0] real_i_idx, real_w_idx;

reg [5:0] out_length, out_length_tmp, out_length_tmp2;

reg flag;
//---------------------------------------------------------------------
//   FSM State Declaration             
//---------------------------------------------------------------------

reg [1:0] c_state, n_state;
reg [11:0] counter;
reg [5:0] counter2;
reg [3:0] counter3;
reg [5:0] out_counter, real_out_counter;
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
        READ_X:     if(counter == 16 * size_store * size_store - 1'b1 && counter3 == 15) n_state = READ_W;
                    else n_state = READ_X;
        READ_W:     if(counter == 16 * size_store * size_store - 1'b1 && counter3 == 15) n_state = RESULT;
                    else n_state = READ_W;
        RESULT:     if(counter[11:2] == 16 && counter2 == 3*size_store) n_state = STANDBY;
                    else n_state = RESULT;
        default:    n_state = STANDBY;
	endcase
end

always @(posedge clk or negedge rst_n) 
begin
    if(!rst_n)
        counter3 <= 0;
    else if((c_state == READ_X && n_state == READ_W) || (c_state == READ_W && n_state == RESULT))
        counter3 <= 0;
	else if(c_state == READ_X || c_state == READ_W || in_valid == 1)
        counter3 <= counter3 + 1'b1;
    else if(c_state == STANDBY)
        counter3 <= 0;
    else 
        counter3 <= counter3;
end

always @(posedge clk or negedge rst_n) 
begin
    if(!rst_n)
        counter <= 0;
    else if((c_state == READ_X && n_state == READ_W) || (c_state == READ_W && n_state == RESULT))
        counter <= 0;
	else if((c_state == READ_X || c_state == READ_W) && counter3 == 15)
        counter <= counter + 1'b1;
    else if(in_valid2 == 1)
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
	else if(c_state == RESULT && (out_counter == 45 || out_counter == out_length_tmp + 6) && flag)
        counter2 <= counter2 + 1'b1;
    else 
        counter2 <= counter2;
end

always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        out_counter <= 0;
    else if(counter2 < size_store)
        out_counter <= 45;
    else if(c_state == STANDBY || out_counter == out_length_tmp + 6 || out_counter == 45)
        out_counter <= 0;
    else if(c_state == RESULT)
        out_counter <= out_counter + 1;
    else
        out_counter <= out_counter;
end

always @(*)
begin
    if(out_counter <= 5)
        real_out_counter = 45 - out_counter;
    else
        real_out_counter = 6 + out_length_tmp - out_counter ;
end
//---------------------------------------------------------------------
//   MEMORY
//---------------------------------------------------------------------

assign CEN = 0;
assign OEN = 0;

MEM_11 X_row0(.Q(X_Q_wire[0]), .CLK(clk), .CEN(CEN), .WEN(Xn_WEN[0]), .A(Xn_address[0]), .D(matrix_in), .OEN(OEN));
MEM_11 X_row1(.Q(X_Q_wire[1]), .CLK(clk), .CEN(CEN), .WEN(Xn_WEN[1]), .A(Xn_address[1]), .D(matrix_in), .OEN(OEN));
MEM_11 X_row2(.Q(X_Q_wire[2]), .CLK(clk), .CEN(CEN), .WEN(Xn_WEN[2]), .A(Xn_address[2]), .D(matrix_in), .OEN(OEN));
MEM_11 X_row3(.Q(X_Q_wire[3]), .CLK(clk), .CEN(CEN), .WEN(Xn_WEN[3]), .A(Xn_address[3]), .D(matrix_in), .OEN(OEN));
MEM_11 X_row4(.Q(X_Q_wire[4]), .CLK(clk), .CEN(CEN), .WEN(Xn_WEN[4]), .A(Xn_address[4]), .D(matrix_in), .OEN(OEN));
MEM_11 X_row5(.Q(X_Q_wire[5]), .CLK(clk), .CEN(CEN), .WEN(Xn_WEN[5]), .A(Xn_address[5]), .D(matrix_in), .OEN(OEN));
MEM_11 X_row6(.Q(X_Q_wire[6]), .CLK(clk), .CEN(CEN), .WEN(Xn_WEN[6]), .A(Xn_address[6]), .D(matrix_in), .OEN(OEN));
MEM_11 X_row7(.Q(X_Q_wire[7]), .CLK(clk), .CEN(CEN), .WEN(Xn_WEN[7]), .A(Xn_address[7]), .D(matrix_in), .OEN(OEN));


MEM_11 W_row0(.Q(W_Q_wire[0]), .CLK(clk), .CEN(CEN), .WEN(Wn_WEN[0]), .A(Wn_address[0]), .D(matrix_in), .OEN(OEN));
MEM_11 W_row1(.Q(W_Q_wire[1]), .CLK(clk), .CEN(CEN), .WEN(Wn_WEN[1]), .A(Wn_address[1]), .D(matrix_in), .OEN(OEN));
MEM_11 W_row2(.Q(W_Q_wire[2]), .CLK(clk), .CEN(CEN), .WEN(Wn_WEN[2]), .A(Wn_address[2]), .D(matrix_in), .OEN(OEN));
MEM_11 W_row3(.Q(W_Q_wire[3]), .CLK(clk), .CEN(CEN), .WEN(Wn_WEN[3]), .A(Wn_address[3]), .D(matrix_in), .OEN(OEN));
MEM_11 W_row4(.Q(W_Q_wire[4]), .CLK(clk), .CEN(CEN), .WEN(Wn_WEN[4]), .A(Wn_address[4]), .D(matrix_in), .OEN(OEN));
MEM_11 W_row5(.Q(W_Q_wire[5]), .CLK(clk), .CEN(CEN), .WEN(Wn_WEN[5]), .A(Wn_address[5]), .D(matrix_in), .OEN(OEN));
MEM_11 W_row6(.Q(W_Q_wire[6]), .CLK(clk), .CEN(CEN), .WEN(Wn_WEN[6]), .A(Wn_address[6]), .D(matrix_in), .OEN(OEN));
MEM_11 W_row7(.Q(W_Q_wire[7]), .CLK(clk), .CEN(CEN), .WEN(Wn_WEN[7]), .A(Wn_address[7]), .D(matrix_in), .OEN(OEN));

//---------------------------------------------------------------------
//   DESIGN
//---------------------------------------------------------------------

//*****************input circuit*****************//
always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        real_i_idx <= 0;
    else if(c_state == STANDBY)
        real_i_idx <= 0;
    else if(in_valid2)
    begin
        real_i_idx[0] <= i_mat_idx;
        real_i_idx[1] <= real_i_idx[0];
        real_i_idx[2] <= real_i_idx[1];
    end
    else
        real_i_idx <= real_i_idx;
end

always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        real_w_idx <= 0;
    else if(c_state == STANDBY)
        real_w_idx <= 0;
    else if(in_valid2)
    begin
        real_w_idx[0] <= w_mat_idx;
        real_w_idx[1] <= real_w_idx[0];
        real_w_idx[2] <= real_w_idx[1];
    end
    else
        real_w_idx <= real_w_idx;
end

always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        matrix_in[0] <= 0;
    else if(in_valid)
        matrix_in[0] <= matrix;
    else
        matrix_in[0] <= 0;
end

genvar i_m;
generate
    for(i_m = 1; i_m < 16; i_m = i_m + 1)
    begin
        always @(posedge clk or negedge rst_n)
        begin
            if(!rst_n)
                matrix_in[i_m] <= 0;
            else
                matrix_in[i_m] <= matrix_in[i_m-1];
        end
    end
endgenerate

always @(posedge clk or negedge rst_n) 
begin
    if(!rst_n)
        size_store <= 5'd2;
    else if(counter == 12'd0 && n_state == READ_X && counter3 == 0)
    begin
        if(matrix_size == 2'b10)
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
    /*if(counter == size_store * size_store * 16 - 1 && counter3 == 15)
        address_counter = 0;
    else*/
        address_counter = counter;
end

assign cal_tmp = address_counter / (size_store * size_store);
assign X_in_address_cal = cal_tmp * size_store + (address_counter % size_store);
assign W_in_address_cal = address_counter / size_store;

genvar i;
generate
    for(i=0; i<8; i=i+1)
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
                Xn_address[i] <= size_store * {real_i_idx, i_mat_idx};
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
    for(j=0; j<8; j=j+1)
    begin
        always @(posedge clk or negedge rst_n) 
        begin
            if(!rst_n)
                Xn_WEN[j] <= 1'b0;
            else if((c_state == READ_X || n_state == READ_X) && c_state != READ_W)
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
    for(k=0; k<8; k=k+1)
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
                Wn_address[k] <= size_store * {real_w_idx, w_mat_idx};
            else if(c_state == RESULT && in_valid2 == 0)
                Wn_address[k] <= Wn_address[k] + 1'b1; 
            else
                Wn_address[k] <= Wn_address[k];
        end
    end
endgenerate

genvar m;
generate
    for(m=0; m<8; m=m+1)
    begin
        always @(posedge clk or negedge rst_n) 
        begin
            if(!rst_n)
                Wn_WEN[m] <= 1'b0;
            else if((c_state == READ_W || n_state == READ_W) && c_state != RESULT)
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
    for(mac_i=0; mac_i<8; mac_i=mac_i+1)
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
    for(mac_j=0; mac_j<8; mac_j=mac_j+1)
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
            .w0(MAC_W_in[0]), .w1(MAC_W_in[1]), .w2(MAC_W_in[2]), .w3(MAC_W_in[3]), .w4(MAC_W_in[4]), .w5(MAC_W_in[5]), .w6(MAC_W_in[6]), .w7(MAC_W_in[7]),  
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

always @(*)
begin
    if(ans[39] == 1'b1)         out_length = 39;
    else if(ans[38] == 1'b1)    out_length = 38;
    else if(ans[37] == 1'b1)    out_length = 37;
    else if(ans[36] == 1'b1)    out_length = 36;
    else if(ans[35] == 1'b1)    out_length = 35;
    else if(ans[34] == 1'b1)    out_length = 34;
    else if(ans[33] == 1'b1)    out_length = 33;
    else if(ans[32] == 1'b1)    out_length = 32;
    else if(ans[31] == 1'b1)    out_length = 31;
    else if(ans[30] == 1'b1)    out_length = 30;
    else if(ans[29] == 1'b1)    out_length = 29;
    else if(ans[28] == 1'b1)    out_length = 28;
    else if(ans[27] == 1'b1)    out_length = 27;
    else if(ans[26] == 1'b1)    out_length = 26;
    else if(ans[25] == 1'b1)    out_length = 25;
    else if(ans[24] == 1'b1)    out_length = 24;
    else if(ans[23] == 1'b1)    out_length = 23;
    else if(ans[22] == 1'b1)    out_length = 22;
    else if(ans[21] == 1'b1)    out_length = 21;
    else if(ans[20] == 1'b1)    out_length = 20;
    else if(ans[19] == 1'b1)    out_length = 19;
    else if(ans[18] == 1'b1)    out_length = 18;
    else if(ans[17] == 1'b1)    out_length = 17;
    else if(ans[16] == 1'b1)    out_length = 16;
    else if(ans[15] == 1'b1)    out_length = 15;
    else if(ans[14] == 1'b1)    out_length = 14;
    else if(ans[13] == 1'b1)    out_length = 13;
    else if(ans[12] == 1'b1)    out_length = 12;
    else if(ans[11] == 1'b1)    out_length = 11;
    else if(ans[10] == 1'b1)    out_length = 10;
    else if(ans[9] == 1'b1)     out_length = 9;
    else if(ans[8] == 1'b1)     out_length = 8;
    else if(ans[7] == 1'b1)     out_length = 7;
    else if(ans[6] == 1'b1)     out_length = 6;
    else if(ans[5] == 1'b1)     out_length = 5;
    else if(ans[4] == 1'b1)     out_length = 4;
    else if(ans[3] == 1'b1)     out_length = 3;
    else if(ans[2] == 1'b1)     out_length = 2;
    else if(ans[1] == 1'b1)     out_length = 1;
    else                        out_length = 0;
    
end

always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        flag <= 0;
    else if(c_state == STANDBY)
        flag <= 0;
    else if(in_valid2)
        flag <= 1;
    else
        flag <= flag;
end

always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        out_length_tmp <= 0;
    else
        out_length_tmp <= out_length;
end

always @(*) 
begin
    out_length_tmp2 = out_length + 1'b1;    
end

always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        out_value <= 0;
    else if(counter2 > size_store && counter2 < 3*size_store)
    begin
        case (real_out_counter)
            45:     out_value <= out_length_tmp2[5];
            44:     out_value <= out_length_tmp2[4];
            43:     out_value <= out_length_tmp2[3];
            42:     out_value <= out_length_tmp2[2];
            41:     out_value <= out_length_tmp2[1];
            40:     out_value <= out_length_tmp2[0];
            39:     out_value <= ans[39];
            38:     out_value <= ans[38];
            37:     out_value <= ans[37];
            36:     out_value <= ans[36];
            35:     out_value <= ans[35];
            34:     out_value <= ans[34];
            33:     out_value <= ans[33];
            32:     out_value <= ans[32];
            31:     out_value <= ans[31];
            30:     out_value <= ans[30];
            29:     out_value <= ans[29];
            28:     out_value <= ans[28];
            27:     out_value <= ans[27];
            26:     out_value <= ans[26];
            25:     out_value <= ans[25];
            24:     out_value <= ans[24];
            23:     out_value <= ans[23];
            22:     out_value <= ans[22];
            21:     out_value <= ans[21];
            20:     out_value <= ans[20];
            19:     out_value <= ans[19];
            18:     out_value <= ans[18];
            17:     out_value <= ans[17];
            16:     out_value <= ans[16];
            15:     out_value <= ans[15];
            14:     out_value <= ans[14];
            13:     out_value <= ans[13];
            12:     out_value <= ans[12];
            11:     out_value <= ans[11];
            10:     out_value <= ans[10];
            9:      out_value <= ans[9];
            8:      out_value <= ans[8];
            7:      out_value <= ans[7];
            6:      out_value <= ans[6];
            5:      out_value <= ans[5];
            4:      out_value <= ans[4];
            3:      out_value <= ans[3];
            2:      out_value <= ans[2];
            1:      out_value <= ans[1];
            0:      out_value <= ans[0];
            default:out_value <= 0; 
        endcase
    end
    else
        out_value <= 0;
end

endmodule

module MAC(counter, clk, size_store, in_valid2, in0, in1, in2, in3, in4, in5, in6, in7, w0, w1, w2, w3, w4, w5, w6, w7, ans);

    input clk, in_valid2;
    input [5:0] counter;
    input [3:0] size_store;
    input signed[15:0] in0, in1, in2, in3, in4, in5, in6, in7;
    input signed[15:0] w0, w1, w2, w3, w4, w5, w6, w7;
    output signed[39:0] ans;

    wire signed[15:0] w_in[7:0];
    wire signed[15:0] X_in [7:0];

    reg signed [39:0] add_value[7:0];
    reg signed [39:0] ans_matrix[7:0][7:0];
    
    assign w_in[0] = w0;
    assign w_in[1] = w1;
    assign w_in[2] = w2;
    assign w_in[3] = w3;
    assign w_in[4] = w4;
    assign w_in[5] = w5;
    assign w_in[6] = w6;
    assign w_in[7] = w7;

    assign X_in[0] = in0;
    assign X_in[1] = in1;
    assign X_in[2] = in2;
    assign X_in[3] = in3;
    assign X_in[4] = in4;
    assign X_in[5] = in5;
    assign X_in[6] = in6;
    assign X_in[7] = in7;

    genvar ans_i, ans_j;
    generate
        for(ans_i=0; ans_i<8; ans_i=ans_i+1)
        begin
            for(ans_j=0; ans_j<8; ans_j=ans_j+1)
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
        for(add_i=0; add_i<8; add_i=add_i+1)
        begin
            always @(*) 
            begin
                if(counter - size_store - 1 >= add_i && (add_i + 8 > counter - size_store - 1))
                    add_value[add_i] = ans_matrix[counter - size_store - 1 - add_i][add_i];
                else
                    add_value[add_i] = 0;
            end
        end
    endgenerate

    assign ans = add_value[0] + add_value[1] + add_value[2] + add_value[3] + add_value[4] + add_value[5] + add_value[6] + add_value[7]; 

endmodule