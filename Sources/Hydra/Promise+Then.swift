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

public extension Promise {
	
	/// Perform an operation on a Promise once it resolves. The chain will then resolve to the Promise returned from the handler.
	/// This `.then` is used to chain a Promise with another Promise. So, for example, you can do this:
	/// `self.asyncFunc1.then(self.asyncFunc2)`
	/// the result of the first promise is passed as first argument to the second chained promise and the output is the
	/// type of the second promise.
	///
	/// - Parameters:
	///   - context: context in which the `body` is called (if not specified `main` is used instead)
	///   - body: this is the handler executed when the first promise (left side) is resolved. You can return
	///     another promise to chain or your code which end up with a promise to chain.
	/// - Returns: a new Promise with the new value defined by right side Promise
	public func then<N>(_ context: Context? = nil, _ body: @escaping (R) throws -> Promise<N>) -> Promise<N> {
		let ctx = context ?? .main
		return Promise<N> { resolve, reject in
			let fulfillLeft: (R) -> (Void) = { value in
				// Let's try to execute then handler by passing first promise's result as first argument of the chained promise
				do {
					let returnedPromise = try body(value)
					returnedPromise.then(ctx, fulfill: resolve, reject: reject)
				} catch let error {
					reject(error)
				}
			}
			// We want to get notified when a Promise ends up with a fullfill or a rejection
			// If left side (first/self) Promise ends fulfilled we want to pass it's argument as first argument of the
			// second promise; otherwise if its ends rejected we simply forward to rejection function.
			self.addObserver(in: ctx, fulfill: fulfillLeft, reject: reject)
		}
	}
	
	
	/// Perform an operation on a Promise once it resolves. The chain will then resolve to the Promise returned from the handler.
	///
	/// - Parameters:
	///   - context: context in which the `fulfillEndHandler` is called (that's not the context in which the second Promise is called)
	///   - onFulfill: block to run when Promise resolved, returns a Promsie that mutates the Promise chain
	/// - Returns: a Promise with the new value to return
	@discardableResult
	public func then<N>(_ context: Context? = nil, _ onFulfill: @escaping (R) throws -> N) -> Promise<N> {
		let ctx = context ?? .main
		return then(ctx, { (value) -> Promise<N> in
			do {
				return Promise<N>(asFulfilled: try onFulfill(value))
			} catch let error {
				return Promise<N>(asRejected: error)
			}
		})
	}
	
	@discardableResult
	private func then(_ context: Context = .main, fulfill: @escaping (R) -> (), reject: @escaping (Error) -> () = { _ in }) -> Promise<R> {
		return Promise<R> { resolve, reject in
			self.addObserver(in: context, fulfill: fulfill, reject: reject)
		}
	}
	
}
