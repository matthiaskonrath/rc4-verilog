`timescale 1ns / 1ps
/*
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

module rc4(
    input wire CLK_IN,
    input wire RESET_N_IN,
    input wire [7:0] KEY_SIZE_IN,
    input wire [7:0] KEY_BYTE_IN,
    input wire [7:0] PLAIN_BYTE_IN,
    input wire START_IN,
    input wire STOP_IN,
    input wire HOLD_IN,
    output reg START_KEY_CPY_OUT,
    output reg BUSY_OUT,
    output reg READ_PLAINTEXT_OUT,
    output reg [7:0] ENC_BYTE_OUT
    );
       
    /*
        RC4 - FSM
        States:
            IDLE        --> Nothing happens here (state after STOP signal or a reset)
            ----
            KEY_CPY     --> The key gets copied into the internal storage
              |
            KSA         --> The Key-Scheduling-Alorithm is executed
              |
            PRGA <-|    --> The Psoudo-Random-Generation-Algorithm is executed (continuas output is generated)
              |____|
    */
    
    localparam  [1:0]
        IDLE    = 2'b00,
        KEY_CPY = 2'b01,
        KSA     = 2'b10,
        PRGA    = 2'b11;
    
    reg [1:0] fsm;
    reg [7:0] array_s [0:255];
    reg [7:0] key [0:31];
    reg [7:0] key_length;
    reg [7:0] key_cpy_counter;
    reg [7:0] ksa_counter;
    reg [7:0] ksa_j;
    reg [7:0] prga_counter;
    reg [7:0] prga_j;
    reg [7:0] array_selector;
    
    
    
    // ---- ---- ---- ---- ---- ---- ---- ----
    //                  MAIN
    // ---- ---- ---- ---- ---- ---- ---- ----
    always @(posedge CLK_IN) begin 
        // ---- ---- ---- ---- ---- ---- ---- ----
        //              RESET
        // ---- ---- ---- ---- ---- ---- ---- ----
        if (!RESET_N_IN || STOP_IN) begin
            // SET FSM
            fsm <= IDLE;
            // SET PORTS
            START_KEY_CPY_OUT <= 0;
            BUSY_OUT <= 0;
            READ_PLAINTEXT_OUT <= 0;
            ENC_BYTE_OUT <= 0;
            // SET VARIABLES
            key_length <= 0;
            key_cpy_counter <= 0;
            ksa_counter <= 0;
            ksa_j <= 0;
            prga_counter <= 1;
            prga_j <= 0;
            array_selector <= 0;
            // SET ARRAY_S
            array_s[8'h00] <= 8'h00; array_s[8'h01] <= 8'h01; array_s[8'h02] <= 8'h02; array_s[8'h03] <= 8'h03; array_s[8'h04] <= 8'h04; array_s[8'h05] <= 8'h05; array_s[8'h06] <= 8'h06; array_s[8'h07] <= 8'h07; array_s[8'h08] <= 8'h08; array_s[8'h09] <= 8'h09; array_s[8'h0a] <= 8'h0a; array_s[8'h0b] <= 8'h0b; array_s[8'h0c] <= 8'h0c; array_s[8'h0d] <= 8'h0d; array_s[8'h0e] <= 8'h0e; array_s[8'h0f] <= 8'h0f;
            array_s[8'h10] <= 8'h10; array_s[8'h11] <= 8'h11; array_s[8'h12] <= 8'h12; array_s[8'h13] <= 8'h13; array_s[8'h14] <= 8'h14; array_s[8'h15] <= 8'h15; array_s[8'h16] <= 8'h16; array_s[8'h17] <= 8'h17; array_s[8'h18] <= 8'h18; array_s[8'h19] <= 8'h19; array_s[8'h1a] <= 8'h1a; array_s[8'h1b] <= 8'h1b; array_s[8'h1c] <= 8'h1c; array_s[8'h1d] <= 8'h1d; array_s[8'h1e] <= 8'h1e; array_s[8'h1f] <= 8'h1f;
            array_s[8'h20] <= 8'h20; array_s[8'h21] <= 8'h21; array_s[8'h22] <= 8'h22; array_s[8'h23] <= 8'h23; array_s[8'h24] <= 8'h24; array_s[8'h25] <= 8'h25; array_s[8'h26] <= 8'h26; array_s[8'h27] <= 8'h27; array_s[8'h28] <= 8'h28; array_s[8'h29] <= 8'h29; array_s[8'h2a] <= 8'h2a; array_s[8'h2b] <= 8'h2b; array_s[8'h2c] <= 8'h2c; array_s[8'h2d] <= 8'h2d; array_s[8'h2e] <= 8'h2e; array_s[8'h2f] <= 8'h2f;
            array_s[8'h30] <= 8'h30; array_s[8'h31] <= 8'h31; array_s[8'h32] <= 8'h32; array_s[8'h33] <= 8'h33; array_s[8'h34] <= 8'h34; array_s[8'h35] <= 8'h35; array_s[8'h36] <= 8'h36; array_s[8'h37] <= 8'h37; array_s[8'h38] <= 8'h38; array_s[8'h39] <= 8'h39; array_s[8'h3a] <= 8'h3a; array_s[8'h3b] <= 8'h3b; array_s[8'h3c] <= 8'h3c; array_s[8'h3d] <= 8'h3d; array_s[8'h3e] <= 8'h3e; array_s[8'h3f] <= 8'h3f;
            array_s[8'h40] <= 8'h40; array_s[8'h41] <= 8'h41; array_s[8'h42] <= 8'h42; array_s[8'h43] <= 8'h43; array_s[8'h44] <= 8'h44; array_s[8'h45] <= 8'h45; array_s[8'h46] <= 8'h46; array_s[8'h47] <= 8'h47; array_s[8'h48] <= 8'h48; array_s[8'h49] <= 8'h49; array_s[8'h4a] <= 8'h4a; array_s[8'h4b] <= 8'h4b; array_s[8'h4c] <= 8'h4c; array_s[8'h4d] <= 8'h4d; array_s[8'h4e] <= 8'h4e; array_s[8'h4f] <= 8'h4f;
            array_s[8'h50] <= 8'h50; array_s[8'h51] <= 8'h51; array_s[8'h52] <= 8'h52; array_s[8'h53] <= 8'h53; array_s[8'h54] <= 8'h54; array_s[8'h55] <= 8'h55; array_s[8'h56] <= 8'h56; array_s[8'h57] <= 8'h57; array_s[8'h58] <= 8'h58; array_s[8'h59] <= 8'h59; array_s[8'h5a] <= 8'h5a; array_s[8'h5b] <= 8'h5b; array_s[8'h5c] <= 8'h5c; array_s[8'h5d] <= 8'h5d; array_s[8'h5e] <= 8'h5e; array_s[8'h5f] <= 8'h5f;
            array_s[8'h60] <= 8'h60; array_s[8'h61] <= 8'h61; array_s[8'h62] <= 8'h62; array_s[8'h63] <= 8'h63; array_s[8'h64] <= 8'h64; array_s[8'h65] <= 8'h65; array_s[8'h66] <= 8'h66; array_s[8'h67] <= 8'h67; array_s[8'h68] <= 8'h68; array_s[8'h69] <= 8'h69; array_s[8'h6a] <= 8'h6a; array_s[8'h6b] <= 8'h6b; array_s[8'h6c] <= 8'h6c; array_s[8'h6d] <= 8'h6d; array_s[8'h6e] <= 8'h6e; array_s[8'h6f] <= 8'h6f;
            array_s[8'h70] <= 8'h70; array_s[8'h71] <= 8'h71; array_s[8'h72] <= 8'h72; array_s[8'h73] <= 8'h73; array_s[8'h74] <= 8'h74; array_s[8'h75] <= 8'h75; array_s[8'h76] <= 8'h76; array_s[8'h77] <= 8'h77; array_s[8'h78] <= 8'h78; array_s[8'h79] <= 8'h79; array_s[8'h7a] <= 8'h7a; array_s[8'h7b] <= 8'h7b; array_s[8'h7c] <= 8'h7c; array_s[8'h7d] <= 8'h7d; array_s[8'h7e] <= 8'h7e; array_s[8'h7f] <= 8'h7f;
            array_s[8'h80] <= 8'h80; array_s[8'h81] <= 8'h81; array_s[8'h82] <= 8'h82; array_s[8'h83] <= 8'h83; array_s[8'h84] <= 8'h84; array_s[8'h85] <= 8'h85; array_s[8'h86] <= 8'h86; array_s[8'h87] <= 8'h87; array_s[8'h88] <= 8'h88; array_s[8'h89] <= 8'h89; array_s[8'h8a] <= 8'h8a; array_s[8'h8b] <= 8'h8b; array_s[8'h8c] <= 8'h8c; array_s[8'h8d] <= 8'h8d; array_s[8'h8e] <= 8'h8e; array_s[8'h8f] <= 8'h8f;
            array_s[8'h90] <= 8'h90; array_s[8'h91] <= 8'h91; array_s[8'h92] <= 8'h92; array_s[8'h93] <= 8'h93; array_s[8'h94] <= 8'h94; array_s[8'h95] <= 8'h95; array_s[8'h96] <= 8'h96; array_s[8'h97] <= 8'h97; array_s[8'h98] <= 8'h98; array_s[8'h99] <= 8'h99; array_s[8'h9a] <= 8'h9a; array_s[8'h9b] <= 8'h9b; array_s[8'h9c] <= 8'h9c; array_s[8'h9d] <= 8'h9d; array_s[8'h9e] <= 8'h9e; array_s[8'h9f] <= 8'h9f; 
            array_s[8'ha0] <= 8'ha0; array_s[8'ha1] <= 8'ha1; array_s[8'ha2] <= 8'ha2; array_s[8'ha3] <= 8'ha3; array_s[8'ha4] <= 8'ha4; array_s[8'ha5] <= 8'ha5; array_s[8'ha6] <= 8'ha6; array_s[8'ha7] <= 8'ha7; array_s[8'ha8] <= 8'ha8; array_s[8'ha9] <= 8'ha9; array_s[8'haa] <= 8'haa; array_s[8'hab] <= 8'hab; array_s[8'hac] <= 8'hac; array_s[8'had] <= 8'had; array_s[8'hae] <= 8'hae; array_s[8'haf] <= 8'haf;
            array_s[8'hb0] <= 8'hb0; array_s[8'hb1] <= 8'hb1; array_s[8'hb2] <= 8'hb2; array_s[8'hb3] <= 8'hb3; array_s[8'hb4] <= 8'hb4; array_s[8'hb5] <= 8'hb5; array_s[8'hb6] <= 8'hb6; array_s[8'hb7] <= 8'hb7; array_s[8'hb8] <= 8'hb8; array_s[8'hb9] <= 8'hb9; array_s[8'hba] <= 8'hba; array_s[8'hbb] <= 8'hbb; array_s[8'hbc] <= 8'hbc; array_s[8'hbd] <= 8'hbd; array_s[8'hbe] <= 8'hbe; array_s[8'hbf] <= 8'hbf;
            array_s[8'hc0] <= 8'hc0; array_s[8'hc1] <= 8'hc1; array_s[8'hc2] <= 8'hc2; array_s[8'hc3] <= 8'hc3; array_s[8'hc4] <= 8'hc4; array_s[8'hc5] <= 8'hc5; array_s[8'hc6] <= 8'hc6; array_s[8'hc7] <= 8'hc7; array_s[8'hc8] <= 8'hc8; array_s[8'hc9] <= 8'hc9; array_s[8'hca] <= 8'hca; array_s[8'hcb] <= 8'hcb; array_s[8'hcc] <= 8'hcc; array_s[8'hcd] <= 8'hcd; array_s[8'hce] <= 8'hce; array_s[8'hcf] <= 8'hcf;
            array_s[8'hd0] <= 8'hd0; array_s[8'hd1] <= 8'hd1; array_s[8'hd2] <= 8'hd2; array_s[8'hd3] <= 8'hd3; array_s[8'hd4] <= 8'hd4; array_s[8'hd5] <= 8'hd5; array_s[8'hd6] <= 8'hd6; array_s[8'hd7] <= 8'hd7; array_s[8'hd8] <= 8'hd8; array_s[8'hd9] <= 8'hd9; array_s[8'hda] <= 8'hda; array_s[8'hdb] <= 8'hdb; array_s[8'hdc] <= 8'hdc; array_s[8'hdd] <= 8'hdd; array_s[8'hde] <= 8'hde; array_s[8'hdf] <= 8'hdf;
            array_s[8'he0] <= 8'he0; array_s[8'he1] <= 8'he1; array_s[8'he2] <= 8'he2; array_s[8'he3] <= 8'he3; array_s[8'he4] <= 8'he4; array_s[8'he5] <= 8'he5; array_s[8'he6] <= 8'he6; array_s[8'he7] <= 8'he7; array_s[8'he8] <= 8'he8; array_s[8'he9] <= 8'he9; array_s[8'hea] <= 8'hea; array_s[8'heb] <= 8'heb; array_s[8'hec] <= 8'hec; array_s[8'hed] <= 8'hed; array_s[8'hee] <= 8'hee; array_s[8'hef] <= 8'hef;
            array_s[8'hf0] <= 8'hf0; array_s[8'hf1] <= 8'hf1; array_s[8'hf2] <= 8'hf2; array_s[8'hf3] <= 8'hf3; array_s[8'hf4] <= 8'hf4; array_s[8'hf5] <= 8'hf5; array_s[8'hf6] <= 8'hf6; array_s[8'hf7] <= 8'hf7; array_s[8'hf8] <= 8'hf8; array_s[8'hf9] <= 8'hf9; array_s[8'hfa] <= 8'hfa; array_s[8'hfb] <= 8'hfb; array_s[8'hfc] <= 8'hfc; array_s[8'hfd] <= 8'hfd; array_s[8'hfe] <= 8'hfe; array_s[8'hff] <= 8'hff;
            // Reset KEY
            key[8'h00] <= 8'h00; key[8'h01] <= 8'h00; key[8'h02] <= 8'h00; key[8'h03] <= 8'h00; key[8'h04] <= 8'h00; key[8'h05] <= 8'h00; key[8'h06] <= 8'h00; key[8'h07] <= 8'h00;
            key[8'h08] <= 8'h00; key[8'h09] <= 8'h00; key[8'h0a] <= 8'h00; key[8'h0b] <= 8'h00; key[8'h0c] <= 8'h00; key[8'h0d] <= 8'h00; key[8'h0e] <= 8'h00; key[8'h0f] <= 8'h00;
            key[8'h10] <= 8'h00; key[8'h11] <= 8'h00; key[8'h12] <= 8'h00; key[8'h13] <= 8'h00; key[8'h14] <= 8'h00; key[8'h15] <= 8'h00; key[8'h16] <= 8'h00; key[8'h17] <= 8'h00;
            key[8'h18] <= 8'h00; key[8'h19] <= 8'h00; key[8'h1a] <= 8'h00; key[8'h1b] <= 8'h00; key[8'h1c] <= 8'h00; key[8'h1d] <= 8'h00; key[8'h1e] <= 8'h00; key[8'h1f] <= 8'h00;
        end // STOP RESET
        else begin
            // ---- ---- ---- ---- ---- ---- ---- ----
            //                  FSM
            // ---- ---- ---- ---- ---- ---- ---- ----
            case(fsm)
            // ---- ---- ---- ---- ---- ---- ---- ----
            //                   IDLE
            // ---- ---- ---- ---- ---- ---- ---- ----
            IDLE: begin
                if (START_IN) begin
                    fsm <= KEY_CPY;
                    START_KEY_CPY_OUT <= 1;
                    BUSY_OUT <= 1'b1;
                end
            end // STOP IDLE
            // ---- ---- ---- ---- ---- ---- ---- ----
            //                KEY COPY
            // ---- ---- ---- ---- ---- ---- ---- ----
            KEY_CPY: begin
                // START KEY_CPY SETUP
                if (START_KEY_CPY_OUT) begin
                    START_KEY_CPY_OUT <= 0;
                    key_length <= KEY_SIZE_IN;
                end // STOP KEY_CPY SETUP
                else begin // START KEY_CPY LOOP
                    key[key_cpy_counter] <= KEY_BYTE_IN;
                    key_cpy_counter <= key_cpy_counter +1;
                    if (key_cpy_counter == key_length -1) begin
                        fsm <= KSA;
                        ksa_j <= (array_s[0] + key[0]);
                    end
                end // STOP KEY_CPY LOOP
            end // STOP KEY_CPY
            // ---- ---- ---- ---- ---- ---- ---- ----
            //      Key-Scheduling-Alorithm (KSA)
            // ---- ---- ---- ---- ---- ---- ---- ----
           KSA: begin
                ksa_counter <= ksa_counter +1;
                if (ksa_counter +1 == ksa_j)
                    ksa_j <= (ksa_j + array_s[(ksa_counter)] + key[(ksa_counter +1) % (key_length)]);
                else
                    ksa_j <= (ksa_j + array_s[(ksa_counter+1)] + key[(ksa_counter +1) % (key_length)]);
                array_s[ksa_j] <= array_s[ksa_counter];
                array_s[ksa_counter] <= array_s[ksa_j];
                if (ksa_counter == 255) begin
                    fsm <= PRGA;
                    prga_j <= prga_j + array_s[prga_counter];
                    READ_PLAINTEXT_OUT <= 1'b1;
                end
            end // STOP KSA
            // ---- ---- ---- ---- ---- ---- ---- ----
            // Psoudo-Random-Generation-Algorithm (PRGA)
            // ---- ---- ---- ---- ---- ---- ---- ----
            PRGA: begin
                if (READ_PLAINTEXT_OUT)
                    READ_PLAINTEXT_OUT <= 1'b0;
                //else
                //begin
                    if (!HOLD_IN) begin
                        prga_counter <= prga_counter +1;
                        if ((prga_counter +1) == prga_j)
                            prga_j <= prga_j + array_s[prga_counter];
                        else
                            prga_j <= prga_j + array_s[prga_counter +1];
                        array_s[prga_j] <= array_s[prga_counter];
                        array_s[prga_counter] <= array_s[prga_j];
                        array_selector <= array_s[prga_j] + array_s[prga_counter];
                        ENC_BYTE_OUT <= array_s[array_selector] ^ PLAIN_BYTE_IN;
                    end // STOP PRGA LOOP
                 //end // STOP HOLD_IN
            end // STOP PRGA
            endcase // STOP FSM
        end // STOP RESET ELSE
    end // STOP MAIN
endmodule