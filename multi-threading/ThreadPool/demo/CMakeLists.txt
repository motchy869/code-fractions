cmake_minimum_required(VERSION 3.10 FATAL_ERROR)

set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR})

add_executable(main_queueTest ${CMAKE_CURRENT_SOURCE_DIR}/main_queueTest.cpp)
target_link_libraries(main_queueTest MultiThreadQueue)

add_executable(main_executableTest ${CMAKE_CURRENT_SOURCE_DIR}/main_executableTest.cpp)
target_link_libraries(main_executableTest MultiThreadQueue)

add_executable(main_threadPool ${CMAKE_CURRENT_SOURCE_DIR}/main_threadPool.cpp)
target_link_libraries(main_threadPool ThreadPool)
