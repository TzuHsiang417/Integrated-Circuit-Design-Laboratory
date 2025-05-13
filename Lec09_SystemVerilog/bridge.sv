module bridge(input clk, INF.bridge_inf inf);

//================================================================
// logic 
//================================================================
logic [2:0] c_state, n_state;
logic [7:0] address;
logic [63:0] write_data;
//================================================================
// state 
//================================================================
parameter STANDBY = 3'd0, WRITE = 3'd1, READ = 3'd2, WRITE_VALID = 3'd3, READ_VALID = 3'd4, OUT_VALID = 3'd5;
//================================================================
//   FSM
//================================================================

always_ff @(posedge clk or negedge inf.rst_n)
begin
    if(!inf.rst_n)
        c_state <= STANDBY;
    else
        c_state <= n_state;
end

always_comb
begin
    case(c_state)
        STANDBY:    if(inf.C_in_valid)
                    begin
                        if(inf.C_r_wb)
                            n_state = READ;
                        else
                            n_state = WRITE;
                    end
                    else n_state = STANDBY;
        WRITE:      if(inf.AW_READY) n_state = WRITE_VALID;
                    else n_state = WRITE;
        READ:       if(inf.AR_READY) n_state = READ_VALID;
                    else n_state = READ;
        WRITE_VALID:if(inf.B_VALID) n_state = OUT_VALID;
                    else n_state = WRITE_VALID;
        READ_VALID: if(inf.R_VALID) n_state = OUT_VALID;
                    else n_state = READ_VALID;
        OUT_VALID:  n_state = STANDBY;
        default:    n_state = STANDBY;
	endcase
end

//================================================================
//   INPUT circuit from design
//================================================================

always_ff @(posedge clk or negedge inf.rst_n)
begin
    if(!inf.rst_n)
        address <= 0;
    else if(inf.C_in_valid)
        address <= inf.C_addr;
    else
        address <= address;
end

always_ff @(posedge clk or negedge inf.rst_n)
begin
    if(!inf.rst_n)
        write_data <= 0;
    else if(inf.C_in_valid && !inf.C_r_wb)
        write_data <= inf.C_data_w;
    else
        write_data <= write_data;
end

//================================================================
//   OUTPUT circuit to design
//================================================================

always_ff @(posedge clk or negedge inf.rst_n)
begin
    if(!inf.rst_n)
        inf.C_out_valid <= 0;
    else if(n_state == OUT_VALID)
        inf.C_out_valid <= 1;
    else
        inf.C_out_valid <= 0;
end

always_ff @(posedge clk or negedge inf.rst_n)
begin
    if(!inf.rst_n)
        inf.C_data_r <= 0;
    else if(inf.R_VALID)
        inf.C_data_r <= inf.R_DATA;
    else
        inf.C_data_r <= inf.C_data_r;
end

//================================================================
//   SIGNAL to DRAM
//================================================================

always_comb
begin
    if(c_state == READ)
        inf.AR_VALID = 1;
    else 
        inf.AR_VALID = 0;
end

always_comb
begin
    if(c_state == READ)
        inf.AR_ADDR = {1'b1, 5'd0, address, 3'd0};
    else
        inf.AR_ADDR = 0;
end

always_comb
begin
    if(c_state == READ_VALID)
        inf.R_READY = 1;
    else
        inf.R_READY = 0;
end

always_comb
begin
    if(c_state == WRITE)
        inf.AW_VALID = 1;
    else
        inf.AW_VALID = 0;
end

always_comb
begin
    if(c_state == WRITE)
        inf.AW_ADDR = {1'b1, 5'd0, address, 3'd0};
    else
        inf.AW_ADDR = 0;
end

assign inf.W_DATA = write_data ;

always_comb
begin
    if(c_state == WRITE_VALID)
        inf.W_VALID = 1;
    else
        inf.W_VALID = 0;
end

always_ff @(posedge clk or negedge inf.rst_n)
begin
    if(!inf.rst_n)
        inf.B_READY <= 0;
    else
        inf.B_READY <= 1;
end

endmodule