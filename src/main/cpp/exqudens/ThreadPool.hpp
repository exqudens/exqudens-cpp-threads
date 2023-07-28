#pragma once

#include <string>
#include <vector>
#include <queue>
#include <memory>
#include <thread>
#include <mutex>
#include <condition_variable>
#include <future>
#include <functional>
#include <stdexcept>
#include <type_traits>

#include "exqudens/ThreadsExport.hpp"

namespace exqudens {

  /*!

    @brief Class ThreadPool test doc.

  */
  class EXQUDENS_THREADS_EXPORT ThreadPool {

    private:

      size_t queueSize;
      std::queue<std::function<void()>> queue;
      std::vector<std::thread> threads;
      std::mutex mutex;
      std::condition_variable condition;
      bool stop;

    public:

      EXQUDENS_THREADS_FUNCTION_ATTRIBUTES
      ThreadPool();

      EXQUDENS_THREADS_FUNCTION_ATTRIBUTES
      explicit ThreadPool(size_t queueSize);

      EXQUDENS_THREADS_FUNCTION_ATTRIBUTES
      ThreadPool(size_t queueSize, size_t size);

      /*!

        @brief Method ThreadPool::submit test doc.

      */
      template<class F, class... ARGS>
      EXQUDENS_THREADS_FUNCTION_ATTRIBUTES
      auto submit(F&& f, ARGS&&... args) -> std::future<typename std::invoke_result<F, ARGS...>::type>;

      ~ThreadPool();
  };

  template<class F, class... ARGS>
  auto ThreadPool::submit(F&& f, ARGS&&... args) -> std::future<typename std::invoke_result<F, ARGS...>::type> {
    try {
      if (queue.size() >= queueSize) {
        throw std::runtime_error(std::string(__FUNCTION__) + "(" + __FILE__ + ":" + std::to_string(__LINE__) + "): queue overflow");
      }
      using return_type = typename std::invoke_result<F, ARGS...>::type;
      auto task = std::make_shared<std::packaged_task<return_type()>>(std::bind(std::forward<F>(f), std::forward<ARGS>(args)...));
      std::future<return_type> res = task->get_future();
      {
        std::unique_lock<std::mutex> lock(mutex);
        if(stop) {
          throw std::runtime_error(std::string(__FUNCTION__) + "(" + __FILE__ + ":" + std::to_string(__LINE__) + "): submitted on stopped 'ThreadPool'");
        }
        queue.emplace([task] { (*task)(); });
      }
      condition.notify_one();
      return res;
    } catch (...) {
      std::throw_with_nested(std::runtime_error(std::string(__FUNCTION__) + "(" + __FILE__ + ":" + std::to_string(__LINE__) + ")"));
    }
  }

}
