`timescale 1ns / 1ps
/*
---- ---- ---- ---- ---- ---- ---- ----
            Information
---- ---- ---- ---- ---- ---- ---- ----
Author: Matthias Konrath
Email:  matthias AT inet-sec.at

---- ---- ---- ---- ---- ---- ---- ----
                LICENSE
---- ---- ---- ---- ---- ---- ---- ----
MIT License

Copyright (c) 2021 Matthias Konrath

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/


module rc4_tb;

parameter KEY_SIZE=32;          // 256 Bit Key
parameter PLAINTEXT_SIZE=32;

reg CLK;
reg RESET_N;
reg [7:0] KEY [0:31];
reg [7:0] PLAINTEXT [0:31];
reg [7:0] KNOWN_CIPHERTEXT [0:31];
reg [7:0] CAPTURED_CIPHERTEXT [0:31];
reg [7:0] key_counter;
reg [7:0] plain_counter;
reg [7:0] cipher_counter;

integer x, error;



// ---- ---- ---- ---- ---- ---- ---- ----
//              RC4 INTERFACE
// ---- ---- ---- ---- ---- ---- ---- ----
reg [7:0] KEY_BYTE;
reg [7:0] PLAIN_BYTE;
reg START;
reg STOP;
reg HOLD;
wire START_KEY_CPY;
wire BUSY;
wire READ_PLAINTEXT;
wire [7:0] ENC_BYTE;

rc4 rc4_interface(
    .CLK_IN(CLK),
    .RESET_N_IN(RESET_N),
    .KEY_SIZE_IN(KEY_SIZE),
    .KEY_BYTE_IN(KEY_BYTE),
    .PLAIN_BYTE_IN(PLAIN_BYTE),
    .START_IN(START),
    .STOP_IN(STOP),
    .HOLD_IN(HOLD),
    .START_KEY_CPY_OUT(START_KEY_CPY),
    .BUSY_OUT(BUSY),
    .READ_PLAINTEXT_OUT(READ_PLAINTEXT),
    .ENC_BYTE_OUT(ENC_BYTE)
);
// STOP RC4 INTERFACE



// ---- ---- ---- ---- ---- ---- ---- ----
//                  CLOCK
// ---- ---- ---- ---- ---- ---- ---- ----
always
begin
    CLK = 1'b1; 
    #1;
    CLK = 1'b0;
    #1;
end // STOP CLOCK



// ---- ---- ---- ---- ---- ---- ---- ----
//              KEY TRNASFARE
// ---- ---- ---- ---- ---- ---- ---- ----
always @(posedge CLK)
begin
    if (START_KEY_CPY || key_counter)
    begin
        KEY_BYTE <= KEY[key_counter];
        if (key_counter == KEY_SIZE-1)
            key_counter <= 0;
        else
            key_counter <= key_counter +1;
    end
end // STOP KEY TRANSFARE



// ---- ---- ---- ---- ---- ---- ---- ----
//           PLAINTEXT TRNSAFARE
// ---- ---- ---- ---- ---- ---- ---- ----
always @(posedge CLK)
begin
    if (READ_PLAINTEXT || plain_counter)
    begin
        PLAIN_BYTE <= PLAINTEXT[plain_counter];
        if (plain_counter == PLAINTEXT_SIZE-1)
            plain_counter <= 0;
        else
            plain_counter <= plain_counter +1;
    end
end // STOP PLAINTEXT TRANSFARE



// ---- ---- ---- ---- ---- ---- ---- ----
// CIPHERTEXT TRNASFARE
// ---- ---- ---- ---- ---- ---- ---- ----
always @(posedge CLK)
begin
    if (plain_counter == 2 || cipher_counter)
    begin
        CAPTURED_CIPHERTEXT[cipher_counter] <= ENC_BYTE;
        // Debug ciphertext output
        //$display("CIPHERTEXT %d %h",cipher_counter, ENC_BYTE);
        if (cipher_counter == PLAINTEXT_SIZE-1)
            cipher_counter <= 0;
        else
            cipher_counter <= cipher_counter +1;
    end
end // STOP CIPHERTEXT TRANSFARE



// ---- ---- ---- ---- ---- ---- ---- ----
//                  MAIN
// ---- ---- ---- ---- ---- ---- ---- ----
initial
begin
    // ---- ---- ---- ---- ---- ---- ---- ----
    //              SETUP
    // ---- ---- ---- ---- ---- ---- ---- ----
    $display("[*] SYSTEM RESET ...");
    RESET_N = 0;
    HOLD = 0;
    STOP = 0;
    key_counter = 0;
    plain_counter = 0;
    cipher_counter = 0;
    error = 0;
    // KEY = ae6c3c41884d35df3ab5adf30f5b2d360938c658341886b0ba510b421e5ab405
    KEY[8'h00] = 8'hae; KEY[8'h01] = 8'h6c; KEY[8'h02] = 8'h3c; KEY[8'h03] = 8'h41; KEY[8'h04] = 8'h88; KEY[8'h05] = 8'h4d; KEY[8'h06] = 8'h35; KEY[8'h07] = 8'hdf;
    KEY[8'h08] = 8'h3a; KEY[8'h09] = 8'hb5; KEY[8'h0a] = 8'had; KEY[8'h0b] = 8'hf3; KEY[8'h0c] = 8'h0f; KEY[8'h0d] = 8'h5b; KEY[8'h0e] = 8'h2d; KEY[8'h0f] = 8'h36;
    KEY[8'h10] = 8'h09; KEY[8'h11] = 8'h38; KEY[8'h12] = 8'hc6; KEY[8'h13] = 8'h58; KEY[8'h14] = 8'h34; KEY[8'h15] = 8'h18; KEY[8'h16] = 8'h86; KEY[8'h17] = 8'hb0;
    KEY[8'h18] = 8'hba; KEY[8'h19] = 8'h51; KEY[8'h1a] = 8'h0b; KEY[8'h1b] = 8'h42; KEY[8'h1c] = 8'h1e; KEY[8'h1d] = 8'h5a; KEY[8'h1e] = 8'hb4; KEY[8'h1f] = 8'h05;
    $display("[*] ENCRYPTION KEY: (SIZE: 0x%H)", KEY_SIZE);
    $display("[+]    KEY[00:15]={0x%H 0x%H 0x%H 0x%H 0x%H 0x%H 0x%H 0x%H 0x%H 0x%H 0x%H 0x%H 0x%H 0x%H 0x%H 0x%H}", KEY[8'h00], KEY[8'h01], KEY[8'h02], KEY[8'h03], KEY[8'h04], KEY[8'h05], KEY[8'h06], KEY[8'h07], KEY[8'h08], KEY[8'h09], KEY[8'h0a], KEY[8'h0b], KEY[8'h0c], KEY[8'h0d], KEY[8'h0e], KEY[8'h0f]);
    $display("[+]    KEY[16:31]={0x%H 0x%H 0x%H 0x%H 0x%H 0x%H 0x%H 0x%H 0x%H 0x%H 0x%H 0x%H 0x%H 0x%H 0x%H 0x%H}", KEY[8'h10], KEY[8'h11], KEY[8'h12], KEY[8'h13], KEY[8'h14], KEY[8'h15], KEY[8'h16], KEY[8'h17], KEY[8'h18], KEY[8'h19], KEY[8'h1a], KEY[8'h1b], KEY[8'h1c], KEY[8'h1d], KEY[8'h1e], KEY[8'h1f]);
    // PLAINTEXT = 3ae280d0d5cd70d8e0f81300dc9031a2e0f8512cb35a7579fd79575cf287c595
    PLAINTEXT[8'h00] = 8'h3a; PLAINTEXT[8'h01] = 8'he2; PLAINTEXT[8'h02] = 8'h80; PLAINTEXT[8'h03] = 8'hd0; PLAINTEXT[8'h04] = 8'hd5; PLAINTEXT[8'h05] = 8'hcd; PLAINTEXT[8'h06] = 8'h70; PLAINTEXT[8'h07] = 8'hd8;
    PLAINTEXT[8'h08] = 8'he0; PLAINTEXT[8'h09] = 8'hf8; PLAINTEXT[8'h0a] = 8'h13; PLAINTEXT[8'h0b] = 8'h00; PLAINTEXT[8'h0c] = 8'hdc; PLAINTEXT[8'h0d] = 8'h90; PLAINTEXT[8'h0e] = 8'h31; PLAINTEXT[8'h0f] = 8'ha2;
    PLAINTEXT[8'h10] = 8'he0; PLAINTEXT[8'h11] = 8'hf8; PLAINTEXT[8'h12] = 8'h51; PLAINTEXT[8'h13] = 8'h2c; PLAINTEXT[8'h14] = 8'hb3; PLAINTEXT[8'h15] = 8'h5a; PLAINTEXT[8'h16] = 8'h75; PLAINTEXT[8'h17] = 8'h79;
    PLAINTEXT[8'h18] = 8'hfd; PLAINTEXT[8'h19] = 8'h79; PLAINTEXT[8'h1a] = 8'h57; PLAINTEXT[8'h1b] = 8'h5c; PLAINTEXT[8'h1c] = 8'hf2; PLAINTEXT[8'h1d] = 8'h87; PLAINTEXT[8'h1e] = 8'hc5; PLAINTEXT[8'h1f] = 8'h95;
    $display("[*] PLAINTEXT: (SIZE: 0x%H)", PLAINTEXT_SIZE);
    $display("[+]    PLAINTEXT[00:15]={0x%H 0x%H 0x%H 0x%H 0x%H 0x%H 0x%H 0x%H 0x%H 0x%H 0x%H 0x%H 0x%H 0x%H 0x%H 0x%H}", PLAINTEXT[8'h00], PLAINTEXT[8'h01], PLAINTEXT[8'h02], PLAINTEXT[8'h03], PLAINTEXT[8'h04], PLAINTEXT[8'h05], PLAINTEXT[8'h06], PLAINTEXT[8'h07], PLAINTEXT[8'h08], PLAINTEXT[8'h09], PLAINTEXT[8'h0a], PLAINTEXT[8'h0b], PLAINTEXT[8'h0c], PLAINTEXT[8'h0d], PLAINTEXT[8'h0e], PLAINTEXT[8'h0f]);
    $display("[+]    PLAINTEXT[16:31]={0x%H 0x%H 0x%H 0x%H 0x%H 0x%H 0x%H 0x%H 0x%H 0x%H 0x%H 0x%H 0x%H 0x%H 0x%H 0x%H}", PLAINTEXT[8'h10], PLAINTEXT[8'h11], PLAINTEXT[8'h12], PLAINTEXT[8'h13], PLAINTEXT[8'h14], PLAINTEXT[8'h15], PLAINTEXT[8'h16], PLAINTEXT[8'h17], PLAINTEXT[8'h18], PLAINTEXT[8'h19], PLAINTEXT[8'h1a], PLAINTEXT[8'h1b], PLAINTEXT[8'h1c], PLAINTEXT[8'h1d], PLAINTEXT[8'h1e], PLAINTEXT[8'h1f]);
    // KNOWN CYPHERTEXT = 2280c9676c8f5c52aba8d42611f85e7ca961a2117d3cfc8236a6051bbfc5f179
    KNOWN_CIPHERTEXT[8'h00] = 8'h22; KNOWN_CIPHERTEXT[8'h01] = 8'h80; KNOWN_CIPHERTEXT[8'h02] = 8'hc9; KNOWN_CIPHERTEXT[8'h03] = 8'h67; KNOWN_CIPHERTEXT[8'h04] = 8'h6c; KNOWN_CIPHERTEXT[8'h05] = 8'h8f; KNOWN_CIPHERTEXT[8'h06] = 8'h5c; KNOWN_CIPHERTEXT[8'h07] = 8'h52;
    KNOWN_CIPHERTEXT[8'h08] = 8'hab; KNOWN_CIPHERTEXT[8'h09] = 8'ha8; KNOWN_CIPHERTEXT[8'h0a] = 8'hd4; KNOWN_CIPHERTEXT[8'h0b] = 8'h26; KNOWN_CIPHERTEXT[8'h0c] = 8'h11; KNOWN_CIPHERTEXT[8'h0d] = 8'hf8; KNOWN_CIPHERTEXT[8'h0e] = 8'h5e; KNOWN_CIPHERTEXT[8'h0f] = 8'h7c;
    KNOWN_CIPHERTEXT[8'h10] = 8'ha9; KNOWN_CIPHERTEXT[8'h11] = 8'h61; KNOWN_CIPHERTEXT[8'h12] = 8'ha2; KNOWN_CIPHERTEXT[8'h13] = 8'h11; KNOWN_CIPHERTEXT[8'h14] = 8'h7d; KNOWN_CIPHERTEXT[8'h15] = 8'h3c; KNOWN_CIPHERTEXT[8'h16] = 8'hfc; KNOWN_CIPHERTEXT[8'h17] = 8'h82;
    KNOWN_CIPHERTEXT[8'h18] = 8'h36; KNOWN_CIPHERTEXT[8'h19] = 8'ha6; KNOWN_CIPHERTEXT[8'h1a] = 8'h05; KNOWN_CIPHERTEXT[8'h1b] = 8'h1b; KNOWN_CIPHERTEXT[8'h1c] = 8'hbf; KNOWN_CIPHERTEXT[8'h1d] = 8'hc5; KNOWN_CIPHERTEXT[8'h1e] = 8'hf1; KNOWN_CIPHERTEXT[8'h1f] = 8'h79;
    $display("[*] KNOWN CIPHERTEXT: (SIZE: 0x%H)", PLAINTEXT_SIZE);
    $display("[+]    KNOWN_CIPHERTEXT[00:15]={0x%H 0x%H 0x%H 0x%H 0x%H 0x%H 0x%H 0x%H 0x%H 0x%H 0x%H 0x%H 0x%H 0x%H 0x%H 0x%H}", KNOWN_CIPHERTEXT[8'h00], KNOWN_CIPHERTEXT[8'h01], KNOWN_CIPHERTEXT[8'h02], KNOWN_CIPHERTEXT[8'h03], KNOWN_CIPHERTEXT[8'h04], KNOWN_CIPHERTEXT[8'h05], KNOWN_CIPHERTEXT[8'h06], KNOWN_CIPHERTEXT[8'h07], KNOWN_CIPHERTEXT[8'h08], KNOWN_CIPHERTEXT[8'h09], KNOWN_CIPHERTEXT[8'h0a], KNOWN_CIPHERTEXT[8'h0b], KNOWN_CIPHERTEXT[8'h0c], KNOWN_CIPHERTEXT[8'h0d], KNOWN_CIPHERTEXT[8'h0e], KNOWN_CIPHERTEXT[8'h0f]);
    $display("[+]    KNOWN_CIPHERTEXT[16:31]={0x%H 0x%H 0x%H 0x%H 0x%H 0x%H 0x%H 0x%H 0x%H 0x%H 0x%H 0x%H 0x%H 0x%H 0x%H 0x%H}", KNOWN_CIPHERTEXT[8'h10], KNOWN_CIPHERTEXT[8'h11], KNOWN_CIPHERTEXT[8'h12], KNOWN_CIPHERTEXT[8'h13], KNOWN_CIPHERTEXT[8'h14], KNOWN_CIPHERTEXT[8'h15], KNOWN_CIPHERTEXT[8'h16], KNOWN_CIPHERTEXT[8'h17], KNOWN_CIPHERTEXT[8'h18], KNOWN_CIPHERTEXT[8'h19], KNOWN_CIPHERTEXT[8'h1a], KNOWN_CIPHERTEXT[8'h1b], KNOWN_CIPHERTEXT[8'h1c], KNOWN_CIPHERTEXT[8'h1d], KNOWN_CIPHERTEXT[8'h1e], KNOWN_CIPHERTEXT[8'h1f]);
    #5;
    RESET_N = 1;
    // STOP SETUP
    
    
    
    // ---- ---- ---- ---- ---- ---- ---- ----
    //              START SIGNAL
    // ---- ---- ---- ---- ---- ---- ---- ----
    #5;
    START = 1;
    #1;
    START = 0;
    // STOP START SIGNAL
    
    
    
    // ---- ---- ---- ---- ---- ---- ---- ----
    //                ANALYSIS
    // ---- ---- ---- ---- ---- ---- ---- ----
    #1500 
    $display("[*] CAPTURED CIPHERTEXT: (SIZE: 0x%H)", PLAINTEXT_SIZE);
    $display("[+]    CAPTURED_CIPHERTEXT[00:15]={0x%H 0x%H 0x%H 0x%H 0x%H 0x%H 0x%H 0x%H 0x%H 0x%H 0x%H 0x%H 0x%H 0x%H 0x%H 0x%H}", CAPTURED_CIPHERTEXT[8'h00], CAPTURED_CIPHERTEXT[8'h01], CAPTURED_CIPHERTEXT[8'h02], CAPTURED_CIPHERTEXT[8'h03], CAPTURED_CIPHERTEXT[8'h04], CAPTURED_CIPHERTEXT[8'h05], CAPTURED_CIPHERTEXT[8'h06], CAPTURED_CIPHERTEXT[8'h07], CAPTURED_CIPHERTEXT[8'h08], CAPTURED_CIPHERTEXT[8'h09], CAPTURED_CIPHERTEXT[8'h0a], CAPTURED_CIPHERTEXT[8'h0b], CAPTURED_CIPHERTEXT[8'h0c], CAPTURED_CIPHERTEXT[8'h0d], CAPTURED_CIPHERTEXT[8'h0e], CAPTURED_CIPHERTEXT[8'h0f]);
    $display("[+]    CAPTURED_CIPHERTEXT[16:31]={0x%H 0x%H 0x%H 0x%H 0x%H 0x%H 0x%H 0x%H 0x%H 0x%H 0x%H 0x%H 0x%H 0x%H 0x%H 0x%H}", CAPTURED_CIPHERTEXT[8'h10], CAPTURED_CIPHERTEXT[8'h11], CAPTURED_CIPHERTEXT[8'h12], CAPTURED_CIPHERTEXT[8'h13], CAPTURED_CIPHERTEXT[8'h14], CAPTURED_CIPHERTEXT[8'h15], CAPTURED_CIPHERTEXT[8'h16], CAPTURED_CIPHERTEXT[8'h17], CAPTURED_CIPHERTEXT[8'h18], CAPTURED_CIPHERTEXT[8'h19], CAPTURED_CIPHERTEXT[8'h1a], CAPTURED_CIPHERTEXT[8'h1b], CAPTURED_CIPHERTEXT[8'h1c], CAPTURED_CIPHERTEXT[8'h1d], CAPTURED_CIPHERTEXT[8'h1e], CAPTURED_CIPHERTEXT[8'h1f]);

    for (x=0; x < PLAINTEXT_SIZE-1; x= x+1)
    begin
        if (KNOWN_CIPHERTEXT[x] != CAPTURED_CIPHERTEXT[x])
        begin
            $display("[!] The known ciphertext does not match the captured ciphertext --> Element ID: %d / Known: 0x%H / Captured: 0x%H ", x, KNOWN_CIPHERTEXT[x], CAPTURED_CIPHERTEXT[x]);
            error = error +1;
        end
    end
    // STOP ANALYSIS
    
    
    
    // ---- ---- ---- ---- ---- ---- ---- ----
    //                  RESULT
    // ---- ---- ---- ---- ---- ---- ---- ----
    $display("---- ---- ---- ---- ---- ---- ---- ---- ---- RESULT ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ----");
    if (error == 0)
        $display("[*] The tests finished successfully ...");
    else
        $display("[!] The test did NOT finish successfully !!!");
    $display("---- ---- ---- ---- ---- ---- ---- ---- ---- RESULT ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ----");
    // STOP RESULT
    $stop;
end // STOP MAIN
endmodule // STOP RC4_TB
