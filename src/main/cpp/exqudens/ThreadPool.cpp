#include "exqudens/ThreadPool.hpp"

/* separator */

namespace exqudens {

  ThreadPool::ThreadPool(): ThreadPool(
      std::thread::hardware_concurrency()
  ) {
  }

  ThreadPool::ThreadPool(size_t queueSize): ThreadPool(
      queueSize,
      queueSize
  ) {
  }

  ThreadPool::ThreadPool(size_t queueSize, size_t threadSize):
      queueSize(queueSize),
      stop(false)
  {
    try {
      if (queueSize == 0) {
        throw std::invalid_argument(CALL_INFO() + ": 'queueSize' is zero");
      }
      if (threadSize == 0) {
        throw std::invalid_argument(CALL_INFO() + ": 'threadSize' is zero");
      }
      for(size_t i = 0; i < threadSize; i++) {
        threads.emplace_back([this]{
          while(true) {
            std::function<void()> task;
            {
              std::unique_lock<std::mutex> lock(this->mutex);
              this->condition.wait(lock, [this]{ return this->stop || !this->queue.empty(); });
              if(this->stop && this->queue.empty()) {
                return;
              }
              task = std::move(this->queue.front());
              this->queue.pop();
            }
            task();
          }
        });
      }
    } catch (...) {
      std::throw_with_nested(std::runtime_error(CALL_INFO()));
    }
  }

  ThreadPool::~ThreadPool() {
    {
      std::unique_lock<std::mutex> lock(mutex);
      stop = true;
    }
    condition.notify_all();
    for(std::thread& thread : threads) {
      thread.join();
    }
  }

}
