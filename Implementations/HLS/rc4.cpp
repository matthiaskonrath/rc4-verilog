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

void rc4(
		uint16_t key_size_in,
		uint32_t plaintext_size_in,
		stream<uint8_t> &key_in,
		stream<uint8_t> &plaintext_in,
		stream<uint8_t> &ciphertext_out) {

	#pragma HLS INTERFACE ap_none port=key_size_in register
	#pragma HLS INTERFACE ap_none port=plaintext_size_in register
	#pragma HLS INTERFACE ap_fifo port=key_in depth=32
	#pragma HLS INTERFACE ap_fifo port=plaintext_in depth=32
	#pragma HLS INTERFACE ap_fifo port=ciphertext_out depth=32

	// Variable Declaration
	uint8_t array_s[N] = {0};
	uint8_t key[32] = {0};
	int i = 0;

	// Input Validation
	if (key_size_in == 0 || key_size_in > 32) {
		printf("[!] The key size is either zero or longer than 32 byte --> 256 bit (which is not allowed)!");
		return;
	}

	// Initialisation
	for(int i = 0; i < key_size_in; i++) {
		key[i] = key_in.read();
	}

	// KSA - Key Scheduling Algorithm
	ksa(array_s, key, plaintext_size_in);

	// PRGA - Pseudo Random Generation Algorithm
	prga(array_s, plaintext_in, ciphertext_out, plaintext_size_in);
}


void swap(uint8_t *a, uint8_t *b) {
#pragma HLS pipeline enable_flush rewind
	uint8_t tmp = *a;
    *a = *b;
    *b = tmp;
}

int ksa(uint8_t *array_s, uint8_t *key, uint16_t key_size) {
    int j = 0;
    int i = 0;

    for(i = 0; i < N; i++)
    	array_s[i] = i;

    for(i = 0; i < N; i++) {
        j = (j + array_s[i] + key[i % key_size]) % N;
        swap(&array_s[i], &array_s[j]);
    }
    return 0;
}

int prga(uint8_t *array_s, stream<uint8_t> &plaintext, stream<uint8_t> &ciphertext, uint32_t plaintext_size) {
#pragma HLS pipeline enable_flush rewind
	uint32_t i = 0;
	uint32_t j = 0;
	uint8_t keystream_byte = 0;
	uint8_t plaintext_byte = 0;
	uint8_t ciphertext_byte = 0;

    for(uint32_t n = 0; n < plaintext_size; n++) {
    	plaintext_byte = plaintext.read();
        i = (i + 1) % N;
        j = (j + array_s[i]) % N;
        swap(&array_s[i], &array_s[j]);
        keystream_byte = array_s[(array_s[i] + array_s[j]) % N];
        ciphertext_byte = keystream_byte ^ plaintext_byte;
        ciphertext << ciphertext_byte;
    }
    return 0;
}