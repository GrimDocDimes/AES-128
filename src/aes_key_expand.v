// AES-128 Key Expansion Module
// Generates 11 round keys (44 words) from the initial 128-bit key

module aes_key_expand (
    input  [127:0] key,
    output [1407:0] round_keys  // 11 keys * 128 bits = 1408 bits
);

    // Round constants for key expansion
    function [7:0] rcon;
        input [3:0] round;
        begin
            case(round)
                4'd0: rcon = 8'h01;
                4'd1: rcon = 8'h02;
                4'd2: rcon = 8'h04;
                4'd3: rcon = 8'h08;
                4'd4: rcon = 8'h10;
                4'd5: rcon = 8'h20;
                4'd6: rcon = 8'h40;
                4'd7: rcon = 8'h80;
                4'd8: rcon = 8'h1B;
                4'd9: rcon = 8'h36;
                default: rcon = 8'h00;
            endcase
        end
    endfunction
    
    // Words for key schedule (44 words total for AES-128)
    wire [31:0] w [0:43];
    
    // Temp wires for SubWord operations
    wire [31:0] temp [0:9];
    wire [31:0] rotword [0:9];
    wire [31:0] subword [0:9];
    
    // First 4 words are the input key (big-endian order)
    assign w[0] = key[127:96];
    assign w[1] = key[95:64];
    assign w[2] = key[63:32];
    assign w[3] = key[31:0];
    
    // Generate remaining words
    genvar i;
    generate
        for (i = 0; i < 10; i = i + 1) begin : key_round
            // RotWord: rotate left by 1 byte
            assign rotword[i] = {w[4*i+3][23:0], w[4*i+3][31:24]};
            
            // SubWord: apply S-box to each byte
            aes_sbox sb0 (.in(rotword[i][31:24]), .out(subword[i][31:24]));
            aes_sbox sb1 (.in(rotword[i][23:16]), .out(subword[i][23:16]));
            aes_sbox sb2 (.in(rotword[i][15:8]),  .out(subword[i][15:8]));
            aes_sbox sb3 (.in(rotword[i][7:0]),   .out(subword[i][7:0]));
            
            // temp = SubWord(RotWord(w[i*4+3])) XOR Rcon
            assign temp[i] = subword[i] ^ {rcon(i), 24'h000000};
            
            // w[i*4+4] = w[i*4] XOR temp
            assign w[4*i+4] = w[4*i] ^ temp[i];
            
            // w[i*4+5] = w[i*4+1] XOR w[i*4+4]
            assign w[4*i+5] = w[4*i+1] ^ w[4*i+4];
            
            // w[i*4+6] = w[i*4+2] XOR w[i*4+5]
            assign w[4*i+6] = w[4*i+2] ^ w[4*i+5];
            
            // w[i*4+7] = w[i*4+3] XOR w[i*4+6]
            assign w[4*i+7] = w[4*i+3] ^ w[4*i+6];
        end
    endgenerate
    
    // Pack round keys into output
    generate
        for (i = 0; i < 11; i = i + 1) begin : pack_keys
            assign round_keys[128*i+127:128*i] = {w[4*i], w[4*i+1], w[4*i+2], w[4*i+3]};
        end
    endgenerate

endmodule
