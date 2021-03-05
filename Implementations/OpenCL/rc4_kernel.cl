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



kernel void rc4(global const unsigned char* key, const unsigned short key_size, global const unsigned char* plaintext, const unsigned int plaintext_size, global unsigned char* ciphertext) {
	typedef unsigned char uint8_t;
	typedef unsigned short uint16_t;
	typedef unsigned int uint32_t;

	// VARIABLE DEFINITION
	int j = 0;
	int i = 0;
	uint32_t n;
	uint8_t array_s[256] = { 0 };
	uint8_t tmp_array_switch = 0;

	// Array initialization
	for (i = 0; i < 256; i++)
		array_s[i] = i;

	// KSA --> Key Scheduling Algorithm
	j = 0;
	for (i = 0; i < 256; i++) {
		j = (j + array_s[i] + key[i % key_size]) % 256;
		tmp_array_switch = array_s[i];
		array_s[i] = array_s[j];
		array_s[j] = tmp_array_switch;
	}

	// PRGA --> Pseudo Random Generation Algorithm
	j = 0;
	i = 0;
	for (n = 0; n < plaintext_size; n++) {
		i = (i + 1) % 256;
		j = (j + array_s[i]) % 256;
		tmp_array_switch = array_s[i];
		array_s[i] = array_s[j];
		array_s[j] = tmp_array_switch;
		ciphertext[n] = array_s[(array_s[i] + array_s[j]) % 256] ^ plaintext[n];
	}
}
