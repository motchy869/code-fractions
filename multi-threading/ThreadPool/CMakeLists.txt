cmake_minimum_required(VERSION 3.18 FATAL_ERROR)

if (UNIX)
    set(CMAKE_CXX_COMPILER "clang++")
elseif (WIN32)
    set(CMAKE_CXX_COMPILER "g++")
endif ()
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_FLAGS "-Wall -Wfatal-errors -pthread")
set(CMAKE_CXX_FLAGS_DEBUG "-O0 -g")
set(CMAKE_CXX_FLAGS_RELEASE "-O3 -DNDEBUG")

# Set the project name and language.
project(ProducerConsumerModel CXX)

add_subdirectory(src)
add_subdirectory(demo)
