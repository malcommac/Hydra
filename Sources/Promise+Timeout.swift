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
	
	/// Timeout does not change sender Promise. Instead it will listen for resolve,reject of it along with a timeout timer.
	/// If promise does not fullfill or reject after given interval it will be marked as rejected with given error (or generic timeout).
	///
	/// - Parameters:
	///   - context: context queue to reject on (if not specified `main` queue is used instead)
	///   - seconds: timeout interval (after passed interval promise will be rejected)
	///   - error: optional; if non-nil value is passed Promise will be rejected with passed error; otherwise `.timeout` is used instead.
	/// - Returns: Promise
	public func timeout(_ context: Context? = nil, interval seconds: TimeInterval, reject error: Error? = nil) -> Promise<R> {
		let ctx = context ?? .main
		let timeoutPromise = Promise<R> { (resolve, reject) in
			// listen for promise fullfill or reject of sel in timeoutPromise
			// All events will be forwarded to resolve,reject of timeoutPromise
			// No changes will be applied
			self.addObserver(in: ctx, fulfill: resolve, reject: reject)
			
			// In order to support timeout we start an async timer; if fired it will mark
			// promise as rejected and return the error you have passed in signature (if nil
			// a generic `.timeout` is fired instead.
			ctx.queue.asyncAfter(deadline: (.now() + seconds), execute: {
				let errorToPass = (error ?? PromiseError.timeout)
				reject(errorToPass)
			})
		}
		return timeoutPromise
	}
	
	
}
