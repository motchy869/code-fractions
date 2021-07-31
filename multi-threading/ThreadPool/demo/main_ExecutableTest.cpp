#include <array>
#include <chrono>
#include <cstdlib>
#include <iostream>
#include <memory>
#include <thread>
#include "../include/MultiThreadQueue.hpp"
#include "../include/ThreadPool.hpp"

static std::mutex gMtx_stdCout; // mutex for std::cout
void printToStdCout(const char *msg) {
    std::lock_guard<std::mutex> lock(gMtx_stdCout);
    std::cout << msg;
}

struct Result {
    unsigned int taskId;
    float alpha;
    float beta;
    float gamma;
};

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
            std::array<char, 1024> msgBuf;
            snprintf(msgBuf.data(), msgBuf.size()-1, "  [taskId=%d] Started. alpha=%g, beta=%g\n", m_taskId, m_alpha, m_beta);
            printToStdCout(msgBuf.data());

            std::this_thread::sleep_for(std::chrono::milliseconds(m_waitTime_ms));
            const float gamma = m_alpha*m_beta;
            snprintf(msgBuf.data(), msgBuf.size()-1, "  [taskId=%d] Calculation done. gamma=%g\n", m_taskId, gamma);
            printToStdCout(msgBuf.data());

            const Result result = {.taskId = m_taskId, .alpha = m_alpha, .beta = m_beta, .gamma = gamma};
            m_mtq_output.push(result);
            snprintf(msgBuf.data(), msgBuf.size()-1, "  [taskId=%d] Pushed result. Task is done.\n", m_taskId);
            printToStdCout(msgBuf.data());
        }
};

void thread_runExecutable(const unsigned int threadId, std::reference_wrapper<MultiThreadQueue<std::shared_ptr<Executable>>> ref_mtq_input) {
    MultiThreadQueue<std::shared_ptr<Executable>> &mtq_input = ref_mtq_input.get();
    std::array<char, 1024> msgBuf;

    snprintf(msgBuf.data(), msgBuf.size()-1, "[thread_runExecutable, threadId=%d] Started.\n", threadId);
    printToStdCout(msgBuf.data());

    std::shared_ptr<Executable> exe;
    while (mtq_input.pop(exe)) {
        snprintf(msgBuf.data(), msgBuf.size()-1, "[thread_runExecutable, threadId=%d] Got Executable object: %s\n", threadId, exe->getDescriptionString());
        printToStdCout(msgBuf.data());
        exe->run();
    }

    snprintf(msgBuf.data(), msgBuf.size()-1, "[thread_runExecutable, threadId=%d] The queue inlet is closed. Shutting down.\n", threadId);
    printToStdCout(msgBuf.data());
}

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

int main() {
    std::array<char, 1024> msgBuf;
    constexpr unsigned int numTasks = 10;
    constexpr size_t queueDepth = 4;
    MultiThreadQueue<std::shared_ptr<Executable>> mtq_exec(queueDepth);
    MultiThreadQueue<Result> mtq_result(queueDepth);

    std::thread th0(thread_runExecutable, 0, std::ref(mtq_exec));
    std::thread th1(thread_runExecutable, 1, std::ref(mtq_exec));
    std::thread th2(thread_runExecutable, 2, std::ref(mtq_exec));
    std::thread th3(thread_collectResult, 3, std::ref(mtq_result));

    for (size_t i=0; i<numTasks; ++i) {
        const unsigned int waitTime_ms = 1000*(1 + i%3);
        const float alpha = static_cast<float>(i);
        const float beta = static_cast<float>(10+i);
        std::shared_ptr<Executable> task = std::make_shared<Task>(i, mtq_result, waitTime_ms, alpha, beta);
        mtq_exec.push(task);
        snprintf(msgBuf.data(), msgBuf.size()-1, "[main] Pushed task, i=%zu\n", i);
        printToStdCout(msgBuf.data());
    }

    mtq_exec.closeInlet();
    printToStdCout("[main] Closed mtq_exec inlet.\n");

    th0.join(); th1.join(); th2.join();
    mtq_result.closeInlet();
    printToStdCout("[main] Closed mtq_result inlet.\n");

    th3.join();
    printToStdCout("[main] Joined all sub threads.\n");

    return EXIT_SUCCESS;
}
