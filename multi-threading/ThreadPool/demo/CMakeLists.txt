cmake_minimum_required(VERSION 3.10 FATAL_ERROR)

add_executable(main_queueTest.out ${CMAKE_CURRENT_SOURCE_DIR}/main_queueTest.cpp)
target_link_libraries(main_queueTest.out MultiThreadQueue)

add_executable(main_executableTest.out ${CMAKE_CURRENT_SOURCE_DIR}/main_executableTest.cpp)
target_link_libraries(main_executableTest.out MultiThreadQueue)

add_executable(main_threadPool.out ${CMAKE_CURRENT_SOURCE_DIR}/main_threadPool.cpp)
target_link_libraries(main_threadPool.out ThreadPool)
