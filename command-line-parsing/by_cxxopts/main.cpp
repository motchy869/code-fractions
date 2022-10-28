#include <cstdlib>
#include <filesystem>
#include <iostream>
#include "cxxopts.hpp"

int main(int argc, char** argv) {
    std::filesystem::path inputFilePath_ch1;
    std::filesystem::path inputFilePath_ch2;
    std::filesystem::path outputFilePath;

    /* command line argument handling */
    cxxopts::Options options("resolver", "Converter from BbInputHistory_1_0_0 struct file to HDF data file.");
    options.add_options()
        ("in1", "the path to ch1 data file", cxxopts::value<std::string>())
        ("in2", "the path to ch2 data file", cxxopts::value<std::string>())
        ("out", "the path to output file", cxxopts::value<std::string>())
        ("h,help", "resolver --in1 <path-to-ch1-data-file> --in2 <path-to-ch2-data-file> --out <path-to-output-file>")
    ;
    auto result = options.parse(argc, argv);
    if (result.count("help")) {
        std::cout << options.help() << std::endl;
        return EXIT_SUCCESS;
    }

    {
        bool isError = false;
        do {
            if (result.count("in1")) {
                inputFilePath_ch1 = result["in1"].as<std::string>();
            } else {
                std::cerr << "Error. option `in1` is not specified." << std::endl;
                isError = true;
                break;
            }
            if (result.count("in2")) {
                inputFilePath_ch2 = result["in2"].as<std::string>();
            } else {
                std::cerr << "Error. option `in2` is not specified." << std::endl;
                isError = true;
                break;
            }
            if (result.count("out")) {
                outputFilePath = result["out"].as<std::string>();
            } else {
                std::cerr << "Error. option `out` is not specified." << std::endl;
                isError = true;
                break;
            }
        } while (false);
        if (isError) {
            std::cout << options.help() << std::endl;
            return EXIT_FAILURE;
        }
    }

    /* Do some work. */

    return EXIT_SUCCESS;
}
