#pragma once

#include <array>
#include <string>
#include <regex>
#include "common.hpp"

/**
 * @brief Print usage.
 *
 * @param[in] argv the argv array.
 */
void printUsage(const char* const argv[]);

/**
 * @brief Parse command line arguments.
 *
 * @param[in] argc the number of the arguments
 * @param[in] argv the array of arguments
 * @param[out] targetFileName target file name
 * @param[out] fwVersion FW version
 * @retval true success
 * @retval false failure
 */
bool parseCmdLineArg(const int argc, const char* const argv[], std::string &targetFileName, FwVersion &fwVersion);
