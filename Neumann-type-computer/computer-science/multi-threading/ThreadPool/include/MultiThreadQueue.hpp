/**
 * @file MultiThreadQueue.hpp
 * @author motchy (motchy869@gmail.com)
 * @brief thread-safe queue inspired by [条件変数 Step-by-Step入門](https://yohhoy.hatenablog.jp/entry/2014/09/23/193617)
 * @version 0.0.1
 * @date 2021-07-28
 * @copyright Copyright (c) 2021 motchy
 * https://motchy869.com/wordpress/
 * Released under the MIT license
 */

#ifndef __MULTI_THREAD_QUEUE__
#define __MULTI_THREAD_QUEUE__

#include <cassert>
#include <condition_variable>
#include <mutex>
#include <queue>

/**
 * @brief thread-safe queue
 *
 * @tparam T_elem the data type of elements
 */
template <typename T_elem>
class MultiThreadQueue {
    private:
        const size_t m_capacity;
        std::queue<T_elem> m_queue;
        std::mutex m_mtx;
        bool m_isInletClosed = false;
        std::condition_variable m_cv_notFull;
        std::condition_variable m_cv_notEmpty;

    public:
        /**
         * @brief Construct a new MultiThreadQueue object
         *
         * @param[in] capacity The max number of the elements which can be held in the queue, must be 1 or greater.
         */
        MultiThreadQueue(size_t capacity) : m_capacity(capacity) {
            assert(capacity > 0);
        }

        /**
         * @brief Get the capacity of the queue
         *
         * @return capacity
         */
        size_t capacity() const {
            return m_capacity;
        }

        /**
         * @brief Check if the inlet is closed
         *
         * @retval true the inlet is closed
         * @retval false the inlet is open
         */
        bool isInletClosed() {
            std::lock_guard<std::mutex> lock(m_mtx);
            return m_isInletClosed;
        }

        /**
         * @brief Push an element to the queue. If the queue is full, the caller thread is blocked until the queue is not-full or is closed.
         *
         * @param[in] elem the data to be pushed into the queue
         * @retval true The data was successfully pushed into the queue.
         * @retval false The queue was already closed, or became closed during waiting for the queue to be not-full.
         */
        bool push(T_elem elem) {
            std::unique_lock<std::mutex> lock(m_mtx);
            m_cv_notFull.wait(lock, [this]{
                return (m_queue.size() < m_capacity) || m_isInletClosed;
            });
            if (m_isInletClosed) {
                return false;
            }
            const bool isNotifNeeded = m_queue.empty();
            m_queue.push(elem);
            if (isNotifNeeded) {
                m_cv_notEmpty.notify_one();
            }
            return true;
        }

        /**
         * @brief Pop an element from the queue. If the queue is empty, the caller thread is blocked until the queue is not-empty or is closed.
         *
         * @param[out] elem the reference to the data which the popped data to be stored
         * @retval true The data was successfully popped from the queue.
         * @retval false The queue was already closed, or became closed during waiting for the queue to be not-empty.
         */
        bool pop(T_elem &elem) {
            std::unique_lock<std::mutex> lock(m_mtx);
            m_cv_notEmpty.wait(lock, [this]{
                return !m_queue.empty() || m_isInletClosed;
            });
            if (m_queue.empty() && m_isInletClosed) {
                return false;
            }
            const bool isNotifNeeded = (m_queue.size() == m_capacity);
            elem = m_queue.front();
            m_queue.pop();
            if (isNotifNeeded) {
                m_cv_notFull.notify_one();
            }
            return true;
        }

        /**
         * @brief Pop all elements from the queue.
         * @details One typically uses this method to abort pending tasks under producer-consumer thread model; calls `closeInlet` method, then calls `popAll` method.
         */
        void popAll() {
            std::lock_guard<std::mutex> lock(m_mtx);
            while (!m_queue.empty()) {m_queue.pop();}
        }

        /**
         * @brief Close the queue inlet.
         * @details After the queue inlet is closed:
         * @par 1. Following or currently-blocked `push` callings return with `false`.
         * @par 2. Following or currently-blocked `pop` callings return with `true` as far as there is at least one element in the queue, otherwise return with `false`.
         */
        void closeInlet() {
            std::lock_guard<std::mutex> lock(m_mtx);
            m_isInletClosed = true;
            m_cv_notFull.notify_all();
            m_cv_notEmpty.notify_all();
        }
};

#endif // __MULTI_THREAD_QUEUE__
