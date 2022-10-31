/**
 * @file argumentParser.cpp
 * @brief command line argument parser example using `getopt`
 * @details For usage of `getopt`, see: https://www.mm2d.net/main/prog/c/getopt-03.html
 * @date 2021-11-30
 */

#include <cstdio>
#include <getopt.h>
#include "argumentParser.hpp"

void printUsage(const char* const argv[]) {
	printf("Usage: %s --file <target file name> --version <version>\n", argv[0]);
	printf("example: %s --file rprc.bin --version 0.2.3\n", argv[0]);
}

bool parseCmdLineArg(const int argc, const char* const argv[], std::string &targetFileName, FwVersion &fwVersion) {
	struct option longOpts[] = {
		{.name = "file",    .has_arg = required_argument, .flag = nullptr, .val = 'f'},
		{.name = "version", .has_arg = required_argument, .flag = nullptr, .val = 'v'},
		{.name = nullptr,   .has_arg = 0,                 .flag = nullptr, .val = 0}, // terminator
	};

	bool existsFileName = false;
	bool existsFwVersion = false;
	std::string fwVersionString;

	int opt = 0;
	int longIndex = 0;

	while ((opt = getopt_long_only(argc, const_cast<char **const>(argv), "fv:", longOpts, &longIndex)) != -1) {
		switch (opt) {
			case 'f':
				existsFileName = true;
				targetFileName = optarg;
				break;
			case 'v':
				existsFwVersion = true;
				fwVersionString = optarg;
				break;
			default:
				printUsage(argv);
				return false;
		}
	}

	if (!existsFileName) {
		fprintf(stderr, "Error, no target file name specified.\n");
		printUsage(argv);
		return false;
	}

	if (!existsFwVersion) {
		fprintf(stderr, "Error, no FW version specified.\n");
		printUsage(argv);
		return false;
	}

	/* parse FW version */
	{
		std::regex versionRegex("^([0-9A-F]).([0-9A-F]).([0-9A-F])$");
		std::smatch versionMatch;
		if (!std::regex_match(fwVersionString, versionMatch, versionRegex)) {
			fprintf(stderr, "Error, invalid FW version.\n");
			printUsage(argv);
			return false;
		}

		if (versionMatch.size() != 4) {
			fprintf(stderr, "Error, invalid FW version.\n");
			fprintf(stderr, "hint: major, minor, patch version must be in the set {0,1,...E,F}\n");
			printUsage(argv);
			return false;
		}

		std::array<uint8_t *, 3> verRef = {&fwVersion.major, &fwVersion.minor, &fwVersion.patch};
		for (size_t i=0; i<verRef.size(); ++i) {
			const char v = versionMatch[1+i].str().c_str()[0];
			*verRef.at(i) = (v <= '9') ? v - '0' : 10 + v - 'A';
		}
	}

	return true;
}
