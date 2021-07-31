#include <array>
#include <cstdlib>
#include <iostream>
#include "../include/ThreadPool.hpp"


static std::mutex gMtx_stdCout; // mutex for std::cout

/**
 * @brief Write string into std::cout.
 * All the concurrent threads MUST use this method to avoid message interleaving.
 *
 * @param[in] msg the string to be written into std::cout
 */
void printToStdCout(const char *msg) {
    std::lock_guard<std::mutex> lock(gMtx_stdCout);
    std::cout << msg;
}

/**
 * @brief a struct to hold the result of a task
 */
struct Result {
    unsigned int taskId;
    float alpha;
    float beta;
    float gamma;
};

/**
 * @brief a concrete class which represents a task
 */
class Task: public Executable {
    private:
        const unsigned int m_taskId;
        std::array<char, 1024> m_descriptionString;
        MultiThreadQueue<Result> &m_mtq_output;
        const unsigned int m_waitTime_ms;
        const float m_alpha, m_beta;

    public:
        Task(unsigned int taskId, MultiThreadQueue<Result> &mtq_output, unsigned int waitTime_ms, float alpha, float beta) : m_taskId(taskId), m_mtq_output(mtq_output), m_waitTime_ms(waitTime_ms), m_alpha(alpha), m_beta(beta) {
            snprintf(m_descriptionString.data(), m_descriptionString.size()-1, "taskId=%d", m_taskId);
        }

        const char *getDescriptionString() override {return m_descriptionString.data();}

        void run() override {
            std::this_thread::sleep_for(std::chrono::microseconds(100)); // Let other worker threads in thread pool take tasks from the queue.

            std::array<char, 1024> msgBuf;
            snprintf(msgBuf.data(), msgBuf.size()-1, "  [taskId=%d] Started. alpha=%g, beta=%g\n", m_taskId, m_alpha, m_beta);
            printToStdCout(msgBuf.data());

            std::this_thread::sleep_for(std::chrono::milliseconds(m_waitTime_ms));
            const float gamma = m_alpha*m_beta;
            snprintf(msgBuf.data(), msgBuf.size()-1, "  [taskId=%d] Calculation done. gamma=%g\n", m_taskId, gamma);
            printToStdCout(msgBuf.data());

            const Result result = {.taskId = m_taskId, .alpha = m_alpha, .beta = m_beta, .gamma = gamma};
            snprintf(msgBuf.data(), msgBuf.size()-1, "  [taskId=%d] Pushing result. Task is done.\n", m_taskId);
            const bool pushResult = m_mtq_output.push(result);
            if (!pushResult) {
                snprintf(msgBuf.data(), msgBuf.size()-1, "  [taskId=%d] Failed to push result.\n", m_taskId);
                printToStdCout(msgBuf.data());
            }
        }
};

/**
 * @brief a thread which accepts all the results from the worker threads in the thread pool
 *
 * @param[in] threadId arbitrary unsigned integer to represent this thread's id
 * @param[in] ref_mtq_input a std::reference_wrapper object holding a reference to a queue which the worker threads pushes the results
 */
void thread_collectResult(const unsigned int threadId, std::reference_wrapper<MultiThreadQueue<Result>> ref_mtq_input) {
    MultiThreadQueue<Result> &mtq_input = ref_mtq_input.get();
    std::array<char, 1024> msgBuf;

    Result result;
    while (mtq_input.pop(result)) {
        snprintf(msgBuf.data(), msgBuf.size()-1, "[thread_collectResult, threadId=%d] Got data: taskId=%d, alpha=%g, beta=%g, gamma=%g\n", threadId, result.taskId, result.alpha, result.beta, result.gamma);
        printToStdCout(msgBuf.data());
    }

    snprintf(msgBuf.data(), msgBuf.size()-1, "[thread_collectResult, threadId=%d] The queue inlet is closed. Shutting down.\n", threadId);
    printToStdCout(msgBuf.data());
}

/**
 * @brief a thread which produces tasks and pushes them to a thread pool
 *
 * @param[in] numTasks the number of the tasks
 * @param[in] ref_threadPool a std::reference_wrapper object holding a reference to a thread pool
 * @param[in] ref_mtq_result a std::reference_wrapper object holding a reference to a queue to push the results of the tasks
 */
void thread_produceTasks(unsigned int numTasks, std::reference_wrapper<ThreadPool> ref_threadPool, std::reference_wrapper<MultiThreadQueue<Result>> ref_mtq_result) {
    std::array<char, 1024> msgBuf;
    ThreadPool &threadPool = ref_threadPool.get();
    MultiThreadQueue<Result> &mtq_result = ref_mtq_result.get();

    for (size_t i=0; i<numTasks; ++i) {
        const unsigned int waitTime_ms = 1000*(1 + i%3);
        const float alpha = static_cast<float>(i);
        const float beta = static_cast<float>(10+i);
        std::shared_ptr<Executable> task = std::make_shared<Task>(i, mtq_result, waitTime_ms, alpha, beta);
        threadPool.pushExecutable(task);
        snprintf(msgBuf.data(), msgBuf.size()-1, "[%s] Pushed task, i=%zu\n", __func__, i);
        printToStdCout(msgBuf.data());
    }

    threadPool.closeInlet();
    snprintf(msgBuf.data(), msgBuf.size()-1, "[%s] Closed thread pool inlet.\n[%s] Shutting down.\n", __func__, __func__);
    printToStdCout(msgBuf.data());
}

int main() {
    constexpr unsigned int numTasks = 10;
    constexpr unsigned int numThreads = 3;
    constexpr size_t queueDepth = 4;

    /* Create a result collector. */
    MultiThreadQueue<Result> mtq_result(queueDepth);
    std::thread th_collectResult(thread_collectResult, 0, std::ref(mtq_result));

    /* Create worker threads. */
    ThreadPool threadPool(numThreads, queueDepth);

    /* Create a task producer thread. */
    std::thread th_produceTasks(thread_produceTasks, numTasks, std::ref(threadPool), std::ref(mtq_result));

    /* Wait for the task producer to shut down. */
    th_produceTasks.join();
    printToStdCout("[main] Detected that the task producer thread shut down.\n");

    /* Wait for all the worker threads to shut down. */
    threadPool.join();
    printToStdCout("[main] Detected that all the worker threads shut down.\n");

    /* Close the result queue inlet. */
    mtq_result.closeInlet();
    printToStdCout("[main] Closed result queue inlet.\n");

    /* Wait for the result collector thread. */
    th_collectResult.join();
    printToStdCout("[main] Joined all sub threads.\n[main] Shutting down.\n");

    return EXIT_SUCCESS;
}
