//
//  Promise+Flow.swift
//  Hydra
//
//  Created by Daniele Margutti on 05/01/2017.
//  Copyright © 2017 Daniele Margutti. All rights reserved.
//

import Foundation

public extension Promise {
	
	/// Perform an operation on a Promise once it resolves. The chain will then resolve to the Promise returned from the handler.
	/// This `.then()` is used to chain a Promise with another Promise. So, for example, you can do this:
	/// `self.asyncFunc1.then(self.asyncFunc2)`
	/// the result of the first promise is passed as first argument to the second chained promise and the output is the
	/// type of the second promise.
	///
	/// - Parameters:
	///   - context: context in which the `fulfillEndHandler` is called (that's not the context in which the second Promise is called)
	///   - fulfillEndHandler: this is the handler executed when the first promise (left side) is resolved. You can return
	///     another promise to chain or your code which end up with a promise to chain.
	/// - Returns: a new Promise with the new value defined by right side Promise
	public func then<N>(in context: Context = .main, _ fulfillEndHandler: @escaping (R) throws -> Promise<N>) -> Promise<N> {
		return Promise<N> { resolve, reject in
			let fulfillLeft: (R) -> (Void) = { value in
				// Let's try to execute then handler by passing first promise's result as first argument of the chained promise
				do {
					let returnedPromise = try fulfillEndHandler(value)
					returnedPromise.then(in: context, fulfill: resolve, reject: reject)
				} catch let error {
					reject(error)
				}
			}
			// We want to get notified when a Promise ends up with a fullfill or a rejection
			// If left side (first/self) Promise ends fulfilled we want to pass it's argument as first argument of the
			// second promise; otherwise if its ends rejected we simply forward to rejection function.
			self.registerObserver(in: context, fulfill: fulfillLeft, reject: reject)
		}
	}
	
	
	/// Perform an operation on a Promise once it resolves. The chain will then resolve to the Promise returned from the handler.
	///
	/// - Parameters:
	///   - context: context in which the `fulfillEndHandler` is called (that's not the context in which the second Promise is called)
	///   - onFulfill: block to run when Promise resolved, returns a Promsie that mutates the Promise chain
	/// - Returns: a Promise with the new value to return
	@discardableResult
	public func then<N>(in context: Context = .main, _ onFulfill: @escaping (R) throws -> N) -> Promise<N> {
		return then(in: context, { (value) -> Promise<N> in
			do {
				return Promise<N>(fulfilled: try onFulfill(value))
			} catch let error {
				return Promise<N>(rejected: error)
			}
		})
	}
	
	@discardableResult
	private func then(in context: Context = .main, fulfill: @escaping (R) -> (), reject: @escaping (Error) -> () = { _ in }) -> Promise<R> {
		return Promise<R> { resolve, reject in
			self.registerObserver(in: context, fulfill: fulfill, reject: reject)
		}
	}
	
}
