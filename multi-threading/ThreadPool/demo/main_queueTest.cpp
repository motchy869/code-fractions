#include <array>
#include <chrono>
#include <cstdlib>
#include <iostream>
#include <mutex>
#include <thread>
#include "MultiThreadQueue.hpp"

struct Param {
    int a;
    float b;
};

static std::mutex gMtx_stdCout; // mutex for std::cout

void printToStdCout(const char *msg) {
    std::lock_guard<std::mutex> lock(gMtx_stdCout);
    std::cout << msg;
}

void printToStdCout(const std::string &msg) {
    std::lock_guard<std::mutex> lock(gMtx_stdCout);
    std::cout << msg;
}

void consumerThread(const unsigned int threadId, std::reference_wrapper<MultiThreadQueue<Param>> ref_mtq) {
    MultiThreadQueue<Param> &mtq = ref_mtq.get();
    std::array<char, 1024> msgBuf;

    snprintf(msgBuf.data(), msgBuf.size()-1, "[id=%x] Started.\n", threadId);
    printToStdCout(msgBuf.data());

    Param param;
    while (mtq.pop(param)) {
        snprintf(msgBuf.data(), msgBuf.size()-1, "[id=%x] Got data: a=%d, b=%g\n", threadId, param.a, param.b);
        printToStdCout(msgBuf.data());
        std::this_thread::sleep_for(std::chrono::seconds(1));
    }

    snprintf(msgBuf.data(), msgBuf.size()-1, "[id=%x] The queue inlet is closed. Shutting down.\n", threadId);
    printToStdCout(msgBuf.data());
}

int main() {
    std::array<char, 1024> msgBuf;
    MultiThreadQueue<Param> mtq(5);

    std::thread th0(consumerThread, 0, std::ref(mtq));

    std::this_thread::sleep_for(std::chrono::milliseconds(300));
    std::thread th1(consumerThread, 1, std::ref(mtq));

    std::this_thread::sleep_for(std::chrono::milliseconds(700));
    std::thread th2(consumerThread, 2, std::ref(mtq));

    for (size_t i=0; i<10; ++i) {
        const Param param = {.a = static_cast<int>(i), .b = 10.0f+static_cast<int>(i)};
        mtq.push(param);
        snprintf(msgBuf.data(), msgBuf.size()-1, "[main] Pushed param, i=%llu\n", i);
        printToStdCout(msgBuf.data());
    }

    mtq.closeInlet();
    printToStdCout("[main] Closed queue inlet.\n");

    th0.join();
    th1.join();
    th2.join();
    printToStdCout("[main] Joined all sub threads.\n");

    return EXIT_SUCCESS;
}
