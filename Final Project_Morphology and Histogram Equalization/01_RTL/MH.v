module MH(
	// Input signals
	clk,
    clk2,
	rst_n,
	in_valid,
    op_valid,
	pic_data,
    se_data,
    op,
	// Output signals
	out_valid,
    out_data
    // -----------------------------
);

//---------------------------------------------------------------------
//   PARAMETER
//---------------------------------------------------------------------
parameter ID_WIDTH = 4 , ADDR_WIDTH = 32, DATA_WIDTH = 128;
//---------------------------------------------------------------------
//   INPUT AND OUTPUT DECLARATION
//---------------------------------------------------------------------
input  clk, clk2, rst_n, in_valid, op_valid;
input [31:0] pic_data;
input [7:0] se_data;
input [2:0] op;
output reg	out_valid;
output reg [31:0] out_data;

//---------------------------------------------------------------------
//   WIRE AND REG DECLARATION
//---------------------------------------------------------------------
reg [3:0] mode;
reg [127:0] pic_in;

wire [127:0] pic_tmp;
//histogram
reg histogram_flag;
reg [9:0]histogram_cnt;
reg [5:0] histogram_address;
reg [10:0] cdf[254:0];
reg [7:0] histogram_value;
reg [8:0] minima;
reg [10:0] cdf_min;
reg [10:0] cdf_v;
reg start_cnt;


//SRAM
wire CEN, OEN;
reg WEN;
reg [5:0] sram_address;
reg [5:0] sram_address_cnt;
reg [5:0] sram_ans_cnt;
wire [127:0] sram_out;
reg [127:0] sram_in;
reg [7:0] sram_in_final;

//SE
reg [7:0] se_reg[15:0];

//image reg
reg [7:0] image_reg1[34:0];
reg [7:0] image_reg2[34:0];
reg [7:0] image_reg3[34:0];
reg [7:0] image_reg4[34:0];
reg [9:0] image_cnt;
wire [9:0] image_cnt2;
reg [7:0] target_image[15:0];
reg [4:0] target_cnt;

//erosion calcution
reg [7:0] erosion_cal_tmp[15:0];
wire [7:0] erosion_ans;

//dilation calcution
reg [7:0] dilation_cal_tmp[15:0];
wire [7:0] dilation_ans;

//calculation end
reg [7:0] calculation_ans[15:0];
reg [3:0] cal_cnt;
wire [7:0] histogram_ans;
wire [9:0] his_numerator;
wire [9:0] his_denomirator;
wire [17:0] his_shift;

//---------------------------------------------------------------------
//   FSM State Declaration             
//---------------------------------------------------------------------

reg [2:0] c_state, n_state;
reg [7:0] counter;
parameter STANDBY = 3'b000, READ_PATTERN = 3'b001, EROSION = 3'b010, DILATION = 3'b011, HISTOGRAM = 3'b101, ANS_OUT = 3'b111, SETTING = 3'b110;//WRITE_DRAM = 3'b110;READ_PIC = 3'b010, READ_SE = 3'b111

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
        STANDBY:        if(in_valid) n_state = READ_PATTERN;
                        else n_state = STANDBY;
        READ_PATTERN:   if(counter == 255 && (mode == 3'b010 || mode == 3'b110)) n_state = EROSION;
                        else if(counter == 255 && (mode == 3'b011 || mode == 3'b111)) n_state = DILATION;
                        else if(counter == 255 && mode == 3'b000) n_state = HISTOGRAM;
                        else n_state = READ_PATTERN;
        EROSION:        if(image_cnt == 1023 && mode == 3'b110) n_state = SETTING;
                        else if(image_cnt == 1023) n_state = ANS_OUT;
                        else n_state = EROSION;
        DILATION:       if(image_cnt == 1023 && mode == 3'b111) n_state = SETTING;
                        else if(image_cnt == 1023) n_state = ANS_OUT;
                        else n_state = DILATION;
        HISTOGRAM:      if(image_cnt == 1023) n_state = ANS_OUT;
                        else n_state = HISTOGRAM;
        SETTING:        if(sram_address_cnt == 8 && mode == 3'b110) n_state = DILATION;
                        else if(sram_address_cnt == 8 && mode == 3'b111) n_state = EROSION;
                        else n_state = SETTING;
        ANS_OUT:        if(counter == 255) n_state = STANDBY;
                        else n_state = ANS_OUT;
        default:        n_state = STANDBY;
	endcase
end

always @(posedge clk or negedge rst_n) 
begin
    if(!rst_n)
        counter <= 0;
	else if(in_valid || c_state == ANS_OUT)
        counter <= counter + 1'b1;
    else if(c_state == STANDBY || counter == 255)
        counter <= 0;
    else 
        counter <= counter;
end

always @(posedge clk or negedge rst_n) 
begin
    if(!rst_n)
        image_cnt <= 0;
	else if(c_state == EROSION || c_state == DILATION)
        image_cnt <= image_cnt + 1'b1;
    else if(c_state == HISTOGRAM && histogram_flag)
        image_cnt <= image_cnt + 1'b1;
    else if(c_state == STANDBY || c_state == SETTING)
        image_cnt <= 0;
    else 
        image_cnt <= image_cnt;
end

//---------------------------------------------------------------------
//   HISTOGRAM control             
//---------------------------------------------------------------------
always @(posedge clk or negedge rst_n) 
begin
    if(!rst_n)
        start_cnt <= 0;
    else if(c_state == STANDBY)    
        start_cnt <= 0;
    else if(c_state == HISTOGRAM)
        start_cnt <= 1;
    else
        start_cnt <= start_cnt;
end

always @(posedge clk or negedge rst_n) 
begin
    if(!rst_n)
        histogram_cnt <= 0;
	else if(c_state == HISTOGRAM && start_cnt)
        histogram_cnt <= histogram_cnt + 1'b1;
    else if(c_state == STANDBY)
        histogram_cnt <= 0;
    else 
        histogram_cnt <= histogram_cnt;
end

always @(posedge clk or negedge rst_n) 
begin
    if(!rst_n)
        histogram_flag <= 0;
	else if(histogram_cnt == 1023)
        histogram_flag <= 1'b1;
    else if(c_state == STANDBY)
        histogram_flag <= 0;
    else 
        histogram_flag <= histogram_flag;
end

always @(posedge clk or negedge rst_n) 
begin
    if(!rst_n)
        histogram_address <= 0;
	else if(c_state == HISTOGRAM && histogram_cnt[3:0] == 14 && start_cnt)
        histogram_address <= histogram_address + 1'b1;
    else if(c_state == STANDBY)
        histogram_address <= 0;
    else 
        histogram_address <= histogram_address;
end

always @(*) 
begin
    case (histogram_cnt[3:0])
        4'd0:   histogram_value = sram_out[7:0];
        4'd1:   histogram_value = sram_out[15:8];
        4'd2:   histogram_value = sram_out[23:16];
        4'd3:   histogram_value = sram_out[31:24];
        4'd4:   histogram_value = sram_out[39:32];
        4'd5:   histogram_value = sram_out[47:40];
        4'd6:   histogram_value = sram_out[55:48];
        4'd7:   histogram_value = sram_out[63:56];
        4'd8:   histogram_value = sram_out[71:64];
        4'd9:   histogram_value = sram_out[79:72];
        4'd10:  histogram_value = sram_out[87:80];
        4'd11:  histogram_value = sram_out[95:88];
        4'd12:  histogram_value = sram_out[103:96];
        4'd13:  histogram_value = sram_out[111:104];
        4'd14:  histogram_value = sram_out[119:112];
        4'd15:  histogram_value = sram_out[127:120];
        default: histogram_value = 0;
    endcase    
end

genvar i_cdf;
generate
    for (i_cdf=0; i_cdf<255; i_cdf=i_cdf+1) 
    begin
        always @(posedge clk or negedge rst_n) 
        begin
            if(!rst_n)
                cdf[i_cdf] <= 0;
            else if(histogram_value <= i_cdf && c_state == HISTOGRAM && histogram_flag == 1'b0 && start_cnt)
                cdf[i_cdf] <= cdf[i_cdf] + 1'b1;
            else if(c_state == STANDBY)
                cdf[i_cdf] <= 0;
            else
                cdf[i_cdf] <= cdf[i_cdf];
        end    
    end
endgenerate

always @(posedge clk or negedge rst_n) 
begin
    if(!rst_n)
        minima <= 256;
    else if(histogram_value < minima && c_state == HISTOGRAM && histogram_flag == 1'b0 && start_cnt)
        minima <= histogram_value;
    else if(c_state == STANDBY)
        minima <= 256;
    else
        minima <= minima;
end

always @(*) 
begin
    case (minima)
        9'd0:    cdf_min = cdf[0];
        9'd1:    cdf_min = cdf[1];
        9'd2:    cdf_min = cdf[2];
        9'd3:    cdf_min = cdf[3];
        9'd4:    cdf_min = cdf[4];
        9'd5:    cdf_min = cdf[5];
        9'd6:    cdf_min = cdf[6];
        9'd7:    cdf_min = cdf[7];
        9'd8:    cdf_min = cdf[8];
        9'd9:    cdf_min = cdf[9];
        9'd10:   cdf_min = cdf[10];
        9'd11:   cdf_min = cdf[11];
        9'd12:   cdf_min = cdf[12];
        9'd13:   cdf_min = cdf[13];
        9'd14:   cdf_min = cdf[14];
        9'd15:   cdf_min = cdf[15];
        9'd16:   cdf_min = cdf[16];
        9'd17:   cdf_min = cdf[17];
        9'd18:   cdf_min = cdf[18];
        9'd19:   cdf_min = cdf[19];
        9'd20:   cdf_min = cdf[20];
        9'd21:   cdf_min = cdf[21];
        9'd22:   cdf_min = cdf[22];
        9'd23:   cdf_min = cdf[23];
        9'd24:   cdf_min = cdf[24];
        9'd25:   cdf_min = cdf[25];
        9'd26:   cdf_min = cdf[26];
        9'd27:   cdf_min = cdf[27];
        9'd28:   cdf_min = cdf[28];
        9'd29:   cdf_min = cdf[29];
        9'd30:   cdf_min = cdf[30];
        9'd31:   cdf_min = cdf[31];
        9'd32:   cdf_min = cdf[32];
        9'd33:   cdf_min = cdf[33];
        9'd34:   cdf_min = cdf[34];
        9'd35:   cdf_min = cdf[35];
        9'd36:   cdf_min = cdf[36];
        9'd37:   cdf_min = cdf[37];
        9'd38:   cdf_min = cdf[38];
        9'd39:   cdf_min = cdf[39];
        9'd40:   cdf_min = cdf[40];
        9'd41:   cdf_min = cdf[41];
        9'd42:   cdf_min = cdf[42];
        9'd43:   cdf_min = cdf[43];
        9'd44:   cdf_min = cdf[44];
        9'd45:   cdf_min = cdf[45];
        9'd46:   cdf_min = cdf[46];
        9'd47:   cdf_min = cdf[47];
        9'd48:   cdf_min = cdf[48];
        9'd49:   cdf_min = cdf[49];
        9'd50:   cdf_min = cdf[50];
        9'd51:   cdf_min = cdf[51];
        9'd52:   cdf_min = cdf[52];
        9'd53:   cdf_min = cdf[53];
        9'd54:   cdf_min = cdf[54];
        9'd55:   cdf_min = cdf[55];
        9'd56:   cdf_min = cdf[56];
        9'd57:   cdf_min = cdf[57];
        9'd58:   cdf_min = cdf[58];
        9'd59:   cdf_min = cdf[59];
        9'd60:   cdf_min = cdf[60];
        9'd61:   cdf_min = cdf[61];
        9'd62:   cdf_min = cdf[62];
        9'd63:   cdf_min = cdf[63];
        9'd64:   cdf_min = cdf[64];
        9'd65:   cdf_min = cdf[65];
        9'd66:   cdf_min = cdf[66];
        9'd67:   cdf_min = cdf[67];
        9'd68:   cdf_min = cdf[68];
        9'd69:   cdf_min = cdf[69];
        9'd70:   cdf_min = cdf[70];
        9'd71:   cdf_min = cdf[71];
        9'd72:   cdf_min = cdf[72];
        9'd73:   cdf_min = cdf[73];
        9'd74:   cdf_min = cdf[74];
        9'd75:   cdf_min = cdf[75];
        9'd76:   cdf_min = cdf[76];
        9'd77:   cdf_min = cdf[77];
        9'd78:   cdf_min = cdf[78];
        9'd79:   cdf_min = cdf[79];
        9'd80:   cdf_min = cdf[80];
        9'd81:   cdf_min = cdf[81];
        9'd82:   cdf_min = cdf[82];
        9'd83:   cdf_min = cdf[83];
        9'd84:   cdf_min = cdf[84];
        9'd85:   cdf_min = cdf[85];
        9'd86:   cdf_min = cdf[86];
        9'd87:   cdf_min = cdf[87];
        9'd88:   cdf_min = cdf[88];
        9'd89:   cdf_min = cdf[89];
        9'd90:   cdf_min = cdf[90];
        9'd91:   cdf_min = cdf[91];
        9'd92:   cdf_min = cdf[92];
        9'd93:   cdf_min = cdf[93];
        9'd94:   cdf_min = cdf[94];
        9'd95:   cdf_min = cdf[95];
        9'd96:   cdf_min = cdf[96];
        9'd97:   cdf_min = cdf[97];
        9'd98:   cdf_min = cdf[98];
        9'd99:   cdf_min = cdf[99];
        9'd100:  cdf_min = cdf[100];
        9'd101:  cdf_min = cdf[101];
        9'd102:  cdf_min = cdf[102];
        9'd103:  cdf_min = cdf[103];
        9'd104:  cdf_min = cdf[104];
        9'd105:  cdf_min = cdf[105];
        9'd106:  cdf_min = cdf[106];
        9'd107:  cdf_min = cdf[107];
        9'd108:  cdf_min = cdf[108];
        9'd109:  cdf_min = cdf[109];
        9'd110:  cdf_min = cdf[110];
        9'd111:  cdf_min = cdf[111];
        9'd112:  cdf_min = cdf[112];
        9'd113:  cdf_min = cdf[113];
        9'd114:  cdf_min = cdf[114];
        9'd115:  cdf_min = cdf[115];
        9'd116:  cdf_min = cdf[116];
        9'd117:  cdf_min = cdf[117];
        9'd118:  cdf_min = cdf[118];
        9'd119:  cdf_min = cdf[119];
        9'd120:  cdf_min = cdf[120];
        9'd121:  cdf_min = cdf[121];
        9'd122:  cdf_min = cdf[122];
        9'd123:  cdf_min = cdf[123];
        9'd124:  cdf_min = cdf[124];
        9'd125:  cdf_min = cdf[125];
        9'd126:  cdf_min = cdf[126];
        9'd127:  cdf_min = cdf[127];
        9'd128:  cdf_min = cdf[128];
        9'd129:  cdf_min = cdf[129];
        9'd130:  cdf_min = cdf[130];
        9'd131:  cdf_min = cdf[131];
        9'd132:  cdf_min = cdf[132];
        9'd133:  cdf_min = cdf[133];
        9'd134:  cdf_min = cdf[134];
        9'd135:  cdf_min = cdf[135];
        9'd136:  cdf_min = cdf[136];
        9'd137:  cdf_min = cdf[137];
        9'd138:  cdf_min = cdf[138];
        9'd139:  cdf_min = cdf[139];
        9'd140:  cdf_min = cdf[140];
        9'd141:  cdf_min = cdf[141];
        9'd142:  cdf_min = cdf[142];
        9'd143:  cdf_min = cdf[143];
        9'd144:  cdf_min = cdf[144];
        9'd145:  cdf_min = cdf[145];
        9'd146:  cdf_min = cdf[146];
        9'd147:  cdf_min = cdf[147];
        9'd148:  cdf_min = cdf[148];
        9'd149:  cdf_min = cdf[149];
        9'd150:  cdf_min = cdf[150];
        9'd151:  cdf_min = cdf[151];
        9'd152:  cdf_min = cdf[152];
        9'd153:  cdf_min = cdf[153];
        9'd154:  cdf_min = cdf[154];
        9'd155:  cdf_min = cdf[155];
        9'd156:  cdf_min = cdf[156];
        9'd157:  cdf_min = cdf[157];
        9'd158:  cdf_min = cdf[158];
        9'd159:  cdf_min = cdf[159];
        9'd160:  cdf_min = cdf[160];
        9'd161:  cdf_min = cdf[161];
        9'd162:  cdf_min = cdf[162];
        9'd163:  cdf_min = cdf[163];
        9'd164:  cdf_min = cdf[164];
        9'd165:  cdf_min = cdf[165];
        9'd166:  cdf_min = cdf[166];
        9'd167:  cdf_min = cdf[167];
        9'd168:  cdf_min = cdf[168];
        9'd169:  cdf_min = cdf[169];
        9'd170:  cdf_min = cdf[170];
        9'd171:  cdf_min = cdf[171];
        9'd172:  cdf_min = cdf[172];
        9'd173:  cdf_min = cdf[173];
        9'd174:  cdf_min = cdf[174];
        9'd175:  cdf_min = cdf[175];
        9'd176:  cdf_min = cdf[176];
        9'd177:  cdf_min = cdf[177];
        9'd178:  cdf_min = cdf[178];
        9'd179:  cdf_min = cdf[179];
        9'd180:  cdf_min = cdf[180];
        9'd181:  cdf_min = cdf[181];
        9'd182:  cdf_min = cdf[182];
        9'd183:  cdf_min = cdf[183];
        9'd184:  cdf_min = cdf[184];
        9'd185:  cdf_min = cdf[185];
        9'd186:  cdf_min = cdf[186];
        9'd187:  cdf_min = cdf[187];
        9'd188:  cdf_min = cdf[188];
        9'd189:  cdf_min = cdf[189];
        9'd190:  cdf_min = cdf[190];
        9'd191:  cdf_min = cdf[191];
        9'd192:  cdf_min = cdf[192];
        9'd193:  cdf_min = cdf[193];
        9'd194:  cdf_min = cdf[194];
        9'd195:  cdf_min = cdf[195];
        9'd196:  cdf_min = cdf[196];
        9'd197:  cdf_min = cdf[197];
        9'd198:  cdf_min = cdf[198];
        9'd199:  cdf_min = cdf[199];
        9'd200:  cdf_min = cdf[200];
        9'd201:  cdf_min = cdf[201];
        9'd202:  cdf_min = cdf[202];
        9'd203:  cdf_min = cdf[203];
        9'd204:  cdf_min = cdf[204];
        9'd205:  cdf_min = cdf[205];
        9'd206:  cdf_min = cdf[206];
        9'd207:  cdf_min = cdf[207];
        9'd208:  cdf_min = cdf[208];
        9'd209:  cdf_min = cdf[209];
        9'd210:  cdf_min = cdf[210];
        9'd211:  cdf_min = cdf[211];
        9'd212:  cdf_min = cdf[212];
        9'd213:  cdf_min = cdf[213];
        9'd214:  cdf_min = cdf[214];
        9'd215:  cdf_min = cdf[215];
        9'd216:  cdf_min = cdf[216];
        9'd217:  cdf_min = cdf[217];
        9'd218:  cdf_min = cdf[218];
        9'd219:  cdf_min = cdf[219];
        9'd220:  cdf_min = cdf[220];
        9'd221:  cdf_min = cdf[221];
        9'd222:  cdf_min = cdf[222];
        9'd223:  cdf_min = cdf[223];
        9'd224:  cdf_min = cdf[224];
        9'd225:  cdf_min = cdf[225];
        9'd226:  cdf_min = cdf[226];
        9'd227:  cdf_min = cdf[227];
        9'd228:  cdf_min = cdf[228];
        9'd229:  cdf_min = cdf[229];
        9'd230:  cdf_min = cdf[230];
        9'd231:  cdf_min = cdf[231];
        9'd232:  cdf_min = cdf[232];
        9'd233:  cdf_min = cdf[233];
        9'd234:  cdf_min = cdf[234];
        9'd235:  cdf_min = cdf[235];
        9'd236:  cdf_min = cdf[236];
        9'd237:  cdf_min = cdf[237];
        9'd238:  cdf_min = cdf[238];
        9'd239:  cdf_min = cdf[239];
        9'd240:  cdf_min = cdf[240];
        9'd241:  cdf_min = cdf[241];
        9'd242:  cdf_min = cdf[242];
        9'd243:  cdf_min = cdf[243];
        9'd244:  cdf_min = cdf[244];
        9'd245:  cdf_min = cdf[245];
        9'd246:  cdf_min = cdf[246];
        9'd247:  cdf_min = cdf[247];
        9'd248:  cdf_min = cdf[248];
        9'd249:  cdf_min = cdf[249];
        9'd250:  cdf_min = cdf[250];
        9'd251:  cdf_min = cdf[251];
        9'd252:  cdf_min = cdf[252];
        9'd253:  cdf_min = cdf[253];
        9'd254:  cdf_min = cdf[254];
        9'd255:  cdf_min = 1024;
        default: cdf_min = 0;
    endcase    
end

always @(*) 
begin
    case (target_image[0])
        8'd0:    cdf_v = cdf[0];
        8'd1:    cdf_v = cdf[1];
        8'd2:    cdf_v = cdf[2];
        8'd3:    cdf_v = cdf[3];
        8'd4:    cdf_v = cdf[4];
        8'd5:    cdf_v = cdf[5];
        8'd6:    cdf_v = cdf[6];
        8'd7:    cdf_v = cdf[7];
        8'd8:    cdf_v = cdf[8];
        8'd9:    cdf_v = cdf[9];
        8'd10:   cdf_v = cdf[10];
        8'd11:   cdf_v = cdf[11];
        8'd12:   cdf_v = cdf[12];
        8'd13:   cdf_v = cdf[13];
        8'd14:   cdf_v = cdf[14];
        8'd15:   cdf_v = cdf[15];
        8'd16:   cdf_v = cdf[16];
        8'd17:   cdf_v = cdf[17];
        8'd18:   cdf_v = cdf[18];
        8'd19:   cdf_v = cdf[19];
        8'd20:   cdf_v = cdf[20];
        8'd21:   cdf_v = cdf[21];
        8'd22:   cdf_v = cdf[22];
        8'd23:   cdf_v = cdf[23];
        8'd24:   cdf_v = cdf[24];
        8'd25:   cdf_v = cdf[25];
        8'd26:   cdf_v = cdf[26];
        8'd27:   cdf_v = cdf[27];
        8'd28:   cdf_v = cdf[28];
        8'd29:   cdf_v = cdf[29];
        8'd30:   cdf_v = cdf[30];
        8'd31:   cdf_v = cdf[31];
        8'd32:   cdf_v = cdf[32];
        8'd33:   cdf_v = cdf[33];
        8'd34:   cdf_v = cdf[34];
        8'd35:   cdf_v = cdf[35];
        8'd36:   cdf_v = cdf[36];
        8'd37:   cdf_v = cdf[37];
        8'd38:   cdf_v = cdf[38];
        8'd39:   cdf_v = cdf[39];
        8'd40:   cdf_v = cdf[40];
        8'd41:   cdf_v = cdf[41];
        8'd42:   cdf_v = cdf[42];
        8'd43:   cdf_v = cdf[43];
        8'd44:   cdf_v = cdf[44];
        8'd45:   cdf_v = cdf[45];
        8'd46:   cdf_v = cdf[46];
        8'd47:   cdf_v = cdf[47];
        8'd48:   cdf_v = cdf[48];
        8'd49:   cdf_v = cdf[49];
        8'd50:   cdf_v = cdf[50];
        8'd51:   cdf_v = cdf[51];
        8'd52:   cdf_v = cdf[52];
        8'd53:   cdf_v = cdf[53];
        8'd54:   cdf_v = cdf[54];
        8'd55:   cdf_v = cdf[55];
        8'd56:   cdf_v = cdf[56];
        8'd57:   cdf_v = cdf[57];
        8'd58:   cdf_v = cdf[58];
        8'd59:   cdf_v = cdf[59];
        8'd60:   cdf_v = cdf[60];
        8'd61:   cdf_v = cdf[61];
        8'd62:   cdf_v = cdf[62];
        8'd63:   cdf_v = cdf[63];
        8'd64:   cdf_v = cdf[64];
        8'd65:   cdf_v = cdf[65];
        8'd66:   cdf_v = cdf[66];
        8'd67:   cdf_v = cdf[67];
        8'd68:   cdf_v = cdf[68];
        8'd69:   cdf_v = cdf[69];
        8'd70:   cdf_v = cdf[70];
        8'd71:   cdf_v = cdf[71];
        8'd72:   cdf_v = cdf[72];
        8'd73:   cdf_v = cdf[73];
        8'd74:   cdf_v = cdf[74];
        8'd75:   cdf_v = cdf[75];
        8'd76:   cdf_v = cdf[76];
        8'd77:   cdf_v = cdf[77];
        8'd78:   cdf_v = cdf[78];
        8'd79:   cdf_v = cdf[79];
        8'd80:   cdf_v = cdf[80];
        8'd81:   cdf_v = cdf[81];
        8'd82:   cdf_v = cdf[82];
        8'd83:   cdf_v = cdf[83];
        8'd84:   cdf_v = cdf[84];
        8'd85:   cdf_v = cdf[85];
        8'd86:   cdf_v = cdf[86];
        8'd87:   cdf_v = cdf[87];
        8'd88:   cdf_v = cdf[88];
        8'd89:   cdf_v = cdf[89];
        8'd90:   cdf_v = cdf[90];
        8'd91:   cdf_v = cdf[91];
        8'd92:   cdf_v = cdf[92];
        8'd93:   cdf_v = cdf[93];
        8'd94:   cdf_v = cdf[94];
        8'd95:   cdf_v = cdf[95];
        8'd96:   cdf_v = cdf[96];
        8'd97:   cdf_v = cdf[97];
        8'd98:   cdf_v = cdf[98];
        8'd99:   cdf_v = cdf[99];
        8'd100:  cdf_v = cdf[100];
        8'd101:  cdf_v = cdf[101];
        8'd102:  cdf_v = cdf[102];
        8'd103:  cdf_v = cdf[103];
        8'd104:  cdf_v = cdf[104];
        8'd105:  cdf_v = cdf[105];
        8'd106:  cdf_v = cdf[106];
        8'd107:  cdf_v = cdf[107];
        8'd108:  cdf_v = cdf[108];
        8'd109:  cdf_v = cdf[109];
        8'd110:  cdf_v = cdf[110];
        8'd111:  cdf_v = cdf[111];
        8'd112:  cdf_v = cdf[112];
        8'd113:  cdf_v = cdf[113];
        8'd114:  cdf_v = cdf[114];
        8'd115:  cdf_v = cdf[115];
        8'd116:  cdf_v = cdf[116];
        8'd117:  cdf_v = cdf[117];
        8'd118:  cdf_v = cdf[118];
        8'd119:  cdf_v = cdf[119];
        8'd120:  cdf_v = cdf[120];
        8'd121:  cdf_v = cdf[121];
        8'd122:  cdf_v = cdf[122];
        8'd123:  cdf_v = cdf[123];
        8'd124:  cdf_v = cdf[124];
        8'd125:  cdf_v = cdf[125];
        8'd126:  cdf_v = cdf[126];
        8'd127:  cdf_v = cdf[127];
        8'd128:  cdf_v = cdf[128];
        8'd129:  cdf_v = cdf[129];
        8'd130:  cdf_v = cdf[130];
        8'd131:  cdf_v = cdf[131];
        8'd132:  cdf_v = cdf[132];
        8'd133:  cdf_v = cdf[133];
        8'd134:  cdf_v = cdf[134];
        8'd135:  cdf_v = cdf[135];
        8'd136:  cdf_v = cdf[136];
        8'd137:  cdf_v = cdf[137];
        8'd138:  cdf_v = cdf[138];
        8'd139:  cdf_v = cdf[139];
        8'd140:  cdf_v = cdf[140];
        8'd141:  cdf_v = cdf[141];
        8'd142:  cdf_v = cdf[142];
        8'd143:  cdf_v = cdf[143];
        8'd144:  cdf_v = cdf[144];
        8'd145:  cdf_v = cdf[145];
        8'd146:  cdf_v = cdf[146];
        8'd147:  cdf_v = cdf[147];
        8'd148:  cdf_v = cdf[148];
        8'd149:  cdf_v = cdf[149];
        8'd150:  cdf_v = cdf[150];
        8'd151:  cdf_v = cdf[151];
        8'd152:  cdf_v = cdf[152];
        8'd153:  cdf_v = cdf[153];
        8'd154:  cdf_v = cdf[154];
        8'd155:  cdf_v = cdf[155];
        8'd156:  cdf_v = cdf[156];
        8'd157:  cdf_v = cdf[157];
        8'd158:  cdf_v = cdf[158];
        8'd159:  cdf_v = cdf[159];
        8'd160:  cdf_v = cdf[160];
        8'd161:  cdf_v = cdf[161];
        8'd162:  cdf_v = cdf[162];
        8'd163:  cdf_v = cdf[163];
        8'd164:  cdf_v = cdf[164];
        8'd165:  cdf_v = cdf[165];
        8'd166:  cdf_v = cdf[166];
        8'd167:  cdf_v = cdf[167];
        8'd168:  cdf_v = cdf[168];
        8'd169:  cdf_v = cdf[169];
        8'd170:  cdf_v = cdf[170];
        8'd171:  cdf_v = cdf[171];
        8'd172:  cdf_v = cdf[172];
        8'd173:  cdf_v = cdf[173];
        8'd174:  cdf_v = cdf[174];
        8'd175:  cdf_v = cdf[175];
        8'd176:  cdf_v = cdf[176];
        8'd177:  cdf_v = cdf[177];
        8'd178:  cdf_v = cdf[178];
        8'd179:  cdf_v = cdf[179];
        8'd180:  cdf_v = cdf[180];
        8'd181:  cdf_v = cdf[181];
        8'd182:  cdf_v = cdf[182];
        8'd183:  cdf_v = cdf[183];
        8'd184:  cdf_v = cdf[184];
        8'd185:  cdf_v = cdf[185];
        8'd186:  cdf_v = cdf[186];
        8'd187:  cdf_v = cdf[187];
        8'd188:  cdf_v = cdf[188];
        8'd189:  cdf_v = cdf[189];
        8'd190:  cdf_v = cdf[190];
        8'd191:  cdf_v = cdf[191];
        8'd192:  cdf_v = cdf[192];
        8'd193:  cdf_v = cdf[193];
        8'd194:  cdf_v = cdf[194];
        8'd195:  cdf_v = cdf[195];
        8'd196:  cdf_v = cdf[196];
        8'd197:  cdf_v = cdf[197];
        8'd198:  cdf_v = cdf[198];
        8'd199:  cdf_v = cdf[199];
        8'd200:  cdf_v = cdf[200];
        8'd201:  cdf_v = cdf[201];
        8'd202:  cdf_v = cdf[202];
        8'd203:  cdf_v = cdf[203];
        8'd204:  cdf_v = cdf[204];
        8'd205:  cdf_v = cdf[205];
        8'd206:  cdf_v = cdf[206];
        8'd207:  cdf_v = cdf[207];
        8'd208:  cdf_v = cdf[208];
        8'd209:  cdf_v = cdf[209];
        8'd210:  cdf_v = cdf[210];
        8'd211:  cdf_v = cdf[211];
        8'd212:  cdf_v = cdf[212];
        8'd213:  cdf_v = cdf[213];
        8'd214:  cdf_v = cdf[214];
        8'd215:  cdf_v = cdf[215];
        8'd216:  cdf_v = cdf[216];
        8'd217:  cdf_v = cdf[217];
        8'd218:  cdf_v = cdf[218];
        8'd219:  cdf_v = cdf[219];
        8'd220:  cdf_v = cdf[220];
        8'd221:  cdf_v = cdf[221];
        8'd222:  cdf_v = cdf[222];
        8'd223:  cdf_v = cdf[223];
        8'd224:  cdf_v = cdf[224];
        8'd225:  cdf_v = cdf[225];
        8'd226:  cdf_v = cdf[226];
        8'd227:  cdf_v = cdf[227];
        8'd228:  cdf_v = cdf[228];
        8'd229:  cdf_v = cdf[229];
        8'd230:  cdf_v = cdf[230];
        8'd231:  cdf_v = cdf[231];
        8'd232:  cdf_v = cdf[232];
        8'd233:  cdf_v = cdf[233];
        8'd234:  cdf_v = cdf[234];
        8'd235:  cdf_v = cdf[235];
        8'd236:  cdf_v = cdf[236];
        8'd237:  cdf_v = cdf[237];
        8'd238:  cdf_v = cdf[238];
        8'd239:  cdf_v = cdf[239];
        8'd240:  cdf_v = cdf[240];
        8'd241:  cdf_v = cdf[241];
        8'd242:  cdf_v = cdf[242];
        8'd243:  cdf_v = cdf[243];
        8'd244:  cdf_v = cdf[244];
        8'd245:  cdf_v = cdf[245];
        8'd246:  cdf_v = cdf[246];
        8'd247:  cdf_v = cdf[247];
        8'd248:  cdf_v = cdf[248];
        8'd249:  cdf_v = cdf[249];
        8'd250:  cdf_v = cdf[250];
        8'd251:  cdf_v = cdf[251];
        8'd252:  cdf_v = cdf[252];
        8'd253:  cdf_v = cdf[253];
        8'd254:  cdf_v = cdf[254];
        8'd255:  cdf_v = 1024;
        default: cdf_v = 0;
    endcase    
end

//---------------------------------------------------------------------
//   SRAM connection             
//---------------------------------------------------------------------

assign CEN = 0;
assign OEN = 0;

SRAM_128 sram128_1(.Q(sram_out), .CLK(clk), .CEN(CEN), .WEN(WEN), .A(sram_address), .D(sram_in), .OEN(OEN));

always @(*) 
begin
    if(c_state == READ_PATTERN)
        WEN = 0;
    else if(c_state == EROSION || c_state == DILATION || (c_state == HISTOGRAM && histogram_flag))
    begin
        if((image_cnt[3:0] == 0 && image_cnt != 0) || image_cnt == 1023)
            WEN = 0;
        else
            WEN = 1;
    end
    else
        WEN = 1;    
end

always @(*)
begin
    if(c_state == READ_PATTERN)
        sram_address = sram_address_cnt;
    else if(c_state == EROSION || c_state == DILATION || (c_state == HISTOGRAM && histogram_flag))
    begin
        if(image_cnt[3:0] == 0 || image_cnt == 1023)
            sram_address = sram_ans_cnt;
        else
            sram_address = sram_address_cnt;
    end
    else if(c_state == HISTOGRAM && !histogram_flag)
        sram_address = histogram_address;
    else if(c_state == ANS_OUT || c_state == SETTING)
        sram_address = sram_address_cnt;
    else
        sram_address = 0;
end

always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        sram_address_cnt <= 0;
    else if(counter == 255 && c_state == READ_PATTERN)
        sram_address_cnt <= 8;
    else if((in_valid || c_state == ANS_OUT) && counter[1:0] == 2'b11)
        sram_address_cnt <= sram_address_cnt + 1'b1;
    else if(c_state == SETTING)
    begin
        if(sram_address_cnt == 8)
            sram_address_cnt <= sram_address_cnt;
        else
            sram_address_cnt <= sram_address_cnt + 1'b1;
    end
    else if((c_state == EROSION || c_state == DILATION || c_state == HISTOGRAM) && image_cnt[3:0] == 15)
    begin
        if(sram_address_cnt == 63)
        begin
            if(image_cnt == 1023)
                sram_address_cnt <= 0;
            else
                sram_address_cnt <= sram_address_cnt;
        end
        else
            sram_address_cnt <= sram_address_cnt + 1'b1;
    end
    else if(c_state == STANDBY || (sram_address_cnt == 63 && counter == 255))
        sram_address_cnt <= 0;
    else
        sram_address_cnt <= sram_address_cnt;
end

always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        sram_ans_cnt <= 63;
    else if(c_state == EROSION || c_state == DILATION || (c_state == HISTOGRAM && histogram_flag))
    begin
        if(image_cnt[3:0] == 0)
            sram_ans_cnt <= sram_ans_cnt + 1;
        else
            sram_ans_cnt <= sram_ans_cnt;
    end
    else if(c_state == STANDBY)
        sram_ans_cnt <= 63;
    else
        sram_ans_cnt <= sram_ans_cnt;
end

always @(*)
begin
    if(c_state == EROSION || c_state == DILATION || c_state == HISTOGRAM)
    begin
        if(image_cnt == 1023)
            sram_in = {sram_in_final, calculation_ans[14], calculation_ans[13], calculation_ans[12], 
                        calculation_ans[11], calculation_ans[10], calculation_ans[9], calculation_ans[8], 
                        calculation_ans[7], calculation_ans[6], calculation_ans[5], calculation_ans[4], 
                        calculation_ans[3], calculation_ans[2], calculation_ans[1], calculation_ans[0]};
        else
            sram_in = {calculation_ans[15], calculation_ans[14], calculation_ans[13], calculation_ans[12], 
                        calculation_ans[11], calculation_ans[10], calculation_ans[9], calculation_ans[8], 
                        calculation_ans[7], calculation_ans[6], calculation_ans[5], calculation_ans[4], 
                        calculation_ans[3], calculation_ans[2], calculation_ans[1], calculation_ans[0]};
    end
    else
        sram_in = pic_tmp;
end

always @(*) 
begin
    if(c_state == EROSION)
        sram_in_final = erosion_ans;
    else if(c_state == DILATION)
        sram_in_final = dilation_ans;
    else
        sram_in_final = histogram_ans;    
end

assign pic_tmp = {pic_data, pic_in[127:32]};
//---------------------------------------------------------------------
//   SE get             
//---------------------------------------------------------------------

genvar i_se;
generate
    for(i_se=0; i_se<16; i_se=i_se+1)
    begin
        always @(posedge clk or negedge rst_n) 
        begin
            if(!rst_n)
                se_reg[i_se] <= 0;
            else if(in_valid && counter < 16)
            begin
                if(i_se == 15)
                    se_reg[i_se] <= se_data;
                else
                    se_reg[i_se] <= se_reg[i_se+1];
            end
            else if(((mode == 3'b011 || mode == 3'b111) && counter == 16) || (c_state == SETTING && sram_address_cnt == 0))
                se_reg[i_se] <= se_reg[15-i_se];
            else if(c_state == STANDBY)
                se_reg[i_se] <= 0;
            else
                se_reg[i_se] <= se_reg[i_se];
        end
    end
endgenerate

//---------------------------------------------------------------------
//   IMAGE get             
//---------------------------------------------------------------------

assign image_cnt2 = image_cnt + 1'b1;

genvar i_im1;
generate
    for(i_im1=0; i_im1<32; i_im1=i_im1+1)
    begin
        always @(posedge clk or negedge rst_n) 
        begin
            if(!rst_n)
                image_reg1[i_im1] <= 0;
            else if(c_state == SETTING && sram_address_cnt <= 2)
            begin
                if(i_im1 < 16)
                begin
                    if(sram_address_cnt == 1)
                        image_reg1[i_im1] <= sram_out[8*i_im1+7 : 8*i_im1];
                    else
                        image_reg1[i_im1] <= image_reg1[i_im1];
                end
                else
                begin
                    if(sram_address_cnt == 2)
                        image_reg1[i_im1] <= sram_out[8*(i_im1-16)+7 : 8*(i_im1-16)];
                    else
                        image_reg1[i_im1] <= image_reg1[i_im1];
                end
            end
            else if(c_state == READ_PATTERN && sram_address_cnt <= 1)
            begin
                if(i_im1 < 16)
                begin
                    if(sram_address_cnt == 0 && in_valid)
                        image_reg1[i_im1] <= pic_tmp[8*i_im1+7 : 8*i_im1];//rdata_m_inf[8*(15-i_im1)+7 : 8*(15-i_im1)];
                    else
                        image_reg1[i_im1] <= image_reg1[i_im1];
                end
                else
                begin
                    if(sram_address_cnt == 1 && in_valid)
                        image_reg1[i_im1] <= pic_tmp[8*(i_im1-16)+7 : 8*(i_im1-16)];
                    else
                        image_reg1[i_im1] <= image_reg1[i_im1];
                end
            end
            else if((c_state == EROSION || c_state == DILATION || c_state == HISTOGRAM) && sram_address_cnt > 7)
            begin
                if(i_im1 < 16)
                begin
                    if(image_cnt2[4] == 1 && image_cnt[3:0] == 15)
                        image_reg1[i_im1] <= image_reg2[i_im1];
                    else
                        image_reg1[i_im1] <= image_reg1[i_im1];
                end
                else
                begin
                    if(image_cnt2[4] == 0 && image_cnt[3:0] == 15)
                        image_reg1[i_im1] <= image_reg2[i_im1];
                    else
                        image_reg1[i_im1] <= image_reg1[i_im1];
                end
            end
            else if(c_state == STANDBY)
                image_reg1[i_im1] <= 0;
            else
                image_reg1[i_im1] <= image_reg1[i_im1];
        end
    end
endgenerate

genvar i_im2;
generate
    for(i_im2=0; i_im2<32; i_im2=i_im2+1)
    begin
        always @(posedge clk or negedge rst_n) 
        begin
            if(!rst_n)
                image_reg2[i_im2] <= 0;
            else if(c_state == SETTING && sram_address_cnt > 2 && sram_address_cnt <= 4)
            begin
                if(i_im2 < 16)
                begin
                    if(sram_address_cnt == 3)
                        image_reg2[i_im2] <= sram_out[8*i_im2+7 : 8*i_im2];
                    else
                        image_reg2[i_im2] <= image_reg2[i_im2];
                end
                else
                begin
                    if(sram_address_cnt == 4)
                        image_reg2[i_im2] <= sram_out[8*(i_im2-16)+7 : 8*(i_im2-16)];
                    else
                        image_reg2[i_im2] <= image_reg2[i_im2];
                end
            end
            else if(c_state == READ_PATTERN && sram_address_cnt > 1 && sram_address_cnt <= 3)
            begin
                if(i_im2 < 16)
                begin
                    if(sram_address_cnt == 2 && in_valid)
                        image_reg2[i_im2] <= pic_tmp[8*i_im2+7 : 8*i_im2];//rdata_m_inf[8*(15-i_im2)+7 : 8*(15-i_im2)];
                    else
                        image_reg2[i_im2] <= image_reg2[i_im2];
                end
                else
                begin
                    if(sram_address_cnt == 3 && in_valid)
                        image_reg2[i_im2] <= pic_tmp[8*(i_im2-16)+7 : 8*(i_im2-16)];
                    else
                        image_reg2[i_im2] <= image_reg2[i_im2];
                end
            end
            else if((c_state == EROSION || c_state == DILATION || c_state == HISTOGRAM) && sram_address_cnt > 7)
            begin
                if(i_im2 < 16)
                begin
                    if(image_cnt2[4] == 1 && image_cnt[3:0] == 15)
                        image_reg2[i_im2] <= image_reg3[i_im2];
                    else
                        image_reg2[i_im2] <= image_reg2[i_im2];
                end
                else if(i_im2 >= 16 && i_im2 < 32)
                begin
                    if(image_cnt2[4] == 0 && image_cnt[3:0] == 15)
                        image_reg2[i_im2] <= image_reg3[i_im2];
                    else
                        image_reg2[i_im2] <= image_reg2[i_im2];
                end
            end
            else if(c_state == STANDBY)
                image_reg2[i_im2] <= 0;
            else
                image_reg2[i_im2] <= image_reg2[i_im2];
        end
    end
endgenerate

genvar i_im3;
generate
    for(i_im3=0; i_im3<32; i_im3=i_im3+1)
    begin
        always @(posedge clk or negedge rst_n) 
        begin
            if(!rst_n)
                image_reg3[i_im3] <= 0;
            else if(c_state == SETTING && sram_address_cnt > 4 && sram_address_cnt <= 6)
            begin
                if(i_im3 < 16)
                begin
                    if(sram_address_cnt == 5)
                        image_reg3[i_im3] <= sram_out[8*i_im3+7 : 8*i_im3];
                    else
                        image_reg3[i_im3] <= image_reg3[i_im3];
                end
                else
                begin
                    if(sram_address_cnt == 6)
                        image_reg3[i_im3] <= sram_out[8*(i_im3-16)+7 : 8*(i_im3-16)];
                    else
                        image_reg3[i_im3] <= image_reg3[i_im3];
                end
            end
            else if(c_state == READ_PATTERN && sram_address_cnt > 3 && sram_address_cnt <= 5)
            begin
                if(i_im3 < 16)
                begin
                    if(sram_address_cnt == 4 && in_valid)
                        image_reg3[i_im3] <= pic_tmp[8*i_im3+7 : 8*i_im3];//rdata_m_inf[8*(15-i_im3)+7 : 8*(15-i_im3)];
                    else
                        image_reg3[i_im3] <= image_reg3[i_im3];
                end
                else
                begin
                    if(sram_address_cnt == 5 && in_valid)
                        image_reg3[i_im3] <= pic_tmp[8*(i_im3-16)+7 : 8*(i_im3-16)];
                    else
                        image_reg3[i_im3] <= image_reg3[i_im3];
                end
            end
            else if((c_state == EROSION || c_state == DILATION || c_state == HISTOGRAM) && sram_address_cnt > 7)
            begin
                if(i_im3 < 16)
                begin
                    if(image_cnt2[4] == 1 && image_cnt[3:0] == 15)
                        image_reg3[i_im3] <= image_reg4[i_im3];
                    else
                        image_reg3[i_im3] <= image_reg3[i_im3];
                end
                else
                begin
                    if(image_cnt2[4] == 0 && image_cnt[3:0] == 15)
                        image_reg3[i_im3] <= image_reg4[i_im3];
                    else
                        image_reg3[i_im3] <= image_reg3[i_im3];
                end
            end
            else if(c_state == STANDBY)
                image_reg3[i_im3] <= 0;
            else
                image_reg3[i_im3] <= image_reg3[i_im3];
        end
    end
endgenerate

genvar i_im4;
generate
    for(i_im4=0; i_im4<32; i_im4=i_im4+1)
    begin
        always @(posedge clk or negedge rst_n) 
        begin
            if(!rst_n)
                image_reg4[i_im4] <= 0;
            else if(c_state == SETTING && sram_address_cnt > 6 && sram_address_cnt <= 8)
            begin
                if(i_im4 < 16)
                begin
                    if(sram_address_cnt == 7)
                        image_reg4[i_im4] <= sram_out[8*i_im4+7 : 8*i_im4];
                    else
                        image_reg4[i_im4] <= image_reg4[i_im4];
                end
                else
                begin
                    if(sram_address_cnt == 8)
                        image_reg4[i_im4] <= sram_out[8*(i_im4-16)+7 : 8*(i_im4-16)];
                    else
                        image_reg4[i_im4] <= image_reg4[i_im4];
                end
            end
            else if(c_state == READ_PATTERN && sram_address_cnt > 5 && sram_address_cnt <= 7)
            begin
                if(i_im4 < 16)
                begin
                    if(sram_address_cnt == 6 && in_valid)
                        image_reg4[i_im4] <= pic_tmp[8*i_im4+7 : 8*i_im4];//rdata_m_inf[8*(15-i_im4)+7 : 8*(15-i_im4)];
                    else
                        image_reg4[i_im4] <= image_reg4[i_im4];
                end
                else
                begin
                    if(sram_address_cnt == 7 && in_valid)
                        image_reg4[i_im4] <= pic_tmp[8*(i_im4-16)+7 : 8*(i_im4-16)];
                    else
                        image_reg4[i_im4] <= image_reg4[i_im4];
                end
            end
            else if((c_state == EROSION || c_state == DILATION || c_state == HISTOGRAM) && sram_address_cnt > 7)
            begin
                if(i_im4 < 16)
                begin
                    if(image_cnt2[4] == 1 && image_cnt[3:0] == 15)
                    begin
                        if(image_cnt2 >= 912)
                            image_reg4[i_im4] <= 0;
                        else
                            image_reg4[i_im4] <= sram_out[8*i_im4+7 : 8*i_im4];
                    end
                    else
                        image_reg4[i_im4] <= image_reg4[i_im4];
                end
                else
                begin
                    if(image_cnt2[4] == 0 && image_cnt[3:0] == 15)
                    begin
                        if(image_cnt2 >= 912)
                            image_reg4[i_im4] <= 0;
                        else
                            image_reg4[i_im4] <= sram_out[8*(i_im4-16)+7 : 8*(i_im4-16)];
                    end
                    else
                        image_reg4[i_im4] <= image_reg4[i_im4];
                end
            end
            else if(c_state == STANDBY)
                image_reg4[i_im4] <= 0;
            else
                image_reg4[i_im4] <= image_reg4[i_im4];
        end
    end
endgenerate

always @(posedge clk)
begin
    image_reg1[32] <= 0;
    image_reg1[33] <= 0;
    image_reg1[34] <= 0;
    image_reg2[32] <= 0;
    image_reg2[33] <= 0;
    image_reg2[34] <= 0;
    image_reg3[32] <= 0;
    image_reg3[33] <= 0;
    image_reg3[34] <= 0;
    image_reg4[32] <= 0;
    image_reg4[33] <= 0;
    image_reg4[34] <= 0;
end

//---------------------------------------------------------------------
//   TARGET IMAGE
//---------------------------------------------------------------------

genvar i_tar;
generate
    for(i_tar=0; i_tar<16; i_tar=i_tar+1)
    begin
        always @(posedge clk) 
        begin
            if(i_tar<4)
                target_image[i_tar] <= image_reg1[target_cnt+i_tar];
            else if(i_tar>=4 && i_tar<8)
                target_image[i_tar] <= image_reg2[target_cnt+i_tar-4];
            else if(i_tar>=8 && i_tar<12)
                target_image[i_tar] <= image_reg3[target_cnt+i_tar-8];
            else
                target_image[i_tar] <= image_reg4[target_cnt+i_tar-12];
        end
    end
endgenerate

always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        target_cnt <= 0;
    else if(c_state == STANDBY)
        target_cnt <= 0;
    else if(n_state == EROSION || n_state == DILATION || (n_state == HISTOGRAM && (histogram_flag || histogram_cnt == 1023)))
        target_cnt <= target_cnt + 1'b1;
    else
        target_cnt <= target_cnt;
end

//---------------------------------------------------------------------
//   EROSION calculation
//---------------------------------------------------------------------

genvar i_ero;
generate
    for (i_ero=0; i_ero<16; i_ero=i_ero+1) 
    begin
        always @(*)
        begin
            if(target_image[i_ero] < se_reg[i_ero])
                erosion_cal_tmp[i_ero] = 0;
            else
                erosion_cal_tmp[i_ero] = target_image[i_ero] - se_reg[i_ero];
        end    
    end
endgenerate

select_min min1(.in1(erosion_cal_tmp[0]), .in2(erosion_cal_tmp[1]), .in3(erosion_cal_tmp[2]), .in4(erosion_cal_tmp[3]),
                .in5(erosion_cal_tmp[4]), .in6(erosion_cal_tmp[5]), .in7(erosion_cal_tmp[6]), .in8(erosion_cal_tmp[7]),
                .in9(erosion_cal_tmp[8]), .in10(erosion_cal_tmp[9]), .in11(erosion_cal_tmp[10]), .in12(erosion_cal_tmp[11]),
                .in13(erosion_cal_tmp[12]), .in14(erosion_cal_tmp[13]), .in15(erosion_cal_tmp[14]), .in16(erosion_cal_tmp[15]),
                .out(erosion_ans));

//---------------------------------------------------------------------
//   DILATION calculation
//---------------------------------------------------------------------

genvar i_dil;
generate
    for (i_dil=0 ; i_dil<16; i_dil=i_dil+1) 
    begin
        always @(*)
        begin
            if(target_image[i_dil] + se_reg[i_dil] > 255)
                dilation_cal_tmp[i_dil] = 255;
            else
                dilation_cal_tmp[i_dil] = target_image[i_dil] + se_reg[i_dil];
        end
    end
endgenerate

select_max max1(.in1(dilation_cal_tmp[0]), .in2(dilation_cal_tmp[1]), .in3(dilation_cal_tmp[2]), .in4(dilation_cal_tmp[3]),
                .in5(dilation_cal_tmp[4]), .in6(dilation_cal_tmp[5]), .in7(dilation_cal_tmp[6]), .in8(dilation_cal_tmp[7]),
                .in9(dilation_cal_tmp[8]), .in10(dilation_cal_tmp[9]), .in11(dilation_cal_tmp[10]), .in12(dilation_cal_tmp[11]),
                .in13(dilation_cal_tmp[12]), .in14(dilation_cal_tmp[13]), .in15(dilation_cal_tmp[14]), .in16(dilation_cal_tmp[15]),
                .out(dilation_ans));

//---------------------------------------------------------------------
//   calculation end
//---------------------------------------------------------------------
assign his_denomirator = 1024 - cdf_min;
assign his_numerator = cdf_v - cdf_min;
assign his_shift = {his_numerator, 8'd0} - his_numerator;
assign histogram_ans =  his_shift / his_denomirator;

genvar i_cal;
generate
    for (i_cal=0; i_cal<16; i_cal=i_cal+1) 
    begin
        always @(posedge clk or negedge rst_n)
        begin
            if(!rst_n)
                calculation_ans[i_cal] <= 0;
            else if(c_state == STANDBY)
                calculation_ans[i_cal] <= 0;
            else if(c_state == EROSION)
            begin
                if(i_cal == cal_cnt)
                    calculation_ans[i_cal] <= erosion_ans;
                else
                    calculation_ans[i_cal] <= calculation_ans[i_cal];
            end
            else if(c_state == DILATION)
            begin
                if(i_cal == cal_cnt)
                    calculation_ans[i_cal] <= dilation_ans;
                else
                    calculation_ans[i_cal] <= calculation_ans[i_cal];
            end
            else if(c_state == HISTOGRAM)
            begin
                if(i_cal == cal_cnt)
                    calculation_ans[i_cal] <= histogram_ans;
                else
                    calculation_ans[i_cal] <= calculation_ans[i_cal];
            end
        end    
    end
endgenerate

always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        cal_cnt <= 0;
    else if(c_state == STANDBY)
        cal_cnt <= 0;
    else if(c_state == EROSION || c_state == DILATION || (c_state == HISTOGRAM && histogram_flag))
        cal_cnt <= cal_cnt + 1'b1;
    else
        cal_cnt <= cal_cnt;
end

//---------------------------------------------------------------------
//   INPUT circuit
//---------------------------------------------------------------------

always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        mode <= 0;
    else if(op_valid)
        mode <= op;
    else if(c_state == STANDBY)
        mode <= 0;
    else
        mode <= mode;
end

genvar i_pic;
generate
    for(i_pic=0; i_pic<96; i_pic=i_pic+1)
    begin
        always @(posedge clk or negedge rst_n)
        begin
            if(!rst_n)
                pic_in[i_pic] <= 0;
            else
                pic_in[i_pic] <= pic_in[i_pic + 32];
        end
    end
endgenerate

always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        pic_in[127:96] <= 0;
    else
        pic_in[127:96] <= pic_data;
end
//---------------------------------------------------------------------
//   OUTPUT circuit
//---------------------------------------------------------------------

always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        out_valid <= 0;
    else if(c_state == ANS_OUT)
        out_valid <= 1;
    else
        out_valid <= 0;
end

always @(*)
begin
    if(out_valid)
    begin
        if(counter[1:0] == 1)
            out_data = sram_out[31:0];
        else if(counter[1:0] == 2)
            out_data = sram_out[63:32];
        else if(counter[1:0] == 3)
            out_data = sram_out[95:64];
        else
            out_data = sram_out[127:96];
    end
    else
        out_data = 0;
end

endmodule

module select_min (
    in1,
    in2,
    in3,
    in4,
    in5,
    in6,
    in7,
    in8,
    in9,
    in10,
    in11,
    in12,
    in13,
    in14,
    in15,
    in16,
    out
);
    
input [7:0] in1, in2, in3, in4, in5, in6, in7, in8, in9, in10, in11, in12, in13, in14, in15, in16;
output reg [7:0] out;

reg [7:0] tmp1, tmp2, tmp3, tmp4, tmp5, tmp6, tmp7, tmp8, tmp9, tmp10, tmp11, tmp12, tmp13, tmp14;

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
    if(in9 > in10)
        tmp5 = in10;
    else
        tmp5 = in9;    
end

always @(*) 
begin
    if(in11 > in12)
        tmp6 = in12;
    else
        tmp6 = in11;    
end

always @(*) 
begin
    if(in13 > in14)
        tmp7 = in14;
    else
        tmp7 = in13;    
end

always @(*) 
begin
    if(in15 > in16)
        tmp8 = in16;
    else
        tmp8 = in15;
end

always @(*) 
begin
    if(tmp1 > tmp2)
        tmp9 = tmp2;
    else
        tmp9 = tmp1;    
end

always @(*) 
begin
    if(tmp3 > tmp4)
        tmp10 = tmp4;
    else
        tmp10 = tmp3;    
end

always @(*) 
begin
    if(tmp5 > tmp6)
        tmp11 = tmp6;
    else
        tmp11 = tmp5;    
end

always @(*) 
begin
    if(tmp7 > tmp8)
        tmp12 = tmp8;
    else
        tmp12 = tmp7;    
end

always @(*) 
begin
    if(tmp9 > tmp10)
        tmp13 = tmp10;
    else
        tmp13 = tmp9;    
end

always @(*) 
begin
    if(tmp11 > tmp12)
        tmp14 = tmp12;
    else
        tmp14 = tmp11;    
end

always @(*) 
begin
    if(tmp13 > tmp14)
        out = tmp14;
    else
        out = tmp13;    
end

endmodule

module select_max (
    in1,
    in2,
    in3,
    in4,
    in5,
    in6,
    in7,
    in8,
    in9,
    in10,
    in11,
    in12,
    in13,
    in14,
    in15,
    in16,
    out
);
    
input [7:0] in1, in2, in3, in4, in5, in6, in7, in8, in9, in10, in11, in12, in13, in14, in15, in16;
output reg [7:0] out;

reg [7:0] tmp1, tmp2, tmp3, tmp4, tmp5, tmp6, tmp7, tmp8, tmp9, tmp10, tmp11, tmp12, tmp13, tmp14;

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
    if(in9 < in10)
        tmp5 = in10;
    else
        tmp5 = in9;    
end

always @(*) 
begin
    if(in11 < in12)
        tmp6 = in12;
    else
        tmp6 = in11;    
end

always @(*) 
begin
    if(in13 < in14)
        tmp7 = in14;
    else
        tmp7 = in13;    
end

always @(*) 
begin
    if(in15 < in16)
        tmp8 = in16;
    else
        tmp8 = in15;
end

always @(*) 
begin
    if(tmp1 < tmp2)
        tmp9 = tmp2;
    else
        tmp9 = tmp1;    
end

always @(*) 
begin
    if(tmp3 < tmp4)
        tmp10 = tmp4;
    else
        tmp10 = tmp3;    
end

always @(*) 
begin
    if(tmp5 < tmp6)
        tmp11 = tmp6;
    else
        tmp11 = tmp5;    
end

always @(*) 
begin
    if(tmp7 < tmp8)
        tmp12 = tmp8;
    else
        tmp12 = tmp7;    
end

always @(*) 
begin
    if(tmp9 < tmp10)
        tmp13 = tmp10;
    else
        tmp13 = tmp9;    
end

always @(*) 
begin
    if(tmp11 < tmp12)
        tmp14 = tmp12;
    else
        tmp14 = tmp11;    
end

always @(*) 
begin
    if(tmp13 < tmp14)
        out = tmp14;
    else
        out = tmp13;    
end

endmodule