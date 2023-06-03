#pragma once

#include <ranges>
#include <format>
#include <vector>
#include <algorithm>
#include <iostream>
#include <thread>
#include <chrono>

#include <gtest/gtest.h>

#include "exqudens/TestUtils.hpp"
#include "exqudens/ThreadPool.hpp"

namespace exqudens {

  int testFunction1() {
    return 123;
  }

  int testFunction2(int value) {
    return value;
  }

  class TestObject {

    public:

      int testMethod1() {
        return 123;
      }

      int testMethod2(int value) {
        return value;
      }

  };

  /*!

    @brief Macro Tests::test1 test doc.

  */
  TEST(Tests, test1) {
    ThreadPool pool(3);
    TestObject object;
    auto testLambda1 = [] () { return 123; };
    std::future<int> testLambdaFuture = pool.submit(testLambda1);
    std::future<int> testFunctionFuture = pool.submit(&testFunction1);
    std::future<int> testMethodFuture = pool.submit(std::bind(&TestObject::testMethod1, object));
    int testLambdaExpected = 123;
    int testFunctionExpected = 123;
    int testMethodExpected = 123;
    int testLambda1result = testLambdaFuture.get();
    int testFunction1result = testFunctionFuture.get();
    int testMethod1result = testMethodFuture.get();
    ASSERT_EQ(testLambdaExpected, testLambda1result);
    ASSERT_EQ(testFunctionExpected, testFunction1result);
    ASSERT_EQ(testMethodExpected, testMethod1result);
  }

  TEST(Tests, test2) {
    ThreadPool pool(3);
    TestObject object;
    auto testLambda2 = [] (int value) { return value; };
    std::future<int> testLambdaFuture = pool.submit(testLambda2, 123);
    std::future<int> testFunctionFuture = pool.submit(&testFunction2, 456);
    std::future<int> testMethodFuture = pool.submit(std::bind(&TestObject::testMethod2, object, std::placeholders::_1), 789);
    int testLambdaExpected = 123;
    int testFunctionExpected = 456;
    int testMethodExpected = 789;
    int testLambdaResult = testLambdaFuture.get();
    int testFunctionResult = testFunctionFuture.get();
    int testMethodResult = testMethodFuture.get();
    ASSERT_EQ(testLambdaExpected, testLambdaResult);
    ASSERT_EQ(testFunctionExpected, testFunctionResult);
    ASSERT_EQ(testMethodExpected, testMethodResult);
  }

  TEST(Tests, test3) {
    ThreadPool pool(3);
    int result = 0;
    auto testLambda = [&result] { result = 123; };
    std::future<void> testLambdaFuture = pool.submit(testLambda);
    testLambdaFuture.get();
    int expected = 123;
    ASSERT_EQ(expected, result);
  }

  TEST(Tests, test4) {
    ASSERT_THROW(ThreadPool pool(1, 0), std::exception);
    ASSERT_THROW(ThreadPool pool(0, 1), std::exception);
    ASSERT_THROW(ThreadPool pool(0, 0), std::exception);
    try {
      ThreadPool pool(0, 1);
      FAIL() << "'std::exception' is not thrown";
    } catch (const std::exception& e) {
      std::vector<std::string> errorMessages = TestUtils::toStringVector(e);
      ASSERT_EQ(2, errorMessages.size());
      ASSERT_NE(std::string::npos, errorMessages.at(1).find("'queueSize' is zero"));
    } catch (...) {
      FAIL() << "'std::exception' is not thrown";
    }
    try {
      ThreadPool pool(1, 0);
      FAIL() << "'std::exception' is not thrown";
    } catch (const std::exception& e) {
      std::vector<std::string> errorMessages = TestUtils::toStringVector(e);
      ASSERT_EQ(2, errorMessages.size());
      ASSERT_NE(std::string::npos, errorMessages.at(1).find("'threadSize' is zero"));
    } catch (...) {
      FAIL() << "'std::exception' is not thrown";
    }
    try {
      ThreadPool pool(0, 0);
      FAIL() << "'std::exception' is not thrown";
    } catch (const std::exception& e) {
      std::vector<std::string> errorMessages = TestUtils::toStringVector(e);
      ASSERT_EQ(2, errorMessages.size());
      ASSERT_NE(std::string::npos, errorMessages.at(1).find("'queueSize' is zero"));
    } catch (...) {
      FAIL() << "'std::exception' is not thrown";
    }
  }

  TEST(Tests, test5) {
    ThreadPool pool(3);
    auto testLambda = [] { throw std::invalid_argument("test!"); };
    std::future<void> testLambdaFuture = pool.submit(testLambda);
    try {
      testLambdaFuture.get();
      FAIL() << "'std::invalid_argument' is not thrown";
    } catch (const std::invalid_argument& e) {
      ASSERT_EQ(std::string("test!"), std::string(e.what()));
    } catch (...) {
      FAIL() << "'std::invalid_argument' is not thrown";
    }
  }

  /*TEST(Tests, test99) {
    ThreadPool pool;
    std::future<int> testFunction1future = pool.submit(&testFunction1);
    int expected = 123;
    int result = testFunction1future.get();
    ASSERT_EQ(expected, result);
    std::future<int> future = pool.submit(
        [](int i) {
          std::this_thread::sleep_for(std::chrono::seconds(5));
          return i;
        },
        expected
    );
    result = future.get();
    ASSERT_EQ(expected, result);
  }*/

  /*TEST(Tests, test99) {
    auto even = [](int i) { return 0 == i % 2; };
    auto println = [] (const auto& i) { std::cout << std::format("{}", i) << std::endl; };

    std::vector<int> result;
    std::ranges::copy(
        std::views::iota(0, 10) | std::views::filter(even),
        std::back_inserter(result)
    );

    std::ranges::for_each(
        result,
        println
    );

    std::vector<int> expected({0, 2, 4, 6, 8});

    ASSERT_EQ(result, expected);
  }*/

}
