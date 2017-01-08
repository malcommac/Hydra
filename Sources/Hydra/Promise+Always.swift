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
	
	/// If added to the chain this function always run given handler regardless of the wether the chain resolves or rejects.
	///
	/// - Parameters:
	///   - context: handler to run the handler on (if not specified `background` queue is used instead)
	///   - body: handler to run at the end of the promise chain
	/// - Returns: a Promise to chain
	@discardableResult
	public func always(_ context: Context? = nil, _ body: @escaping () throws -> Void) -> Promise<R> {
		let ctx = context ?? .background
		return Promise<R> { resolve, reject in
			let onResolve: (R) -> (Void) = { value in
				do {
					try body()
					resolve(value)
				} catch {
					reject(error)
				}
			}
			let onReject: (Error) -> (Void) = { error in
				do {
					try body()
					reject(error)
				} catch {
					reject(error)
				}
			}
			self.addObserver(in: ctx, fulfill: onResolve, reject: onReject)
		}
	}
	
}
