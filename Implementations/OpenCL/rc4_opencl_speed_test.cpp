/*
 *	INITIAL SOURCE: https://github.com/gcielniak/OpenCL-Tutorials
 *	COMPILATION: g++ -lOpenCL -o rc4_opencl_speed_test rc4_opencl_speed_test.cpp
 */


#include <iostream>
#include <vector>
#include <chrono>
#include "Utils.h"


void print_help() {
	std::cerr << "[*] Application usage:" << std::endl;

	std::cerr << "  -p : select platform " << std::endl;
	std::cerr << "  -d : select device" << std::endl;
	std::cerr << "  -l : list all platforms and devices" << std::endl;
	std::cerr << "  -h : print this message" << std::endl;
}

int main(int argc, char **argv) {
	int i = 0;
	int error = 0;


	int platform_id = 0;
	int device_id = 0;

	for (i = 1; i < argc; i++)	{
		if ((strcmp(argv[i], "-p") == 0) && (i < (argc - 1))) { platform_id = atoi(argv[++i]); }
		else if ((strcmp(argv[i], "-d") == 0) && (i < (argc - 1))) { device_id = atoi(argv[++i]); }
		else if (strcmp(argv[i], "-l") == 0) { std::cout << ListPlatformsDevices() << std::endl; }
		else if (strcmp(argv[i], "-h") == 0) { print_help(); return 0; }
	}

	try {
		const uint16_t key_size = 32;
		const size_t key_size_bytes = key_size * sizeof(uint8_t);
		// KEY: ae6c3c41884d35df3ab5adf30f5b2d360938c658341886b0ba510b421e5ab405
		std::vector<uint8_t> key = {
				0xae, 0x6c, 0x3c, 0x41, 0x88, 0x4d, 0x35, 0xdf,
				0x3a, 0xb5, 0xad, 0xf3, 0x0f, 0x5b, 0x2d, 0x36,
				0x09, 0x38, 0xc6, 0x58, 0x34, 0x18, 0x86, 0xb0,
				0xba, 0x51, 0x0b, 0x42, 0x1e, 0x5a, 0xb4, 0x05
		};

		const uint32_t plaintext_size = 1024 * 1000 * 10; // 10 Megabyte
		const size_t plaintext_size_bytes = plaintext_size * sizeof(uint8_t);
		std::vector<uint8_t> plaintext(plaintext_size, 'a');

		std::vector<uint8_t> ciphertext(plaintext_size);

		// LAST 32 BYTE OF THE KNOWN CIPHERTEXT: 0d7e9b0d51a432b89e7438d498ac83a5236c521ecbec5a8af66182426a31566c
		std::vector<uint8_t> known_ciphertext = {
				0x0d, 0x7e, 0x9b, 0x0d, 0x51, 0xa4, 0x32, 0xb8,
				0x9e, 0x74, 0x38, 0xd4, 0x98, 0xac, 0x83, 0xa5,
				0x23, 0x6c, 0x52, 0x1e, 0xcb, 0xec, 0x5a, 0x8a,
				0xf6, 0x61, 0x82, 0x42, 0x6a, 0x31, 0x56, 0x6c
		};

		// START TIMER
		std::chrono::steady_clock::time_point begin = std::chrono::steady_clock::now();

		cl::Context context = GetContext(platform_id, device_id);
		std::cout << "[*] Runinng on " << GetPlatformName(platform_id) << ", " << GetDeviceName(platform_id, device_id) << std::endl;
		std::cout << "---- ---- ---- ---- ---- ---- ---- ----" << std::endl;
		cl::CommandQueue queue(context);
		cl::Program::Sources sources;
		AddSources(sources, "rc4_kernel.cl");
		cl::Program program(context, sources);

		try {
			program.build();
		}
		catch (const cl::Error& err) {
			std::cout << "[!] Build Status: " << program.getBuildInfo<CL_PROGRAM_BUILD_STATUS>(context.getInfo<CL_CONTEXT_DEVICES>()[0]) << std::endl;
			std::cout << "[!] Build Options:\t" << program.getBuildInfo<CL_PROGRAM_BUILD_OPTIONS>(context.getInfo<CL_CONTEXT_DEVICES>()[0]) << std::endl;
			std::cout << "[!] Build Log:\t " << program.getBuildInfo<CL_PROGRAM_BUILD_LOG>(context.getInfo<CL_CONTEXT_DEVICES>()[0]) << std::endl;
			throw err;
		}


		cl::Buffer buffer_key(context, CL_MEM_READ_WRITE, key_size_bytes);
		cl::Buffer buffer_plaintext(context, CL_MEM_READ_WRITE, plaintext_size_bytes);
		cl::Buffer buffer_ciphertext(context, CL_MEM_READ_WRITE, plaintext_size_bytes);

		queue.enqueueWriteBuffer(buffer_key, CL_FALSE, 0, key_size_bytes, &key[0]);
		queue.enqueueWriteBuffer(buffer_plaintext, CL_FALSE, 0, plaintext_size_bytes, &plaintext[0]);

		cl::Kernel kernel_rc4 = cl::Kernel(program, "rc4");
		kernel_rc4.setArg(0, buffer_key);
		kernel_rc4.setArg(1, sizeof(uint16_t), &key_size);
		kernel_rc4.setArg(2, buffer_plaintext);
		kernel_rc4.setArg(3, sizeof(uint32_t), &plaintext_size);
		kernel_rc4.setArg(4, buffer_ciphertext);

		queue.enqueueNDRangeKernel(kernel_rc4, cl::NullRange, cl::NDRange(1), cl::NullRange);

		queue.enqueueReadBuffer(buffer_ciphertext, CL_FALSE, 0, plaintext_size_bytes, &ciphertext[0]);
		queue.finish();

		// STOP TIMER
		std::chrono::steady_clock::time_point end = std::chrono::steady_clock::now();
		float time_ms = std::chrono::duration_cast<std::chrono::milliseconds>(end - begin).count();


		/*
		 *	RC4 Evaluation / Tests
		 */
		printf("[*] Comparing the last 32 byte against a known good ciphertext ...\n");
		printf("[*] KEY:         0x");
		for (i = 0; i < key_size; i++) {
			printf("%02x", static_cast<int>(key[i]));
		}
		printf("\n");

		printf("[*] Plaintext:   0x");
		for (i = plaintext_size - 32; i < plaintext_size; i++) {
			printf("%02x", static_cast<int>(plaintext[i]));
		}
		printf("\n");
		
		// Ciphertext extraction and checking
		printf("[*] Ciphertext:  0x");
		for (i = 0; i < 32; i++) {
			printf("%02x", static_cast<int>(ciphertext[plaintext_size - 32 + i]));
			if (ciphertext[plaintext_size - 32 + i] != known_ciphertext[i])
				error += 1;
		}
		printf("\n");

		// Print Plaintext
		printf("[*] Known Ciph.: 0x");
		for (i = 0; i < 32; i++) {
			printf("%02x", static_cast<int>(known_ciphertext[i]));
		}
		printf("\n");

		// Print PASS / FAIL
		std::cout << "---- ---- ---- ---- ---- ---- ---- ----" << std::endl;
		if (error == 0) {
			std::cout << "[*] ... PASSED ..."  << std::endl;
			std::cout << "---- ---- ---- ---- ---- ---- ---- ----" << std::endl;
		}
		else {
			std::cout << "[!] ... FAILED ..."  << std::endl;
			std::cout << "---- ---- ---- ---- ---- ---- ---- ----" << std::endl;
		}

		printf("[*] Encrypted %d MB in %.2f seconds (%.2f MB/s)\n", (plaintext_size_bytes/(1024 * 1000)), float(time_ms/1000), float((plaintext_size_bytes / (1024 * 1000)) / float(time_ms/1000)));

	}
	catch (cl::Error err) {
		std::cerr << "ERROR: " << err.what() << ", " << getErrorString(err.err()) << std::endl;
	}

	return 0;
}