/*
* Hydra
* Fullfeatured lightweight Promise & Await Library for Swift
*
* Created by:	Daniele Margutti
* Email:		hello@danielemargutti.com
* Web:			http://www.danielemargutti.com
* Twitter:		@danielemargutti
*
* Copyright © 2017 Daniele Margutti
*
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in
* all copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
* THE SOFTWARE.
*
*/

import Foundation
import XCTest

@testable import Hydra

public enum TestErrors: Error {
	case someError
	case anotherError
}

class HydraTestThen: XCTestCase {
	
	let delayResult: TimeInterval = 0.5
	let expTimeout: TimeInterval = 20000
	
	override func setUp() { super.setUp() }
	override func tearDown() { super.tearDown() }
	
	//MARK: Init Tests
	
	/// Test a fulfilled promise.
	/// A fulfilled promise is a promise already set to a fulfilled state
	/// with a given value. Usually you don't need to create a fulfilled with
	/// a final state; Hydra uses this concept to chain multiple promises.
	func test_fulfilledPromise() {
		let promise = Promise<Int>(resolved: 6)
		XCTAssertNil(promise.state.error)
		XCTAssertNotNil(promise.state.value)
		XCTAssert((promise.state.value! == 6), "Invalid fulfilled result")
	}
	
	
	/// Test a rejected promise.
	/// A fulfilled promise is a promise already set to a fulfilled state
	/// with a given value. Usually you don't need to create a fulfilled with
	/// a final state; Hydra uses this concept to chain multiple promises.
	func test_rejectedPromise() {
		let promise = Promise<Int>(rejected: TestErrors.someError)
		XCTAssertNil(promise.state.value)
		XCTAssertNotNil(promise.state.error)
		guard case TestErrors.someError = promise.state.error! else {
			XCTFail()
			return
		}
	}
	
	
	/// This test ensure which a fullfill dispatcher correctly return the
	/// correct resolve value.
	func test_fulfillDispatcher() {
		let result = "Hello"
		Promise<String> { fulfill,_,_ in
			fulfill(result)
			}.then { value in
				XCTAssertEqual(value, result)
		}
	}
	
	
	/// This test evaluate an async promise by calling both resolve and reject
	/// The result we expect is resolve because Promise in a final state cannot
	/// transit to another state.
	func test_asyncFulfillRaceCondition() {
		let exp = expectation(description: "test_asyncFulfillRaceCondition")
		let fulfillResult = "Hello"
		let rejectError = TestErrors.someError
		Promise<String> { fullfill,reject,_ in
			fullfill(fulfillResult)
			reject(rejectError)
			}.then { result in
				if result == fulfillResult {
					print("chiamata")
					exp.fulfill()
				} else {
					XCTFail()
				}
		}
		waitForExpectations(timeout: expTimeout, handler: nil)
	}
	
	
	/// This test evaluate an async promise by calling both reject and resolve
	/// one after the other.
	/// The result we expect is reject with given error while the final state
	/// cannot be further modified.
	func test_asyncRejectRaceCondition() {
		let exp = expectation(description: "test_asyncRejectRaceCondition")
		let fulfillResult = "Hello"
		let rejectError = TestErrors.someError
		let promise = Promise<String> { fullfill,reject,_ in
			reject(rejectError)
			fullfill(fulfillResult)
		}
		promise.then { result in
			XCTFail()
			}.catch { err in
				if let err = err as? TestErrors {
					XCTAssertEqual(err, rejectError)
					exp.fulfill()
				} else {
					XCTFail()
				}
		}
		waitForExpectations(timeout: expTimeout, handler: nil)
	}
	
	//MARK: Then Tests
	
	/// Test `then` operator to see if a fake async promise resolves correctly
	func test_then() {
		let exp = expectation(description: "test_then")
		let expectedInt = 5
		intPromise(expectedInt).then { value in
			XCTAssertEqual(expectedInt, value)
			exp.fulfill()
		}
		waitForExpectations(timeout: expTimeout, handler: nil)
	}
	
	
	/// Test `then` which transform a promise value as input for another promise
	/// and verify final result
	func test_thenPromise() {
		let exp = expectation(description: "test_thenPromise")
		let expectedInt = 5
		intPromise(expectedInt).then { value in
			self.toStringPromise("##\(value)##")
			}.then { strValue in
				XCTAssertEqual(strValue, "##\(expectedInt)##")
				exp.fulfill()
		}
		waitForExpectations(timeout: expTimeout, handler: nil)
	}
	
	
	/// Test `then` to chain a promise with another promise and get a transformed version of
	/// the result of the first promise
	func test_thenPromiseAlt() {
		let exp = expectation(description: "test_thenPromise")
		let expectedInt = 5
		intPromise(expectedInt).then(doubleIntPromise).then { result in
			XCTAssertEqual(result,expectedInt*2)
			exp.fulfill()
		}
		waitForExpectations(timeout: expTimeout, handler: nil)
	}
	
	//MARK: Catch Tests
	
	/// Test single `catch` statement applied to a promise with resolve with an error
	func test_catchSingle() {
		let exp = expectation(description: "test_catch")
		let rejectError = TestErrors.anotherError
		intFailedPromise(rejectError).then { _ in
			XCTFail()
			}.catch { err in
				if let err = err as? TestErrors {
					XCTAssertEqual(err, rejectError)
					exp.fulfill()
				} else {
					XCTFail()
				}
		}
		waitForExpectations(timeout: expTimeout, handler: nil)
	}
	
	
	/// Test multiple promises which fails and end in a single `catch`
	func test_catchMultiple() {
		let exp = expectation(description: "test_catch")
		
		let p = intPromise(5)
		p.then { value in
			self.toStringErrorPromise(value)
			}.catch { err in
				if let err = err as? TestErrors {
					if err == TestErrors.anotherError {
						exp.fulfill()
					} else {
						XCTFail()
					}
				} else {
					XCTFail()
				}
		}
		waitForExpectations(timeout: expTimeout, handler: nil)
	}
	
	//MARK: Recover tests
	
	
	/// Test `recover` operator. When a promise is rejected is possible to add
	/// a `recover` operator into the chain. This operator receive the error as input
	/// and return another Promise with the same value of the previous promise as output.
	// In this test we have tried to recover a bad call by executing a resolving promise.
	// Test is passed if recover works and we get a valid result into the final `then`.
	func test_recoverPromise() {
		let exp = expectation(description: "test_recoverPromise")
		let expResult = 5
		intPromise(expResult).then { value in
			self.toStringErrorPromise(value)
			}.recover { err -> Promise<String> in
				return self.toStringPromise("\(expResult)")
			}.then { string in
				if ("\(expResult)" != string) {
					XCTFail()
				}
				exp.fulfill()
		}
		waitForExpectations(timeout: expTimeout, handler: nil)
	}
	
	/// If return rejected promise in `recover` operator, chain to next as its error.
	func test_recover_failure() {
		let exp = expectation(description: "test_recover_failure")
		
		let errPromise = intFailedPromiseImmediate(TestErrors.anotherError)
		errPromise.recover { (err) -> Promise<Int> in
			return Promise<Int>(rejected: TestErrors.someError)
			}.catch { (e) -> () in
				XCTAssertEqual(e as! TestErrors, TestErrors.someError)
				exp.fulfill()
		}
		waitForExpectations(timeout: expTimeout, handler: nil)
	}
	
	//MARK: Pass tests
	
	
	/// `pass` operator is used for performing an operation in the middle of a promise
	/// chain without changing the type of the Promise.
	/// In this test we simply print the value in the middle of the chain for logging purpose.
	/// Test is passed if promise resolves correctly.
	func test_pass() {
		let exp = expectation(description: "test_pass")
		let expResult = 5
		intPromise(expResult).pass { value in
			print("logging \(value)")
			}.then { final in
				exp.fulfill()
		}
		waitForExpectations(timeout: expTimeout, handler: nil)
	}
	
	
	/// This is another test with `pass` operator. We have added `pass` in multiple points of a chain.
	/// We expect that result of the caller promise will not change into pass block and the result is
	/// passed over to the next promise.
	func test_passSequence() {
		let exp = expectation(description: "test_passSequence")
		let expResult = 5
		intPromise(5).pass { value in
			print("value is int \(value)")
			}.then(intPromise).pass { value in
				print("value is int \(value)")
			}.then { value in
				if value != expResult {
					XCTFail()
				} else {
					exp.fulfill()
				}
		}
		waitForExpectations(timeout: expTimeout, handler: nil)
	}
	
	//MARK: Always
	
	/// `always` operator is used to perform a block of code always at the end of a promise regardless
	/// the result is a valid value or an error.
	/// In this test we put the always before a catch and we should continue to receive the final value.
	func test_always() {
		let exp = expectation(description: "test_always")
		intPromise(5).always {
			exp.fulfill()
			}.catch { _ in
				XCTFail()
		}
		waitForExpectations(timeout: expTimeout, handler: nil)
	}
	
	
	/// Another test with `pass` operator a the end of the chain.
	/// Test resolves if the block is executed for a valid resolved promise.
	func test_alwaysSequence() {
		let exp = expectation(description: "test_always")
		intPromise(5).pass { value in
			print(value)
			}.then { value -> Promise<String> in
				return self.toStringPromise("\(value)")
			}.always {
				exp.fulfill()
		}
		waitForExpectations(timeout: expTimeout, handler: nil)
	}
	
	/// Another test with `pass` operator a the end of the chain.
	/// Test resolves if the block is executed for a rejected resolved promise.
	func test_alwaysError() {
		let exp = expectation(description: "test_always")
		intFailedPromise(TestErrors.anotherError).then { value in
			XCTFail()
			}.catch { err in
				print("\(err)")
			}.always {
				exp.fulfill()
		}
		waitForExpectations(timeout: expTimeout, handler: nil)
	}
	
	//MARK Any Test
	
	
	/// `any` operator resolve a promise when at least one of the input promises has been resolved or rejected
	/// Test is resolved when the first promise is resolved (se second one is delayed and should be not resolved before).
	func test_any() {
		let exp = expectation(description: "test_any")
		let promise1 = Promise<Int>(resolved: 1)
		let promise2 = intPromise(5)
		any(promise1, promise2).then { result in
			XCTAssertEqual(result, promise1.result!)
			exp.fulfill()
			}.catch { _ in
				XCTFail()
		}
		waitForExpectations(timeout: expTimeout, handler: nil)
	}
	
	/// The same test with `any` operator which takes as input an array instead of variable list of arguments
	func test_anyWithArray() {
		let exp = expectation(description: "test_anyWithArray")
		let promise1 = Promise<Int>(resolved: 1)
		let promise2 = intPromise(5)
		any([promise1, promise2]).then { result in
			XCTAssertEqual(result, promise1.result!)
			exp.fulfill()
			}.catch { _ in
				XCTFail()
		}
		waitForExpectations(timeout: expTimeout, handler: nil)
	}
	
	func test_anyWithAllBodyPromise() {
		let exp = expectation(description: "test_anyWithAllBodyPromise")
		let promise1 = intPromiseDelay(100, delay: 0.1)
		let promise2 = intPromise(5)
		any(promise1, promise2).then { result in
			XCTAssertEqual(result, promise1.result!)
			exp.fulfill()
			}.catch { _ in
				XCTFail()
		}
		waitForExpectations(timeout: expTimeout, handler: nil)
	}
	
	func test_anyWithArrayAllBodyPromise() {
		let exp = expectation(description: "test_anyWithArrayAllBodyPromise")
		let promise1 = intPromiseDelay(100, delay: 0.1)
		let promise2 = intPromise(5)
		any([promise1, promise2]).then { result in
			XCTAssertEqual(result, promise1.result!)
			exp.fulfill()
			}.catch { _ in
				XCTFail()
		}
		waitForExpectations(timeout: expTimeout, handler: nil)
	}
	
	//MARK: All Tests
	
	
	/// `all` operator resolve a promise which takes as input an array of promise
	/// the all-promise resolves when all promises resolves correctly or one of them has been rejecged.
	/// Test resolves when all promises has a valid result.
	func test_all() {
		let exp = expectation(description: "test_all")
		let promise1 = Promise<Int>(resolved: 3)
		let promise2 = intPromise(12)
		all(promise1, promise2).then { results in
			XCTAssertEqual(results[0], promise1.result!)
			XCTAssertEqual(results[1], promise2.result!)
			exp.fulfill()
			}.catch { _ in
				XCTFail()
		}
		waitForExpectations(timeout: expTimeout, handler: nil)
	}
	
	/// `all` operator with comcurrency argument test.
	/// body executable timing will restricted by concurrency.
	func test_all_with_concurrency() {
		let exp = expectation(description: "test_all_with_concurrency")
		var timebasedResults = [Int]()
		let promise1 = intPromiseDelayWithCompletion(3, delay: 0.5, completion: { timebasedResults.append($0) })
		let promise2 = intPromiseDelayWithCompletion(12, delay: 0, completion: { timebasedResults.append($0) })
		all(promise1, promise2, concurrency: 1).then { results in
			XCTAssertEqual(results[0], 3)
			XCTAssertEqual(results[1], 12)
			XCTAssertEqual(timebasedResults[0], promise1.result!)
			XCTAssertEqual(timebasedResults[1], promise2.result!)
			exp.fulfill()
			}.catch { _ in
				XCTFail()
		}
		waitForExpectations(timeout: expTimeout, handler: nil)
	}
	
	/// This is another test with `all` operator.
	/// This test it's okay if all-promise is rejected because one of the input promise rejects.
	func test_allError() {
		let exp = expectation(description: "test_allError")
		let promise1 = Promise<Int>(resolved: 1)
		let promise2 = intFailedPromise(TestErrors.anotherError)
		all([promise1, promise2]).then { results in
			XCTFail()
			}.catch { error in
				XCTAssertEqual(error as! TestErrors, TestErrors.anotherError)
				exp.fulfill()
		}
		waitForExpectations(timeout: expTimeout, handler: nil)
	}
	
	//MARK: Map Tests
	
	
	/// `map` operator transform an input array in an array of promises.
	/// Test works using `map` by executing each transformation in parallel.
	/// Result is done when all promises are resolved and the result should be ordered.
	func test_mapConcurrent() {
		executeMap(as: PromiseResolveType.parallel)
	}
	
	/// `map` operator transform an input array in an array of promises.
	/// Test works using `map` by executing each transformation in series.
	/// Result is done when all promises are resolved (one after another).
	func test_mapSeries() {
		executeMap(as: PromiseResolveType.series)
	}
	
	func executeMap(as type: PromiseResolveType) {
		let exp = expectation(description: "test_mapConcurrent")
		let items = [1, 4, 7, 15, 55, 12, 0]
		let itemsDoubled = [2, 8, 14, 30, 110, 24, 0]
		
		map(as: type, items) { result in
			return self.doubleIntPromise(result)
			}.then { items in
				if items.elementsEqual(itemsDoubled) {
					exp.fulfill()
				} else {
					XCTFail()
				}
			}.catch { _ in
				XCTFail()
		}
		waitForExpectations(timeout: expTimeout, handler: nil)
	}
	
	//MARK: Defer Tests
	
	/// `defer` test defer the execution of the next promise of the chain by a specified interval expressed in seconds.
	/// This test ensure the result arrives ~5seconds after the first promise is resolved.
	func test_defer() {
		let exp = expectation(description: "test_defer")
		let started = Date()
		Promise<Int>(resolved: 5).defer(5).then { value in
			let diff = Date().timeIntervalSince(started)
			if diff > 5 && diff <= 5.3 {
				exp.fulfill()
			} else {
				XCTFail()
			}
		}
		waitForExpectations(timeout: expTimeout, handler: nil)
	}
	
	//MARK: Timeout Tests
	
	/// `timeout` operator is used to reject a promise if it takes more than a specified interval to get resolved
	/// This test ensure that the promise itself resolves because the operation, delayed by 0.5s, is fulfilled
	/// into the range of 0.7 seconds.
	func test_timeoutOK() {
		let exp = expectation(description: "test_timeoutOK")
		intPromiseDelay(5, delay: 0.5).timeout(timeout: 0.7).then { value in
			exp.fulfill()
			}.catch { _ in
				XCTFail()
		}
		waitForExpectations(timeout: expTimeout, handler: nil)
	}
	
	/// The same test with `timeout` but here the delay is higher than timeout so we expect
	/// promise fails with given error.
	func test_timeoutFailed() {
		let exp = expectation(description: "test_timeoutFailed")
		intPromiseDelay(5, delay: 1.5).timeout(timeout: 0.7).then { value in
			XCTFail()
			}.catch { _ in
				exp.fulfill()
		}
		waitForExpectations(timeout: expTimeout, handler: nil)
	}
	
	// Async Tests
	
	func test_async() {
		let exp = expectation(description: "test_async")
		let returnValue = 5
		async { (_) -> Int in
			Thread.sleep(forTimeInterval: 2.0)
			return returnValue
			}.then { value in
				if value == returnValue {
					exp.fulfill()
				} else {
					XCTFail()
				}
		}
		waitForExpectations(timeout: expTimeout, handler: nil)
	}
	
	// Await Tests
	
	
	/// `await` operator allows to execute async operation in sync fashion
	/// This test passes if all operation are resolved one after another when the previous is finished
	func test_await() {
		let exp = expectation(description: "test_await")
		async(in: .background) {
			do {
				let startValue = 5
				//				let result1 = try ..self.intPromise(startValue)
				let result1 = try await(self.intPromise(startValue))
				let result2 = try ..self.intPromiseDelay(result1 * 2, delay: 0.5)
				let result3 = try ..self.intPromiseDelay(result2 * 2, delay: 0.5)
				if result3 == startValue * 4 {
					exp.fulfill()
				} else {
					XCTFail()
				}
			} catch {
				XCTFail()
			}
		}
		waitForExpectations(timeout: expTimeout, handler: nil)
	}
	
	/// The same test with `async` but here we expect the entire async session fail
	func test_awaitFailed() {
		let exp = expectation(description: "test_awaitFailed")
		async(in: .background) {
			do {
				let startValue = 5
				let _ = try ..self.intPromise(startValue)
				let result2 = try ..self.intFailedPromise(TestErrors.anotherError)
				let _ = try ..self.intPromiseDelay(result2 * 2, delay: 0.5)
				XCTFail()
			} catch {
				exp.fulfill()
			}
		}
		waitForExpectations(timeout: expTimeout, handler: nil)
	}
	
	// Reduce Tests
	
	
	/// `reduce` operator allows to reduce an array of items to a single promise.
	/// Test works if end value is resolved correctly.
	func test_reduce() {
		let exp = expectation(description: "test_reduce")
		let items = [1,5,10,20,40,60,80]
		reduce(items, 0) { (partial, current) in
			return self.doubleAndSumImmediatePromise(partial: partial, value: current)
			}.then { value in
				if value == 432 {
					exp.fulfill()
				} else {
					XCTFail()
				}
			}.catch { _ in
				XCTFail()
		}
		waitForExpectations(timeout: expTimeout, handler: nil)
	}
	
	/// The same test with `reduce` but here we expect it to fail
	func test_reduceError() {
		let exp = expectation(description: "test_reduceError")
		let items = [1,5,10,20,40,60,80]
		reduce(items, 0) { (partial, current) in
			guard partial > 200 else {
				return self.intFailedPromiseImmediate(TestErrors.anotherError)
			}
			return self.doubleAndSumImmediatePromise(partial: partial, value: current)
			}.then { value in
				XCTFail()
			}.catch { _ in
				exp.fulfill()
		}
		waitForExpectations(timeout: expTimeout, handler: nil)
	}
	
	//MARK: Retry Test
	
	func test_retry() {
		let exp = expectation(description: "test_retry")
		
		let retryAttempts = 3
		let successOnAttempt = 3
		var currentAttempt = 0
		Promise<Int> { (resolve, reject, _) in
			currentAttempt += 1
			if currentAttempt < successOnAttempt {
				print("attempt is \(currentAttempt)... reject")
				reject(TestErrors.anotherError)
			} else {
				print("attempt is \(currentAttempt)... resolve")
				resolve(5)
			}
			}.retry(retryAttempts).then { value in
				print("value \(value) at attempt \(currentAttempt)")
				XCTAssertEqual(currentAttempt, 3)
				exp.fulfill()
			}.catch { err in
				print("failed \(err) at attempt \(currentAttempt)")
				XCTFail()
		}
		
		waitForExpectations(timeout: expTimeout, handler: nil)
	}
	
	func test_retry_allFailure() {
		let exp = expectation(description: "test_retry_allFailure")
		
		let retryAttempts = 3
		var currentAttempt = 0
		Promise<Int> { (resolve, reject, _) in
			currentAttempt += 1
			print("attempt is \(currentAttempt)... reject")
			reject(TestErrors.anotherError)
			}.retry(retryAttempts).then { value in
				print("value \(value) at attempt \(currentAttempt)")
				XCTFail()
			}.catch { err in
				print("failed \(err) at attempt \(currentAttempt)")
				XCTAssertEqual(err as! TestErrors, .anotherError)
				XCTAssertEqual(currentAttempt, 3)
				exp.fulfill()
		}
		
		waitForExpectations(timeout: expTimeout, handler: nil)
		
	}
	
	func test_retry_condition() {
		let exp = expectation(description: "test_retry_condition")
		
		let retryAttempts = 5
		let successOnAttempt = 5
		let retryableRemainAttempt = 2
		var currentAttempt = 0
		Promise<Int> { (resolve, reject, _) in
			currentAttempt += 1
			if currentAttempt < successOnAttempt {
				print("attempt is \(currentAttempt)... reject")
				reject(TestErrors.anotherError)
			} else {
				print("attempt is \(currentAttempt)... resolve")
				resolve(5)
			}
			}.retry(retryAttempts) { (remainAttempts, error) -> Bool in
				if remainAttempts > retryableRemainAttempt {
					print("retry remainAttempts is \(remainAttempts)... true")
					return true
				} else {
					print("retry remainAttempts is \(remainAttempts)... false")
					return false
				}
			}.then { value in
				print("value \(value) at attempt \(currentAttempt)")
				XCTFail()
			}.catch { err in
				print("failed \(err) at attempt \(currentAttempt)")
				XCTAssertEqual(err as! TestErrors, .anotherError)
				XCTAssertEqual(currentAttempt, 3)
				exp.fulfill()
		}
		
		waitForExpectations(timeout: expTimeout, handler: nil)
	}
	
    //MARK: RetryWhen Test
    
    func test_retryWhen() {
        let exp = expectation(description: "test_retryWhen")
        
        let retryAttempts = 3
        let successOnAttempt = 3
        var currentAttempt = 0
        Promise<Int> { (resolve, reject, _) in
            currentAttempt += 1
            if currentAttempt < successOnAttempt {
                print("attempt is \(currentAttempt)... reject")
                reject(TestErrors.anotherError)
            } else {
                print("attempt is \(currentAttempt)... resolve")
                resolve(5)
            }
        }.retryWhen(retryAttempts).then { value in
            print("value \(value) at attempt \(currentAttempt)")
            XCTAssertEqual(currentAttempt, 3)
            exp.fulfill()
        }.catch { (err) in
            print("failed \(err) at attempt \(currentAttempt)")
            XCTFail()
        }
        waitForExpectations(timeout: expTimeout, handler: nil)
    }
    
    func test_retryWhen_allFailure() {
        let exp = expectation(description: "test_retryWhen_allFailure")
        
        let retryAttempts = 3
        var currentAttempt = 0
        Promise<Int> { (resolve, reject, _) in
            currentAttempt += 1
            print("attempt is \(currentAttempt)... reject")
            reject(TestErrors.anotherError)
            }.retryWhen(retryAttempts).then { value in
                print("value \(value) at attempt \(currentAttempt)")
                XCTFail()
            }.catch { err in
                print("failed \(err) at attempt \(currentAttempt)")
                XCTAssertEqual(err as! TestErrors, .anotherError)
                XCTAssertEqual(currentAttempt, 3)
                exp.fulfill()
        }
        
        waitForExpectations(timeout: expTimeout, handler: nil)
        
    }
    
    func test_retryWhen_condition() {
        let exp = expectation(description: "test_retryWhen_condition")
        
        let retryAttempts = 5
        let successOnAttempt = 5
        let retryableRemainAttempt = 2
        var currentAttempt = 0
        Promise<Int> { (resolve, reject, _) in
            currentAttempt += 1
            if currentAttempt < successOnAttempt {
                print("attempt is \(currentAttempt)... reject")
                reject(TestErrors.anotherError)
            } else {
                print("attempt is \(currentAttempt)... resolve")
                resolve(5)
            }
        }.retryWhen(retryAttempts) { (remainAttempts, error) -> Promise<Bool> in
            if remainAttempts > retryableRemainAttempt {
                print("retry remainAttempts is \(remainAttempts)... true")
                return Promise<Bool>(resolved: true).defer(5)
            } else {
                print("retry remainAttempts is \(remainAttempts)... false")
                return Promise<Bool>(resolved: false)
            }
        }.then { value in
            print("value \(value) at attempt \(currentAttempt)")
            XCTFail()
        }.catch { err in
            print("failed \(err) at attempt \(currentAttempt)")
            XCTAssertEqual(err as! TestErrors, .anotherError)
            XCTAssertEqual(currentAttempt, 3)
            exp.fulfill()
        }
        
        waitForExpectations(timeout: expTimeout, handler: nil)
    }
    
	func test_invalidationTokenWithAsyncOperator() {
		let exp = expectation(description: "test_retry_condition")
		let invalidator: InvalidationToken = InvalidationToken()
		
		async(token: invalidator, { st -> String in
			Thread.sleep(forTimeInterval: 2.0)
			if st.isCancelled {
				print("Promise cancelled")
				exp.fulfill()
			} else {
				print("Promise resolved")
				XCTFail()
			}
			return ""
		}).then { _ in

		}
		invalidator.invalidate()
		waitForExpectations(timeout: expTimeout, handler: nil)
	}
	
	func test_invalidationToken() {
		let exp = expectation(description: "test_retry_condition")

		let invalidator: InvalidationToken = InvalidationToken()
		
		DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 2, execute: {
			invalidator.isCancelled = true
		})
		
		test_invalidationToken(token: invalidator).then { total in
			print("Operation finished with: \(total)")
			XCTFail()
		}.cancelled {
			print("Operation cancelled")
			exp.fulfill()
		}
		
		waitForExpectations(timeout: expTimeout, handler: nil)
	}
	
	func test_cancelledPromiseChainable() {
		let exp = expectation(description: "test_cancelledPromiseChainable")
		
		let invalidator: InvalidationToken = InvalidationToken()
		invalidator.isCancelled = true
		
		test_invalidationToken(token: invalidator)
			.retry()
			.recover { (error) -> Promise<Int> in
				XCTFail()
				return Promise<Int>(resolved: 1)
			}
			.defer(0.1)
			.pass { (value) in
				XCTFail()
			}
			.then { (value) -> Int in
				XCTFail()
				return 2
			}
			.validate { (value) -> (Bool) in
				XCTFail()
				return value == 2
			}
			.catch { (error) -> () in
				XCTFail()
			}.cancelled {
				print("Operation cancelled")
				exp.fulfill()
		}
		
		waitForExpectations(timeout: expTimeout, handler: nil)
	}
	
	func test_invalidationToken(token: InvalidationToken) -> Promise<Int> {
		return Promise<Int>(in: .main, token: token, { (resolve, reject, op) in
			var total: Int = 0
			for i in 0..<100 {
				if op.isCancelled == true {
					op.cancel()
					return
				}
				sleep(1)
				total += i
			}
			resolve(total)
		})
	}
	
	//MARK: Helper
	
	func intFailedPromise(_ error: Error) -> Promise<Int> {
		return Promise<Int> { _, reject, _ in
			DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + self.delayResult, execute: {
				reject(error)
			})
		}
	}
	
	func intFailedPromiseImmediate(_ error: Error) -> Promise<Int> {
		return Promise<Int> { _, reject, _ in
			reject(error)
		}
	}
	
	func intPromise(_ value: Int = 10) -> Promise<Int> {
		return Promise<Int> { resolve, _, _ in
			DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + self.delayResult, execute: {
				resolve(value)
			})
		}
	}
	
	func intPromiseImmediate(_ value: Int = 10) -> Promise<Int> {
		return Promise<Int> { resolve, _, _ in
			resolve(value)
		}
	}
	
	func intPromiseDelay(_ value: Int = 10, delay: TimeInterval) -> Promise<Int> {
		return Promise<Int> { resolve, _, _ in
			DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + delay, execute: {
				resolve(value)
			})
		}
	}
	
	func intPromiseDelayWithCompletion(_ value: Int = 10, delay: TimeInterval, completion: ((Int) -> Void)? = nil) -> Promise<Int> {
		return Promise<Int> { resolve, _, _ in
			DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + delay, execute: {
				completion?(value)
				resolve(value)
			})
		}
	}
	
	func doubleIntPromise(_ input: Int) -> Promise<Int> {
		return Promise<Int> { resolve, _, _ in
			DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + self.delayResult, execute: {
				resolve(input*2)
			})
		}
	}
	
	func doubleAndSumImmediatePromise(partial: Int, value: Int) -> Promise<Int> {
		return Promise<Int> { resolve, _, _ in
			resolve( partial + (value * 2) )
		}
	}
	
	func toStringErrorPromise(_ input: Int) -> Promise<String> {
		return Promise<String> { _, reject, _ in
			DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + self.delayResult, execute: {
				reject(TestErrors.anotherError)
			})
		}
	}
	
	func toStringPromise(_ input: String) -> Promise<String> {
		return Promise<String> { resolve, _, _ in
			DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + self.delayResult, execute: {
				resolve(input)
			})
		}
	}
	
}
