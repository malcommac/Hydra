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
}

class HydraTestThen: XCTestCase {
	
	override func setUp() {
		super.setUp()
		
	}
	
	override func tearDown() {
		// Put teardown code here. This method is called after the invocation of each test method in the class.
		super.tearDown()
	}
	
	
	/// Test fulfilled Promise,a prom
	func test_resolvedPromise() {
		let promise = Promise<Int>(asFulfilled: 6)
		XCTAssertNil(promise.state.error)
		XCTAssertNotNil(promise.state.value)
		XCTAssert((promise.state.value! == 6), "Invalid fulfilled result")
	}
	
	
	/// <#Description#>
	func test_rejectedPromise() {
		let promise = Promise<Int>(asRejected: TestErrors.someError)
		XCTAssertNil(promise.state.value)
		XCTAssertNotNil(promise.state.error)
		guard case TestErrors.someError = promise.state.error! else {
			XCTFail()
			return
		}
	}
	
}
