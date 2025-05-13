//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   File Name   : B2BCD_IP.v
//   Module Name : B2BCD_IP
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

module B2BCD_IP #(parameter WIDTH = 4, parameter DIGIT = 2) (
    // Input signals
    Binary_code,
    // Output signals
    BCD_code
);

// ===============================================================
// Declaration
// ===============================================================
input  [WIDTH-1:0]   Binary_code;
output [DIGIT*4-1:0] BCD_code;

// ===============================================================
// Soft IP DESIGN
// ===============================================================
reg [DIGIT*4-1:0] BCD_tmp;
reg [WIDTH-1:0] Binary_tmp[DIGIT-1:0];

genvar i;
generate
for(i=0; i<DIGIT; i=i+1) 
begin:BCD
    always @(Binary_code) 
    begin
        Binary_tmp[i] = Binary_code / (10**i);
        BCD_tmp[4*i+3:4*i] = Binary_tmp[i] % 10;
    end
end
endgenerate

assign BCD_code = BCD_tmp;

endmodule

/*module add3(in, out);
input [3:0] in;
output reg [3:0] out;

always @ (in)
begin
    case (in)
        4'b0000: out <= 4'b0000;
        4'b0001: out <= 4'b0001;
        4'b0010: out <= 4'b0010; 
        4'b0011: out <= 4'b0011; 
        4'b0100: out <= 4'b0100; 
        4'b0101: out <= 4'b1000; 
        4'b0110: out <= 4'b1001; 
        4'b0111: out <= 4'b1010; 
        4'b1000: out <= 4'b1011; 
        4'b1001: out <= 4'b1100; 
        default: out <= 4'b0000; 
    endcase 
endmodule*/