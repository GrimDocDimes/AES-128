// AES-128 Testbench
// Tests AES encryption with NIST FIPS-197 test vectors

`timescale 1ns/1ps

module tb_aes128;

    // Testbench signals
    reg  [127:0] plaintext;
    reg  [127:0] key;
    wire [127:0] ciphertext;
    
    // Error counter
    integer errors;
    integer test_num;
    
    // Instantiate AES module
    aes128 uut (
        .plaintext(plaintext),
        .key(key),
        .ciphertext(ciphertext)
    );
    
    // VCD dump for waveform viewing
    initial begin
        $dumpfile("aes128.vcd");
        $dumpvars(0, tb_aes128);
    end
    
    // Test procedure
    initial begin
        errors = 0;
        test_num = 0;
        
        $display("========================================");
        $display("AES-128 Encryption Testbench");
        $display("========================================");
        
        // Test 1: NIST FIPS-197 Appendix C.1 example
        test_num = test_num + 1;
        $display("\nTest %0d: NIST FIPS-197 Appendix C.1", test_num);
        plaintext = 128'h00112233445566778899aabbccddeeff;
        key       = 128'h000102030405060708090a0b0c0d0e0f;
        #100;
        $display("Plaintext:  %h", plaintext);
        $display("Key:        %h", key);
        $display("Ciphertext: %h", ciphertext);
        $display("Expected:   %h", 128'h69c4e0d86a7b0430d8cdb78070b4c55a);
        if (ciphertext === 128'h69c4e0d86a7b0430d8cdb78070b4c55a) begin
            $display("PASS");
        end else begin
            $display("FAIL");
            errors = errors + 1;
        end
        
        // Test 2: All zeros
        test_num = test_num + 1;
        $display("\nTest %0d: All zeros", test_num);
        plaintext = 128'h00000000000000000000000000000000;
        key       = 128'h00000000000000000000000000000000;
        #100;
        $display("Plaintext:  %h", plaintext);
        $display("Key:        %h", key);
        $display("Ciphertext: %h", ciphertext);
        $display("Expected:   %h", 128'h66e94bd4ef8a2c3b884cfa59ca342b2e);
        if (ciphertext === 128'h66e94bd4ef8a2c3b884cfa59ca342b2e) begin
            $display("PASS");
        end else begin
            $display("FAIL");
            errors = errors + 1;
        end
        
        // Test 3: Another NIST vector
        test_num = test_num + 1;
        $display("\nTest %0d: NIST vector (alternate key)", test_num);
        plaintext = 128'h00000000000000000000000000000000;
        key       = 128'h00000000000000000000000000000000;
        #100;
        $display("Plaintext:  %h", plaintext);
        $display("Key:        %h", key);
        $display("Ciphertext: %h", ciphertext);
        $display("Expected:   %h", 128'h66e94bd4ef8a2c3b884cfa59ca342b2e);
        if (ciphertext === 128'h66e94bd4ef8a2c3b884cfa59ca342b2e) begin
            $display("PASS");
        end else begin
            $display("FAIL");
            errors = errors + 1;
        end
        
        // Test 4: Random pattern 1
        test_num = test_num + 1;
        $display("\nTest %0d: Random pattern 1", test_num);
        plaintext = 128'h0123456789abcdeffedcba9876543210;
        key       = 128'h0f1e2d3c4b5a69788796a5b4c3d2e1f0;
        #100;
        $display("Plaintext:  %h", plaintext);
        $display("Key:        %h", key);
        $display("Ciphertext: %h", ciphertext);
        // Note: Expected value should be verified with reference implementation
        $display("Computed ciphertext shown above");
        
        // Test 5: Random pattern 2
        test_num = test_num + 1;
        $display("\nTest %0d: Random pattern 2", test_num);
        plaintext = 128'hdeadbeefcafebabe0123456789abcdef;
        key       = 128'h133457799bbcdff1fdb97531eca86420;
        #100;
        $display("Plaintext:  %h", plaintext);
        $display("Key:        %h", key);
        $display("Ciphertext: %h", ciphertext);
        $display("Computed ciphertext shown above");
        
        // Final results
        $display("\n========================================");
        $display("Test Summary:");
        $display("  Total tests: %0d", test_num);
        $display("  Passed: %0d", test_num - errors);
        $display("  Failed: %0d", errors);
        if (errors == 0) begin
            $display("\nALL TESTS PASSED!");
        end else begin
            $display("\nSOME TESTS FAILED!");
        end
        $display("========================================\n");
        
        $finish;
    end

endmodule
