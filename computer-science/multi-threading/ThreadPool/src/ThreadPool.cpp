#include "../include/ThreadPool.hpp"

static void thread_runExecutable(std::reference_wrapper<std::mutex> ref_threadsCreationMutex, ThreadInfo threadInfo, std::reference_wrapper<MultiThreadQueue<std::shared_ptr<Executable>>> ref_queue) {
    /* Wait until all the other threads be created, otherwise the constructor is blocked and cannot create other threads. */
    std::unique_lock<std::mutex> lock(ref_threadsCreationMutex.get());
    lock.unlock();
    std::this_thread::sleep_for(std::chrono::microseconds(100));

    MultiThreadQueue<std::shared_ptr<Executable>> &queue = ref_queue.get();
    std::shared_ptr<Executable> exe;
    while (queue.pop(exe)) {
        exe->run(threadInfo);
    }
}

ThreadPool::ThreadPool(unsigned int numThreads, unsigned int queueDepth) : m_numThreads(numThreads), m_threads(numThreads), m_queue(queueDepth) {
    std::lock_guard<std::mutex> lock(m_threadsMtx);
    for (unsigned int i=0; i<m_numThreads; ++i) {
        m_threads.emplace_back(thread_runExecutable, std::ref(m_threadsMtx), (ThreadInfo){.threadId=i}, std::ref(m_queue));
    }
}

void ThreadPool::join() {
    std::lock_guard<std::mutex> lock(m_threadsMtx);
    for (auto &th : m_threads) {
        if (th.joinable()) {th.join();}
    }
}
