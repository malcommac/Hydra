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

//MARK: PromiseError

/// This is the list of standard errors provided by a Promise. You can extended this enum or
/// use another one to provide your own errors list (you must inherit from Swift's `Error` protocol).
///
/// - invalidInput: invalid input
/// - timeout: timeout reached
/// - rejected: promise rejected
/// - invalidContext: invalid context provided
/// - attemptsFailed: number of attempts reached but the promise is rejected
public enum PromiseError: Error {
	case timeout
	case rejected
	case invalidInput
	case invalidContext
	case attemptsFailed
}

//MARK: Promise State

/// This represent the state of a Promise
///
/// - pending: pending state. Promise was not evaluated yet.
/// - fulfilled: final state. Promise was fulfilled with expected value instance.
/// - rejected: final state. Promise was rejected with given error.
internal enum State<Value> {
	case pending
	case resolved(_: Value)
	case rejected(_: Error)
	
	/// Resolved `value` associated with the state. `nil` if the state is not `resolved`.
	var value: Value? {
		guard case .resolved(let value) = self else { return nil }
		return value
	}
	
	/// Error associated with the state. `nil` if the state is not `rejected`.
	var error: Error? {
		guard case .rejected(let error) = self else { return nil }
		return error
	}
	
	/// Return `true` if the promise is in `pending` state, `false` otherwise.
	var isPending: Bool {
		guard case .pending = self else { return false }
		return true
	}
}


/// This enum represent an observer which receive the state of a promise.
///
/// - onResolve: register an handler which is executed only if target promise is fulfilled.
/// - onReject: register an handler which is executed only if target promise is rejected.
internal enum Observer<Value> {
	typealias ResolveObserver = ((Value) -> (Void))
	typealias RejectObserver = ((Error) -> (Void))
	
	case onResolve(_: Context, _: ResolveObserver)
	case onReject(_: Context, _: RejectObserver)
	
	/// Call the observer by state
	///
	/// - Parameter state: State<Value>
	func call(_ state: State<Value>) {
		switch (self, state) {
		case (.onResolve(let context, let handler), .resolved(let value)):
			context.queue.async {
				handler(value)
			}
		case (.onReject(let context, let handler), .rejected(let error)):
			context.queue.async {
				handler(error)
			}
		default:
			return
		}
	}
	
}
