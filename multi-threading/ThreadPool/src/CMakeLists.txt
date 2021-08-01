cmake_minimum_required(VERSION 3.18 FATAL_ERROR)

add_library(ThreadPool ThreadPool.cpp)
target_include_directories(ThreadPool PUBLIC ${PROJECT_SOURCE_DIR}/include)

add_library(MultiThreadQueue INTERFACE)
target_include_directories(MultiThreadQueue INTERFACE ${PROJECT_SOURCE_DIR}/include)
