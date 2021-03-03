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


module controller(
    input wire CLK100MHZ,
    input wire btnC,
    input wire btnCpuReset,
    output wire [7:0] led
    );

parameter KEY_SIZE=32;          // 256 Bit Key
parameter PLAINTEXT_SIZE=32;

reg [7:0] KEY [0:31];
reg [7:0] PLAINTEXT [0:31];
reg [7:0] key_counter;
reg [7:0] plain_counter;
reg [7:0] cipher_counter;
reg [7:0] cipher_byte;
reg btn_debounce;
reg trigger;

assign led[7:0] = cipher_byte;



// ---- ---- ---- ---- ---- ---- ---- ----
//               CLOCK SETUP
// ---- ---- ---- ---- ---- ---- ---- ----
wire CLK115MHZ;
wire alternative_clk;
assign alternative_clk = CLK115MHZ;
wire clk_locked;

clk_wiz_0 clk_generator (
  // Clock out ports
  .clk_out1(CLK115MHZ),
  .clk_in1(CLK100MHZ)
);
// STOP CLOCK SETUP



// ---- ---- ---- ---- ---- ---- ---- ----
//                RC4 SETUP
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
    .CLK_IN(alternative_clk),
    .RESET_N_IN(btnCpuReset),
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
// STOP RC4 SETUP



// ---- ---- ---- ---- ---- ---- ---- ----
//                  MAIN
// ---- ---- ---- ---- ---- ---- ---- ----
always @(posedge alternative_clk) begin
    // ---- ---- ---- ---- ---- ---- ---- ----
    //                  RESET
    // ---- ---- ---- ---- ---- ---- ---- ----
    if(!btnCpuReset)
    begin
        STOP <= 0;
        HOLD <= 0;
        cipher_byte <= 0;
        cipher_counter <= 0;
        trigger <= 0;
        btn_debounce <= 1;
        plain_counter <= 0;
        // KEY = ae6c3c41884d35df3ab5adf30f5b2d360938c658341886b0ba510b421e5ab405
        KEY[8'h00] = 8'hae; KEY[8'h01] = 8'h6c; KEY[8'h02] = 8'h3c; KEY[8'h03] = 8'h41; KEY[8'h04] = 8'h88; KEY[8'h05] = 8'h4d; KEY[8'h06] = 8'h35; KEY[8'h07] = 8'hdf;
        KEY[8'h08] = 8'h3a; KEY[8'h09] = 8'hb5; KEY[8'h0a] = 8'had; KEY[8'h0b] = 8'hf3; KEY[8'h0c] = 8'h0f; KEY[8'h0d] = 8'h5b; KEY[8'h0e] = 8'h2d; KEY[8'h0f] = 8'h36;
        KEY[8'h10] = 8'h09; KEY[8'h11] = 8'h38; KEY[8'h12] = 8'hc6; KEY[8'h13] = 8'h58; KEY[8'h14] = 8'h34; KEY[8'h15] = 8'h18; KEY[8'h16] = 8'h86; KEY[8'h17] = 8'hb0;
        KEY[8'h18] = 8'hba; KEY[8'h19] = 8'h51; KEY[8'h1a] = 8'h0b; KEY[8'h1b] = 8'h42; KEY[8'h1c] = 8'h1e; KEY[8'h1d] = 8'h5a; KEY[8'h1e] = 8'hb4; KEY[8'h1f] = 8'h05;
        // PLAINTEXT = 3ae280d0d5cd70d8e0f81300dc9031a2e0f8512cb35a7579fd79575cf287c595
        PLAINTEXT[8'h00] = 8'h3a; PLAINTEXT[8'h01] = 8'he2; PLAINTEXT[8'h02] = 8'h80; PLAINTEXT[8'h03] = 8'hd0; PLAINTEXT[8'h04] = 8'hd5; PLAINTEXT[8'h05] = 8'hcd; PLAINTEXT[8'h06] = 8'h70; PLAINTEXT[8'h07] = 8'hd8;
        PLAINTEXT[8'h08] = 8'he0; PLAINTEXT[8'h09] = 8'hf8; PLAINTEXT[8'h0a] = 8'h13; PLAINTEXT[8'h0b] = 8'h00; PLAINTEXT[8'h0c] = 8'hdc; PLAINTEXT[8'h0d] = 8'h90; PLAINTEXT[8'h0e] = 8'h31; PLAINTEXT[8'h0f] = 8'ha2;
        PLAINTEXT[8'h10] = 8'he0; PLAINTEXT[8'h11] = 8'hf8; PLAINTEXT[8'h12] = 8'h51; PLAINTEXT[8'h13] = 8'h2c; PLAINTEXT[8'h14] = 8'hb3; PLAINTEXT[8'h15] = 8'h5a; PLAINTEXT[8'h16] = 8'h75; PLAINTEXT[8'h17] = 8'h79;
        PLAINTEXT[8'h18] = 8'hfd; PLAINTEXT[8'h19] = 8'h79; PLAINTEXT[8'h1a] = 8'h57; PLAINTEXT[8'h1b] = 8'h5c; PLAINTEXT[8'h1c] = 8'hf2; PLAINTEXT[8'h1d] = 8'h87; PLAINTEXT[8'h1e] = 8'hc5; PLAINTEXT[8'h1f] = 8'h95;
    end // STOP RESET
    else begin
        // ---- ---- ---- ---- ---- ---- ---- ----
        //              START SIGNAL
        // ---- ---- ---- ---- ---- ---- ---- ----
        if(btnC && btn_debounce) begin
            btn_debounce <= 0;
            START <= 1'b1;
        end if(START) begin
            START <= 1'b0;
        end // STOP START SIGNAL
        
        
        
        // ---- ---- ---- ---- ---- ---- ---- ----
        //              KEY TRNAFARE
        // ---- ---- ---- ---- ---- ---- ---- ----
        if (START_KEY_CPY || key_counter) begin
            if (key_counter == KEY_SIZE) begin
                key_counter <= 0;
                KEY_BYTE <= 8'b00;
            end else begin
                key_counter <= key_counter +1;
                KEY_BYTE <= KEY[key_counter];
            end
        end// STOP KEY TRANSFARE
        
        
        
        // ---- ---- ---- ---- ---- ---- ---- ----
        //          PLAINTEXT TRNAFARE
        // ---- ---- ---- ---- ---- ---- ---- ----
        if (READ_PLAINTEXT || plain_counter) begin
            if (plain_counter == PLAINTEXT_SIZE) begin
                plain_counter <= 0;
                PLAIN_BYTE <= 8'b00;
            end else begin
                plain_counter <= plain_counter +1;
                PLAIN_BYTE <= PLAINTEXT[plain_counter];
            end
        end // STOP PLAINTEXT TRANSFARE
        
        
        
        // ---- ---- ---- ---- ---- ---- ---- ----
        //    CIPHERTEXT TRANSFARE (ELEMENT 32)
        //     LED[7:0] --> 01111001 --> 0x79 
        // ---- ---- ---- ---- ---- ---- ---- ----
        //if (trigger == 0 && plain_counter == 2)
        if (trigger == 0 && cipher_counter == PLAINTEXT_SIZE-1) begin
            HOLD <= 1'b1;
            trigger <= 1;
            cipher_byte <= ENC_BYTE;
        end else begin
            if (plain_counter == 2 || cipher_counter)
                cipher_counter <= cipher_counter +1;
        end // STOP CIPHERTEXT TRANSFARE
    end
end // STOP MAIN
endmodule // STOP CONTROLLER