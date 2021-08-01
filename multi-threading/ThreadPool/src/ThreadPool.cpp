#include "../include/ThreadPool.hpp"

static void thread_runExecutable(ThreadInfo threadInfo, std::reference_wrapper<MultiThreadQueue<std::shared_ptr<Executable>>> ref_queue) {
    std::this_thread::yield();
    std::this_thread::sleep_for(std::chrono::microseconds(1)); // Let the constructor create other threads
    MultiThreadQueue<std::shared_ptr<Executable>> &queue = ref_queue.get();
    std::shared_ptr<Executable> exe;
    while (queue.pop(exe)) {
        exe->run(threadInfo);
    }
}

ThreadPool::ThreadPool(unsigned int numThreads, unsigned int queueDepth) : m_numThreads(numThreads), m_threads(numThreads), m_queue(queueDepth) {
    for (unsigned int i=0; i<m_numThreads; ++i) {
        m_threads.push_back(std::thread(thread_runExecutable, (ThreadInfo){.threadId=i}, std::ref(m_queue)));
    }
}

void ThreadPool::join() {
    std::lock_guard<std::mutex> lock(m_threadsMtx);
    for (auto &th : m_threads) {
        if (th.joinable()) {th.join();}
    }
}
