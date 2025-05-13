module HD (code_word1, code_word2, out_n);
    output reg signed [5:0] out_n;
    input [6:0] code_word1, code_word2;
    wire signed [3:0] c1, c2;
    wire [1:0] opt;
    
    Correct_Wrong CE1(.code_word(code_word1), .correct_info(c1), .wrong_bit(opt[1]));
    Correct_Wrong CE2(.code_word(code_word2), .correct_info(c2), .wrong_bit(opt[0]));

    always @(*) 
    begin
        case (opt)
            2'b00: out_n = 2*c1 + c2;
            2'b01: out_n = 2*c1 - c2;
            2'b10: out_n = c1 - 2*c2;
            default: out_n = c1 + 2*c2;
        endcase
    end

endmodule

module Correct_Wrong (code_word, correct_info, wrong_bit);
    output reg [3:0] correct_info;
    output reg wrong_bit;
    input [6:0] code_word;
    wire Circle1, Circle2, Circle3;
    
    assign Circle1 = code_word[6] ^ code_word[3] ^ code_word[2] ^ code_word[1];
    assign Circle2 = code_word[5] ^ code_word[3] ^ code_word[2] ^ code_word[0];
    assign Circle3 = code_word[4] ^ code_word[3] ^ code_word[1] ^ code_word[0];

    always @(*) 
    begin
        case ({Circle1, Circle2, Circle3})
            3'b001: begin wrong_bit = code_word[4]; correct_info = {code_word[3], code_word[2], code_word[1], code_word[0]}; end 
            3'b010: begin wrong_bit = code_word[5]; correct_info = {code_word[3], code_word[2], code_word[1], code_word[0]}; end
            3'b011: begin wrong_bit = code_word[0]; correct_info = {code_word[3], code_word[2], code_word[1], ~code_word[0]}; end
            3'b100: begin wrong_bit = code_word[6]; correct_info = {code_word[3], code_word[2], code_word[1], code_word[0]}; end
            3'b101: begin wrong_bit = code_word[1]; correct_info = {code_word[3], code_word[2], ~code_word[1], code_word[0]}; end
            3'b110: begin wrong_bit = code_word[2]; correct_info = {code_word[3], ~code_word[2], code_word[1], code_word[0]}; end
            3'b111: begin wrong_bit = code_word[3]; correct_info = {~code_word[3], code_word[2], code_word[1], code_word[0]}; end
            default: begin wrong_bit = 0; correct_info = {code_word[3], code_word[2], code_word[1], code_word[0]}; end
        endcase    
    end
    
endmodule