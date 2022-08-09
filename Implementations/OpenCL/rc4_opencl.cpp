/*
 *	INITIAL SOURCE: https://github.com/gcielniak/OpenCL-Tutorials
 *	COMPILATION (linux): g++ -o rc4_opencl rc4_opencl.cpp -lOpenCL
 *	COMPILATION (macos): g++ -o rc4_opencl rc4_opencl.cpp -std=c++11 -framework OpenCl
 */


#include <iostream>
#include <vector>
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

		const uint32_t plaintext_size = 32;
		const size_t plaintext_size_bytes = plaintext_size * sizeof(uint8_t);
		// PLAINTEXT: 3ae280d0d5cd70d8e0f81300dc9031a2e0f8512cb35a7579fd79575cf287c595
		std::vector<uint8_t> plaintext = {
				0x3a, 0xe2, 0x80, 0xd0, 0xd5, 0xcd, 0x70, 0xd8,
				0xe0, 0xf8, 0x13, 0x00, 0xdc, 0x90, 0x31, 0xa2,
				0xe0, 0xf8, 0x51, 0x2c, 0xb3, 0x5a, 0x75, 0x79,
				0xfd, 0x79, 0x57, 0x5c, 0xf2, 0x87, 0xc5, 0x95
		};

		std::vector<uint8_t> ciphertext(plaintext_size);

		// https://gchq.github.io/CyberChef/#recipe=RC4(%7B'option':'Hex','string':'ae6c3c41884d35df3ab5adf30f5b2d360938c658341886b0ba510b421e5ab405'%7D,'Hex','Hex')&input=M2FlMjgwZDBkNWNkNzBkOGUwZjgxMzAwZGM5MDMxYTJlMGY4NTEyY2IzNWE3NTc5ZmQ3OTU3NWNmMjg3YzU5NQ
		// KNOWN CIPHERTEXT: 2280c9676c8f5c52aba8d42611f85e7ca961a2117d3cfc8236a6051bbfc5f179
		std::vector<uint8_t> known_ciphertext = {
				0x22, 0x80, 0xc9, 0x67, 0x6c, 0x8f, 0x5c, 0x52,
				0xab, 0xa8, 0xd4, 0x26, 0x11, 0xf8, 0x5e, 0x7c,
				0xa9, 0x61, 0xa2, 0x11, 0x7d, 0x3c, 0xfc, 0x82,
				0x36, 0xa6, 0x05, 0x1b, 0xbf, 0xc5, 0xf1, 0x79
		};

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

		/*
		 *	RC4 Evaluation / Tests
		 */
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
		std::cout << "---- ---- ---- ---- ---- ---- ---- ----" << std::endl;
		if (error == 0) {
			std::cout << "[*] ... PASSED ..."  << std::endl;
			std::cout << "---- ---- ---- ---- ---- ---- ---- ----" << std::endl;
		}
		else {
			std::cout << "[!] ... FAILED ..."  << std::endl;
			std::cout << "---- ---- ---- ---- ---- ---- ---- ----" << std::endl;
		}
	}
	catch (cl::Error err) {
		std::cerr << "ERROR: " << err.what() << ", " << getErrorString(err.err()) << std::endl;
	}

	return 0;
}