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
	
	/// Catches an error in a Promise chain and allows the chain to recover.
	///
	/// - Parameters:
	///   - context: context to run the handler on
	///   - handler: handler to run when Promise chain rejects
	/// - Returns: a void Promise
	@discardableResult
	public func `catch`(_ context: Context? = nil, _ body: @escaping (Error) throws -> Void) -> Promise<Void> {
		let ctx = context ?? .main
		return Promise<Void> { (resolve, reject) in
			let onResolve: (R) -> (Void) = { value in
				resolve(())
			}
			let onReject: (Error) -> (Void) = { error in
				do {
					try body(error)
				} catch {
					return reject(error)
				}
				resolve(())
			}
			self.addObserver(in: ctx, fulfill: onResolve, reject: onReject)
		}
	}
	
}
