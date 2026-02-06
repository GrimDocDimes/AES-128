// AES-128 Encryption Module
// Implements full AES-128 encryption with 10 rounds
// Inputs: 128-bit plaintext, 128-bit key
// Output: 128-bit ciphertext

module aes128 (
    input  [127:0] plaintext,
    input  [127:0] key,
    output [127:0] ciphertext
);

    // Round keys from key expansion
    wire [1407:0] round_keys;
    
    // State array for each round (11 states: initial + 10 rounds)
    wire [127:0] state [0:10];
    
    // Intermediate signals for each round
    wire [127:0] after_subbytes [0:9];
    wire [127:0] after_shiftrows [0:9];
    wire [127:0] after_mixcolumns [0:8];
    
    // Key expansion module
    aes_key_expand key_expand (
        .key(key),
        .round_keys(round_keys)
    );
    
    // Initial round: AddRoundKey
    assign state[0] = plaintext ^ round_keys[127:0];
    
    // Generate 10 rounds
    genvar round;
    generate
        for (round = 0; round < 10; round = round + 1) begin : aes_rounds
            
            // SubBytes transformation
            aes_round_subbytes subbytes (
                .state_in(state[round]),
                .state_out(after_subbytes[round])
            );
            
            // ShiftRows transformation
            aes_round_shiftrows shiftrows (
                .state_in(after_subbytes[round]),
                .state_out(after_shiftrows[round])
            );
            
            // MixColumns (skip in final round)
            if (round < 9) begin
                aes_round_mixcolumns mixcolumns (
                    .state_in(after_shiftrows[round]),
                    .state_out(after_mixcolumns[round])
                );
                
                // AddRoundKey
                assign state[round+1] = after_mixcolumns[round] ^ round_keys[128*(round+1)+127:128*(round+1)];
            end else begin
                // Final round: no MixColumns
                assign state[round+1] = after_shiftrows[round] ^ round_keys[128*(round+1)+127:128*(round+1)];
            end
        end
    endgenerate
    
    // Output ciphertext
    assign ciphertext = state[10];

endmodule


// SubBytes transformation module
module aes_round_subbytes (
    input  [127:0] state_in,
    output [127:0] state_out
);

    genvar i;
    generate
        for (i = 0; i < 16; i = i + 1) begin : sbox_array
            aes_sbox sbox (
                .in(state_in[8*i+7:8*i]),
                .out(state_out[8*i+7:8*i])
            );
        end
    endgenerate

endmodule


// ShiftRows transformation module
module aes_round_shiftrows (
    input  [127:0] state_in,
    output [127:0] state_out
);

    // AES state is organized as 4x4 matrix of bytes
    // state_in[127:120] = s[0,0], state_in[119:112] = s[1,0], etc.
    // Column-major order
    
    // Row 0: no shift
    assign state_out[127:120] = state_in[127:120];  // s[0,0]
    assign state_out[95:88]   = state_in[95:88];    // s[0,1]
    assign state_out[63:56]   = state_in[63:56];    // s[0,2]
    assign state_out[31:24]   = state_in[31:24];    // s[0,3]
    
    // Row 1: left shift by 1
    assign state_out[119:112] = state_in[87:80];    // s[1,0] <- s[1,1]
    assign state_out[87:80]   = state_in[55:48];    // s[1,1] <- s[1,2]
    assign state_out[55:48]   = state_in[23:16];    // s[1,2] <- s[1,3]
    assign state_out[23:16]   = state_in[119:112];  // s[1,3] <- s[1,0]
    
    // Row 2: left shift by 2
    assign state_out[111:104] = state_in[47:40];    // s[2,0] <- s[2,2]
    assign state_out[79:72]   = state_in[15:8];     // s[2,1] <- s[2,3]
    assign state_out[47:40]   = state_in[111:104];  // s[2,2] <- s[2,0]
    assign state_out[15:8]    = state_in[79:72];    // s[2,3] <- s[2,1]
    
    // Row 3: left shift by 3 (or right shift by 1)
    assign state_out[103:96]  = state_in[7:0];      // s[3,0] <- s[3,3]
    assign state_out[71:64]   = state_in[103:96];   // s[3,1] <- s[3,0]
    assign state_out[39:32]   = state_in[71:64];    // s[3,2] <- s[3,1]
    assign state_out[7:0]     = state_in[39:32];    // s[3,3] <- s[3,2]

endmodule


// MixColumns transformation module
module aes_round_mixcolumns (
    input  [127:0] state_in,
    output [127:0] state_out
);

    // Apply MixColumns to each of the 4 columns
    genvar col;
    generate
        for (col = 0; col < 4; col = col + 1) begin : mix_columns
            aes_mixcolumn_single mc (
                .col_in(state_in[32*col+31:32*col]),
                .col_out(state_out[32*col+31:32*col])
            );
        end
    endgenerate

endmodule


// MixColumns for a single column
module aes_mixcolumn_single (
    input  [31:0] col_in,
    output [31:0] col_out
);

    wire [7:0] s0, s1, s2, s3;
    wire [7:0] s0_2x, s1_2x, s2_2x, s3_2x;
    
    // Extract bytes from column
    assign s0 = col_in[31:24];
    assign s1 = col_in[23:16];
    assign s2 = col_in[15:8];
    assign s3 = col_in[7:0];
    
    // Multiply by 2 in GF(2^8) using polynomial 0x11b
    assign s0_2x = {s0[6:0], 1'b0} ^ (s0[7] ? 8'h1b : 8'h00);
    assign s1_2x = {s1[6:0], 1'b0} ^ (s1[7] ? 8'h1b : 8'h00);
    assign s2_2x = {s2[6:0], 1'b0} ^ (s2[7] ? 8'h1b : 8'h00);
    assign s3_2x = {s3[6:0], 1'b0} ^ (s3[7] ? 8'h1b : 8'h00);
    
    // MixColumns transformation
    assign col_out[31:24] = s0_2x ^ s1_2x ^ s1 ^ s2 ^ s3;      // 2*s0 + 3*s1 + s2 + s3
    assign col_out[23:16] = s0 ^ s1_2x ^ s2_2x ^ s2 ^ s3;      // s0 + 2*s1 + 3*s2 + s3
    assign col_out[15:8]  = s0 ^ s1 ^ s2_2x ^ s3_2x ^ s3;      // s0 + s1 + 2*s2 + 3*s3
    assign col_out[7:0]   = s0_2x ^ s0 ^ s1 ^ s2 ^ s3_2x;      // 3*s0 + s1 + s2 + 2*s3

endmodule
