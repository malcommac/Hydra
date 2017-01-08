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
	
	/// Perform an operation in the middle of a chain that does not effect the resolved value.
	/// However it may reject the chain.
	///
	/// - Parameters:
	///   - context: dispatch queue to run the body on (if not specified `background` is used instead)
	///   - body: block to run in the middle of the promise chain. Chain waits for the returned Promise to resolve
	/// - Returns: Promise that resolves to the result of the previous Promise
	public func forward<N>(_ context: Context? = nil, _ body: @escaping (R) throws -> Promise<N>) -> Promise<R> {
		let ctx = context ?? .background
		return self.then(ctx, { value in
			try body(value).then(ctx, { _ in
				Promise(asFulfilled: value)
			})
		})
	}
	
	/// Perform an operation in the middle of a chain that does not effect the resolved value.
	/// However it may reject the chain.
	///
	/// - Parameters:
	/// - context: dispatch queue to run the body on (if not specified `background` is used instead)
	/// - body: block to run in the middle of the promise chain
	/// - Returns: Promise that resolves to the result of the previous Promise
	@discardableResult
	public func forward(_ context: Context? = nil, _ body: @escaping (R) throws -> Void) -> Promise<R> {
		let ctx = context ?? .background
		return self.forward(ctx, { value in
			try Promise<Void>(asFulfilled: body(value))
		})
	}
}
