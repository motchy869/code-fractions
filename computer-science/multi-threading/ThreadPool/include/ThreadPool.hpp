/**
 * @file ThreadPool.hpp
 * @author motchy (motchy869@gmail.com)
 * @brief thread pool
 * @version 0.1.0
 * @date 2021-07-29
 * @copyright Copyright (c) 2021 motchy
 * https://motchy869.com/wordpress/
 * Released under the MIT license
 */

#ifndef __THREAD_POOL__
#define __THREAD_POOL__

#include <memory>
#include <thread>
#include <vector>
#include "MultiThreadQueue.hpp"

/**
 * @brief struct for hold information of a worker thread.
 */
struct ThreadInfo {
    const unsigned int threadId; // Worker-unique non-negative integer starts with 0. If the thread pool has N worker threads, 0 <= threadId <= N-1.
};

/**
 * @brief interface class for handling task as object
 * @details A `ThreadPool` can accept any class inheriting `Executable` class, so it is possible to push various type tasks into a single thread pool.
 */
class Executable {
    public:
        /**
         * @brief Get the description string about this object
         *
         * @return description string
         */
        virtual const char *getDescriptionString() = 0;

        /**
         * @brief Run task in current thread
         */
        virtual void run(ThreadInfo threadInfo) = 0;

        /**
         * @brief Destroy the Executable object
         */
        virtual ~Executable() {}
};

class ThreadPool {
    private:
        const unsigned int m_numThreads;
        std::vector<std::thread> m_threads;
        std::mutex m_threadsMtx;
        MultiThreadQueue<std::shared_ptr<Executable>> m_queue;

    public:
        /**
         * @brief Construct a new ThreadPool object
         *
         * @param[in] numThreads the number of the threads to be created
         * @param[in] queueDepth the depth of the queue for sending Executable object to pooled threads
         */
        ThreadPool(unsigned int numThreads, unsigned int queueDepth);

        /**
         * @brief Get the number of the pooled threads
         *
         * @return the number of the pooled threads
         */
        size_t numThreads() const {return m_numThreads;}

        /**
         * @brief Push a new Executable object to the queue.
         * @details If the queue is full, the caller thread is blocked until the queue is not-full or is closed.
         *
         * @param[in] ptr_exe std::shared_ptr of an Executable object
         * @retval true The object was successfully pushed into the queue.
         * @retval false The queue was already closed, or became closed during waiting for the queue to be not-full.
         */
        bool pushExecutable(std::shared_ptr<Executable> ptr_exe) {return m_queue.push(ptr_exe);}

        /**
         * @brief Pops all Executable objects from the queue.
         */
        void popAllExecutables() {m_queue.popAll();}

        /**
         * @brief Close the queue inlet. No more Executable objects can be pushed after this operation.
         * @details After the queue inlet is closed:
         * @par 1. following or currently-blocked `pushExecutable` callings return with `false`.
         * @par 2. After the queue becomes empty, each pooled thread waiting for a new Executable object shuts down; i.e. all the pooled threads eventually shut down.
         */
        void closeInlet() {m_queue.closeInlet();}

        /**
         * @brief Wait until all the pooled threads shut down.
         * @details One typically calls `pushExecutable` method repeatedly until all the tasks are pushed, then calls `closeInlet` method, finally calls `join` method.
         */
        void join();
};

#endif // __THREAD_POOL__
