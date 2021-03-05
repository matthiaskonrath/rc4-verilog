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



#include <chrono>
#include <iostream>
#include <stdio.h>
#include <cstring>

#define N 256

using namespace std;

void rc4(
	uint16_t key_size_in,
	uint32_t plaintext_size_in,
	uint8_t* key_in,
	uint8_t* plaintext_in,
	uint8_t* ciphertext_out
);

void swap(uint8_t* a, uint8_t* b);
int ksa(uint8_t* S, uint8_t* key, uint16_t key_size);
int prga(uint8_t* S, uint8_t* plaintext, uint8_t* ciphertext, uint32_t plaintext_size);


int main()
{
	// Variable Definition
	int i = 0;
	int error = 0;

	const uint16_t key_size = 32;
	// ae6c3c41884d35df3ab5adf30f5b2d360938c658341886b0ba510b421e5ab405
	uint8_t key[key_size] = {
			0xae, 0x6c, 0x3c, 0x41, 0x88, 0x4d, 0x35, 0xdf,
			0x3a, 0xb5, 0xad, 0xf3, 0x0f, 0x5b, 0x2d, 0x36,
			0x09, 0x38, 0xc6, 0x58, 0x34, 0x18, 0x86, 0xb0,
			0xba, 0x51, 0x0b, 0x42, 0x1e, 0x5a, 0xb4, 0x05
	};

	const uint32_t plaintext_size = 32;
	// 3ae280d0d5cd70d8e0f81300dc9031a2e0f8512cb35a7579fd79575cf287c595
	uint8_t plaintext[plaintext_size] = {
			0x3a, 0xe2, 0x80, 0xd0, 0xd5, 0xcd, 0x70, 0xd8,
			0xe0, 0xf8, 0x13, 0x00, 0xdc, 0x90, 0x31, 0xa2,
			0xe0, 0xf8, 0x51, 0x2c, 0xb3, 0x5a, 0x75, 0x79,
			0xfd, 0x79, 0x57, 0x5c, 0xf2, 0x87, 0xc5, 0x95
	};

	uint8_t ciphertext[plaintext_size] = {0};

	// https://gchq.github.io/CyberChef/#recipe=RC4(%7B'option':'Hex','string':'ae6c3c41884d35df3ab5adf30f5b2d360938c658341886b0ba510b421e5ab405'%7D,'Hex','Hex')&input=M2FlMjgwZDBkNWNkNzBkOGUwZjgxMzAwZGM5MDMxYTJlMGY4NTEyY2IzNWE3NTc5ZmQ3OTU3NWNmMjg3YzU5NQ
	// 2280c9676c8f5c52aba8d42611f85e7ca961a2117d3cfc8236a6051bbfc5f179
	uint8_t known_ciphertext[] = {
			0x22, 0x80, 0xc9, 0x67, 0x6c, 0x8f, 0x5c, 0x52,
			0xab, 0xa8, 0xd4, 0x26, 0x11, 0xf8, 0x5e, 0x7c,
			0xa9, 0x61, 0xa2, 0x11, 0x7d, 0x3c, 0xfc, 0x82,
			0x36, 0xa6, 0x05, 0x1b, 0xbf, 0xc5, 0xf1, 0x79
	};


	rc4(
		key_size,
		plaintext_size,
		key,
		plaintext,
		ciphertext);


	printf("[*] KEY:         0x");
	for (i = 0; i < key_size; i++) {
		printf("%02x", static_cast<int>(key[i]));
	}
	printf("\n");
	printf("[*] Plaintext:   0x");
	for (i = 0; i < plaintext_size; i++) {
		printf("%02x", static_cast<int>(plaintext[i]));
	}
	printf("\n");

	// Ciphertext extraction and checking
	printf("[*] Ciphertext:  0x");
	for (i = 0; i < plaintext_size; i++) {
		printf("%02x", static_cast<int>(ciphertext[i]));
		if (ciphertext[i] != known_ciphertext[i])
			error += 1;
	}
	printf("\n");

	// Print Plaintext
	printf("[*] Known Ciph.: 0x");
	for (i = 0; i < plaintext_size; i++) {
		printf("%02x", static_cast<int>(known_ciphertext[i]));
	}
	printf("\n");

	// Print PASS / FAIL
	printf("---- ---- ---- ---- ---- ---- ---- ----\n");
	if (error == 0) {
		printf("[*] ... PASSED ...\n");
		printf("---- ---- ---- ---- ---- ---- ---- ----\n");
	}
	else {
		printf("[!] ... FAILED ...\n");
		printf("---- ---- ---- ---- ---- ---- ---- ----\n");
	}


	// Speed test
	printf("\n");
	printf("---- ---- ---- ---- ---- ---- ---- ----\n");
	printf("[*] ... SPEED TEST ...\n");
	// Reuse key
	const uint32_t plaintext_size_speed_test = 1024 * 1000 * 50; // 50 Megabyte
	uint8_t* plaintext_speed_test = (uint8_t*) malloc(plaintext_size_speed_test);
	memset(plaintext_speed_test, 'a', (size_t) plaintext_size_speed_test);
	uint8_t* ciphertext_test = (uint8_t*) malloc(plaintext_size_speed_test);
	std::chrono::steady_clock::time_point begin = std::chrono::steady_clock::now();
	rc4(
		key_size,
		plaintext_size_speed_test,
		key,
		plaintext_speed_test,
		ciphertext_test);
	std::chrono::steady_clock::time_point end = std::chrono::steady_clock::now();
	/*
	// For 50 MB --> 658b79745390f3ccd8242c9d0178a018add82ba8d0058adf9dfb3a2b02d188a3
	printf("[*] Ciphertext (last 32 byte):  0x");
	for (i = plaintext_size_speed_test-32; i < plaintext_size_speed_test; i++) {
		printf("%02x", static_cast<int>(ciphertext_test[i]));
	}
	printf("\n");
	*/
	free(plaintext_speed_test);
	free(ciphertext_test);
	float time_ms = std::chrono::duration_cast<std::chrono::milliseconds>(end - begin).count();
	printf("[*] Encrypted %d MB in %.2f seconds (%.2f MB/s)\n", (plaintext_size_speed_test/(1024 * 1000)), float(time_ms/1000), float((plaintext_size_speed_test / (1024 * 1000)) / float(time_ms/1000)));

	return 0;
}


void rc4(
	uint16_t key_size_in,
	uint32_t plaintext_size_in,
	uint8_t* key_in,
	uint8_t* plaintext_in,
	uint8_t* ciphertext_out) {

	// Variable Declaration
	uint8_t array_s[N] = { 0 };
	int i = 0;

	// Input Validation
	if (key_size_in == 0 || key_size_in > 32) {
		printf("[!] The key size is either zero or longer than 32 byte --> 256 bit (which is not allowed)!");
		return;
	}

	// KSA - Key Scheduling Algorithm
	ksa(array_s, key_in, key_size_in);

	// PRGA - Pseudo Random Generation Algorithm
	prga(array_s, plaintext_in, ciphertext_out, plaintext_size_in);
}


void swap(uint8_t* a, uint8_t* b) {
	uint8_t tmp = *a;
	*a = *b;
	*b = tmp;
}


int ksa(uint8_t* array_s, uint8_t* key, uint16_t key_size) {
	int j = 0;
	int i = 0;

	for (i = 0; i < N; i++)
		array_s[i] = i;

	for (i = 0; i < N; i++) {
		j = (j + array_s[i] + key[i % key_size]) % N;
		swap(&array_s[i], &array_s[j]);
	}
	return 0;
}


int prga(uint8_t* array_s, uint8_t* plaintext, uint8_t* ciphertext, uint32_t plaintext_size) {
	uint32_t i = 0;
	uint32_t j = 0;
	uint8_t keystream_byte = 0;

	for (uint32_t n = 0; n < plaintext_size; n++) {
		i = (i + 1) % N;
		j = (j + array_s[i]) % N;
		swap(&array_s[i], &array_s[j]);
		keystream_byte = array_s[(array_s[i] + array_s[j]) % N];
		ciphertext[n] = keystream_byte ^ plaintext[n];
	}
	return 0;
}
