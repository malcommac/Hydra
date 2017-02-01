//
//  HydraTestThen.swift
//  Hydra
//
//  Created by Daniele Margutti on 08/01/2017.
//  Copyright © 2017 Daniele Margutti. All rights reserved.
//

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
		Promise<String> { fulfill,_ in
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
		Promise<String> { fullfill,reject in
			fullfill(fulfillResult)
			reject(rejectError)
		}.then { result in
			if result == fulfillResult {
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
		let promise = Promise<String> { fullfill,reject in
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
	
	//MARK: Pass tests
	
	func test_pass() {
		let exp = expectation(description: "test_pass")
		let expResult = 5
		intPromise(expResult).pass { value in
			print("value is \(value)")
		}.then { final in
			print("final is \(final)")
			exp.fulfill()
		}
		waitForExpectations(timeout: expTimeout, handler: nil)
	}
	
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
	
	func test_always() {
		let exp = expectation(description: "test_always")
		intPromise(5).always {
			exp.fulfill()
		}.catch { _ in
			XCTFail()
		}
		waitForExpectations(timeout: expTimeout, handler: nil)
	}
	
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
	
	//MARK: All Tests
	
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
	
	func test_mapConcurrent() {
		executeMap(as: PromiseResolveType.parallel)
	}
	
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
		}
		waitForExpectations(timeout: expTimeout, handler: nil)
	}
	
	//MARK: Defer Tests
	
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
	
	func test_timeoutOK() {
		let exp = expectation(description: "test_timeoutOK")
		intPromiseDelay(5, delay: 0.5).timeout(timeout: 0.7).then { value in
			exp.fulfill()
		}.catch { _ in
			XCTFail()
		}
		waitForExpectations(timeout: expTimeout, handler: nil)
	}
	
	func test_timeoutFailed() {
		let exp = expectation(description: "test_timeoutFailed")
		intPromiseDelay(5, delay: 1.5).timeout(timeout: 0.7).then { value in
			XCTFail()
		}.catch { _ in
			exp.fulfill()
		}
		waitForExpectations(timeout: expTimeout, handler: nil)
	}
	
	// Await Tests
	
	func test_await() {
		let exp = expectation(description: "test_await")
		do {
			let startValue = 5
			let result1 = try ..intPromise(startValue)
			let result2 = try ..intPromiseDelay(result1 * 2, delay: 0.5)
			let result3 = try ..intPromiseDelay(result2 * 2, delay: 0.5)
			if result3 == startValue * 4 {
				exp.fulfill()
			} else {
				XCTFail()
			}
		} catch {
			XCTFail()
		}
		waitForExpectations(timeout: expTimeout, handler: nil)
	}
	
	func test_awaitFailed() {
		let exp = expectation(description: "test_awaitFailed")
		do {
			let startValue = 5
			let _ = try ..intPromise(startValue)
			let result2 = try ..intFailedPromise(TestErrors.anotherError)
			let _ = try ..intPromiseDelay(result2 * 2, delay: 0.5)
			XCTFail()
		} catch {
			exp.fulfill()
		}
		waitForExpectations(timeout: expTimeout, handler: nil)
	}
	
	// Reduce Tests
	
//	func test_reduce() {
//		let exp = expectation(description: "test_awaitFailed")
//		let items = [1,5,10,40,2,5,7]
//		reduce(items, 0) { (partial, current) in
//			
//		}.then { value in
//			
//		}
//		waitForExpectations(timeout: expTimeout, handler: nil)
//	}
	
	//MARK: Helper
	
	func intFailedPromise(_ error: Error) -> Promise<Int> {
		return Promise<Int> { _, reject in
			DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + self.delayResult, execute: {
				reject(error)
			})
		}
	}
	
	func intPromise(_ value: Int = 10) -> Promise<Int> {
		return Promise<Int> { resolve, _ in
			DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + self.delayResult, execute: {
				resolve(value)
			})
		}
	}
	
	func intPromiseImmediate(_ value: Int = 10) -> Promise<Int> {
		return Promise<Int> { resolve, _ in
			resolve(value)
		}
	}
	
	func intPromiseDelay(_ value: Int = 10, delay: TimeInterval) -> Promise<Int> {
		return Promise<Int> { resolve, _ in
			DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + self.delayResult, execute: {
				resolve(value)
			})
		}
	}
	
	func doubleIntPromise(_ input: Int) -> Promise<Int> {
		return Promise<Int> { resolve, _ in
			DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + self.delayResult, execute: {
				resolve(input*2)
			})
		}
	}
	
	func toStringErrorPromise(_ input: Int) -> Promise<String> {
		return Promise<String> { _, reject in
			DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + self.delayResult, execute: {
				reject(TestErrors.anotherError)
			})
		}
	}
	
	func toStringPromise(_ input: String) -> Promise<String> {
		return Promise<String> { resolve, _ in
			DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + self.delayResult, execute: {
				resolve(input)
			})
		}
	}
	
}
