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

#ifndef __HEADER_H__
#define __HEADER_H__

#include <stdint.h>
#include <stdio.h>
#include <ap_int.h>
#include <hls_stream.h>

#define N 256   // 2^8

using namespace std;
using namespace hls;

void rc4(
	  uint16_t key_size_in,
	  uint32_t plaintext_size_in,
	  stream<uint8_t> &key_in,
      stream<uint8_t> &plaintext_in,
      stream<uint8_t> &ciphertext_out
      );

void swap(uint8_t *a, uint8_t *b);
int ksa(uint8_t *S, uint8_t *key, uint16_t key_size);
int prga(uint8_t *S, stream<uint8_t> &plaintext, stream<uint8_t> &ciphertext, uint32_t plaintext_size);


#endif
