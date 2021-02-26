# RC4 - Verilog

### General Information
- 87.5MHz speed was achived on the Nexys 4 (xc7a100tcsg324-1)
    - WNS=0.089 / TNS=0.0ns / WHS=0.026ns / THS=0.0ns
    - Total On-Chip Pwer: ~0.237W
- ~500 cycles after the reset, encrypted output gets generated
- Every cycle one byte gets encrypted
- To use the RC4 block as an cheap PRNG just put a 8'b00 into the PLAIN_BYTE_IN

### Resource Utilization on Nexys 4 (xc7a100tcsg324-1)
(This inlcudes the test code from controller.v)
| Resource | Utilization | Available | Utilization (%) |
| ------ | ------ | ------ | ------ |
| LUT | 11557 | 63400 | 18.23 |
| FF | 2548 | 126800 | 2.01 |
| IO | 19 | 210 | 9.05 |
| BUFG | 2 | 32 | 6.25 |
| MMCM | 1 | 6 | 16.67 |

### Speed tests
| Implementation | Device | Frequency | Speed (Mbit/s) | Speed (MB/s) | Notes |
| ------ | ------ | ------ | ------ | ------ | ------ |
| Verilog | Nexys4 | ~88 MHz | ~704 Mbit/s | ~88 MB/s | optimized implementation |
| HLS (C++) | Nexys4 | ~200 MHz | ~160 Mbit/s | ~20 MB/s | optimized implementation |
| C++ | i7-8665U | unknown | ~120 Mbit/s | ~15 MB/s | not optimized / single threaded |
| Python | i7-8665U | unknown | ~40 Mbit/s | ~5 MB/s | not optimized / single threaded |

### Implementation Information
##### For details see rc4_tb.v or controller.v
#### Instantiation
```verilog
rc4 rc4_interface(
    .CLK_IN(CLK),                       // Clock input
    .RESET_N_IN(RESET_N),               // Active low reset line
    .KEY_SIZE_IN(KEY_SIZE),             // Key size in bytes
    .KEY_BYTE_IN(KEY_BYTE),             // During the setup the key is transfared byte by byte via this register
    .PLAIN_BYTE_IN(PLAIN_BYTE),         // During the normal operation every cycle one plaintext byte is transfared via this register for encryption (for PRNG operation just set 8'h00 as input)
    .START_IN(START),                   // One positive clock cycle on this register signals the RC4 module that it should start the setup process
    .STOP_IN(STOP),                     // One positive clock cycle on this register signals the RC4 module that it should stop (reset --> return to IDLE)
    .HOLD_IN(HOLD),                     // As long as this register is pulled high no further encryption / PRNG generation happens (waites for a low signal)
    .START_KEY_CPY_OUT(START_KEY_CPY),  // During the setup this wire gets pulled to high for one clock cycle to indicate the start of the key transfare to the RC4 module
    .BUSY_OUT(BUSY),                    // If the RC4 module is not in IDLE this signal is pulled to high
    .READ_PLAINTEXT_OUT(READ_PLAINTEXT),// After the setup is complete, this wire gets pulled to high for one clock cycle to indicate the start of the normal operation (if a plaintext should be encrypted it now needs to be placed into the PLAIN_BYTE register one byte after the other every clock cycle)
    .ENC_BYTE_OUT(ENC_BYTE)             // One clock cycle after the plaintext byte was put into the PLAIN_BYTE register the encrypted byte needs to be copied from the ENC_BYTE register
);
```

#### Key Transfare Code
```verilog
always @(posedge CLK)
begin
    if (START_KEY_CPY || key_counter)
    begin
        
        if (key_counter == KEY_SIZE)
        begin
            key_counter <= 0;
            KEY_BYTE <= 8'b00;
        end
        else
        begin
            key_counter <= key_counter +1;
            KEY_BYTE <= KEY[key_counter];
        end
    end
end
```

#### Plaintext Transfare Code (stops after the counter overflows or the plaintext size is reached)
```verilog
always @(posedge CLK)
begin
    if (READ_PLAINTEXT || plain_counter)
    begin
        if (plain_counter == PLAINTEXT_SIZE)
        begin
            plain_counter <= 0;
            PLAIN_BYTE <= 8'b00;
        end
        else
        begin
            plain_counter <= plain_counter +1;
            PLAIN_BYTE <= PLAINTEXT[plain_counter];
        end
    end
end
```

#### Ciphertext Transfare Code (stops after the counter overflows or the plaintext / ciphertext size is reached)
```verilog
always @(posedge CLK)
begin
    if (plain_counter == 2 || cipher_counter)
    begin
        CAPTURED_CIPHERTEXT[cipher_counter] <= ENC_BYTE;
        if (cipher_counter == PLAINTEXT_SIZE-1)
            cipher_counter <= 0;
        else
            cipher_counter <= cipher_counter +1;
    end
end
```

### Useful links
- https://en.wikipedia.org/wiki/RC4
- https://www.binaryhexconverter.com/binary-to-hex-converter
- https://gchq.github.io/CyberChef
- https://reference.digilentinc.com/reference/programmable-logic/nexys-4/start
