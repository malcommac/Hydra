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

	/// Allows Promise recovery by returning another Promise
	///
	/// - Parameters:
	///   - context: context in which recovery handler (`body`) is executed (if not specified `background` context is used instead).
	///   - body: recovery handler which should return a new promise
	/// - Returns: Promise
	public func recover(_ context: Context? = nil, _ body: @escaping (Error) throws -> Promise<R>) -> Promise<R> {
		let ctx = context ?? .background
		return Promise<R>(ctx, { resolve, reject in
			self.then(ctx, resolve).catch(self.context, { error in
				do {
					try body(error).then(self.context, resolve)
				} catch (let error) {
					reject(error)
				}
			})
		})
	}
	
}
