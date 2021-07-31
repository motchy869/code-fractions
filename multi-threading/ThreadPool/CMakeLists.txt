cmake_minimum_required(VERSION 3.10 FATAL_ERROR)

set(CMAKE_CXX_COMPILER "clang++")
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_FLAGS "-Wall -pthread")
set(CMAKE_CXX_FLAGS_DEBUG "-O0 -g")
set(CMAKE_CXX_FLAGS_RELEASE "-O3 -DNDEBUG")

# Set the project name and language.
project(ProducerConsumerModel CXX)

add_subdirectory(src)
add_subdirectory(demo)
