//
//  Promise+Forward.swift
//  Hydra
//
//  Created by Daniele Margutti on 05/01/2017.
//  Copyright © 2017 Daniele Margutti. All rights reserved.
//

import Foundation

public extension Promise {
	
	/// Perform an operation in the middle of a chain that does not effect the resolved value.
	/// However it may reject the chain.
	///
	/// - Parameters:
	///   - context: dispatch queue to run the body on
	///   - body: block to run in the middle of the promise chain. Chain waits for the returned Promise to resolve
	/// - Returns: Promise that resolves to the result of the previous Promise
	public func forward<N>(_ context: Context = .main, _ body: @escaping (R) throws -> Promise<N>) -> Promise<R> {
		return self.then(context, { value in
			try body(value).then(context, { _ in
				Promise(fulfilled: value)
			})
		})
	}
	
	/// Perform an operation in the middle of a chain that does not effect the resolved value.
	/// However it may reject the chain.
	///
	/// - Parameters:
	/// - context: dispatch queue to run the body on
	/// - body: block to run in the middle of the promise chain
	/// - Returns: Promise that resolves to the result of the previous Promise
	@discardableResult
	public func forward(_ context: Context = .main, _ body: @escaping (R) throws -> Void) -> Promise<R> {
		return self.forward(context, { value in
			try Promise<Void>(fulfilled: body(value))
		})
	}
}
