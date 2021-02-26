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

#include "header.h"

int main(){
	// Variable Definition
	int i = 0;
	int error = 0;
	uint8_t ciphertext_byte = 0;

	uint16_t key_size = 32;
	// ae6c3c41884d35df3ab5adf30f5b2d360938c658341886b0ba510b421e5ab405
	uint8_t key[key_size] = {
			0xae, 0x6c, 0x3c, 0x41, 0x88, 0x4d, 0x35, 0xdf,
			0x3a, 0xb5, 0xad, 0xf3, 0x0f, 0x5b, 0x2d, 0x36,
			0x09, 0x38, 0xc6, 0x58, 0x34, 0x18, 0x86, 0xb0,
			0xba, 0x51, 0x0b, 0x42, 0x1e, 0x5a, 0xb4, 0x05
	};

	uint32_t plaintext_size = 32;
	// 3ae280d0d5cd70d8e0f81300dc9031a2e0f8512cb35a7579fd79575cf287c595
	uint8_t plaintext[plaintext_size] = {
			0x3a, 0xe2, 0x80, 0xd0, 0xd5, 0xcd, 0x70, 0xd8,
			0xe0, 0xf8, 0x13, 0x00, 0xdc, 0x90, 0x31, 0xa2,
			0xe0, 0xf8, 0x51, 0x2c, 0xb3, 0x5a, 0x75, 0x79,
			0xfd, 0x79, 0x57, 0x5c, 0xf2, 0x87, 0xc5, 0x95
	};

	// https://gchq.github.io/CyberChef/#recipe=RC4(%7B'option':'Hex','string':'ae6c3c41884d35df3ab5adf30f5b2d360938c658341886b0ba510b421e5ab405'%7D,'Hex','Hex')&input=M2FlMjgwZDBkNWNkNzBkOGUwZjgxMzAwZGM5MDMxYTJlMGY4NTEyY2IzNWE3NTc5ZmQ3OTU3NWNmMjg3YzU5NQ
	// 2280c9676c8f5c52aba8d42611f85e7ca961a2117d3cfc8236a6051bbfc5f179
	uint8_t known_ciphertext[plaintext_size] = {
			0x22, 0x80, 0xc9, 0x67, 0x6c, 0x8f, 0x5c, 0x52,
			0xab, 0xa8, 0xd4, 0x26, 0x11, 0xf8, 0x5e, 0x7c,
			0xa9, 0x61, 0xa2, 0x11, 0x7d, 0x3c, 0xfc, 0x82,
			0x36, 0xa6, 0x05, 0x1b, 0xbf, 0xc5, 0xf1, 0x79
	};

	stream<uint8_t> key_in;
	stream<uint8_t> plaintext_in;
	stream<uint8_t> ciphertext_out;

	// Filling the Streams
	printf("[*] KEY:         0x");
	for(i=0; i < key_size; i++) {
		key_in << key[i];
		printf("%02x", static_cast<int>(key[i]));
	}
	printf("\n");
	printf("[*] Plaintext:   0x");
	for(i=0; i < plaintext_size; i++) {
		plaintext_in << plaintext[i];
		printf("%02x", static_cast<int>(plaintext[i]));
	}
	printf("\n");


	// RC4 Algorithm
	rc4(
		key_size,
		plaintext_size,
		key_in,
		plaintext_in,
		ciphertext_out);

	// Ciphertext extraction and checking
	printf("[*] Ciphertext:  0x");
	for(i=0; i < plaintext_size; i++) {
		ciphertext_out >> ciphertext_byte;
		printf("%02x", static_cast<int>(ciphertext_byte));
		if (ciphertext_byte != known_ciphertext[i])
			error += 1;
	}
	printf("\n");

	// Print Plaintext
	printf("[*] Known Ciph.: 0x");
	for(i=0; i < plaintext_size; i++) {
		printf("%02x", static_cast<int>(known_ciphertext[i]));
	}
	printf("\n");

	// Print PASS / FAIL
	printf("---- ---- ---- ---- ---- ---- ---- ----\n");
	if (error == 0){
		printf("[*] ... PASSED ...\n");
		printf("---- ---- ---- ---- ---- ---- ---- ----\n");
		return 0;
	} else {
		printf("[!] ... FAILED ...\n");
		printf("---- ---- ---- ---- ---- ---- ---- ----\n");
		return 1;
	}
}
