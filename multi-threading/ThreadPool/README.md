# Producer-Consumer model multi-thread library for C++

A thread pool library and example code for C++.

## 1. Build & Run example

### 1.1. On Unix-like OS

```sh
./doDebugBuild.sh
./build/demo/main_threadPool
```

### 1.2. On Windows

```bat
./doDebugBuild.bat
./build/demo/main_threadPool.exe
```

## 2. Core files

|file|description|
|:---|:---|
|include/MultiThreadQueue.hpp|thread-safe queue (header only library)|
|include/ThreadPool.hpp|header fo ThreadPool.cpp|
|src/ThreadPool.cpp|thread pool library|
|demo/main_threadPool.cpp|example to show the usage of thread pool library|

## 3. Brief usage

```C++
#include <array>
#include <cstdio>
#include "../include/ThreadPool.hpp"

/**
 * @brief Parameter for a task.
 * You can customize this class to design your parameter.
 */
struct TaskParam {
    int a;
    float b;
};

/**
 * @brief A concrete class which represents a task.
 * You can customize this class to design your task.
 */
class Task : public Executable {
    private:
        const int m_taskId;
        const TaskParam m_taskParam;
        std::array<char, 1024> m_descriptionString;

    public:
        Task(int taskId, TaskParam taskParam) : m_taskId(taskId), m_taskParam(taskParam) {
            /* Prepare the task description string. */
            snprintf(m_descriptionString.data(), m_descriptionString.size()-1, "taskId=%d, a=%d, b=%g", m_taskId, taskParam.a, taskParam.b);
        }

        const char *getDescriptionString() override {return m_descriptionString.data();}

        void run() override {
            /* Let other worker threads in thread pool take tasks from the queue. */
            constexpr int gapTime_us = 100; // Good value depends on situations
            std::this_thread::sleep_for(std::chrono::microseconds(gapTime_us));

            /* Do some heavy work */
        }
};

/**
 * @brief a thread which produces tasks and pushes them to a thread pool
 */
void thread_produceTasks(std::reference_wrapper<ThreadPool> ref_threadPool) {
    const int numTasks = 10;
    ThreadPool &threadPool = ref_threadPool.get();

    /* Create tasks and pass them to worker threads. */
    for (int i=0; i<numTasks; ++i) {
        std::shared_ptr<Executable> task = std::make_shared<Task>(i, (TaskParam){.a = i, .b = 10.0f + i});
        threadPool.pushExecutable(task);
    }

    threadPool.closeInlet(); // Close thread pool inlet to notify the worker threads that no more tasks will come.
}

int main() {
    const int numWorkerThreads = 3;
    const int queueDepth = 5;

    /* Create a thread pool. */
    ThreadPool threadPool(numWorkerThreads, queueDepth);

    /* Create a task producer thread. */
    std::thread(thread_produceTasks, std::ref(threadPool));

    /* Wait for the task producer to shut down. */
    th_produceTasks.join();

    /* Wait for all the worker threads shut down. */
    threadPool.join();

    return EXIT_SUCCESS;
}
```

Here is an detail example: `demo/main_threadPool.cpp`
