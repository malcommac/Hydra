//
//  Promise+Timeout.swift
//  Hydra
//
//  Created by Daniele Margutti on 05/01/2017.
//  Copyright © 2017 Daniele Margutti. All rights reserved.
//

import Foundation

public extension Promise {
	
	/// Timeout does not change sender Promise. Instead it will listen for resolve,reject of it along with a timeout timer.
	/// If promise does not fullfill or reject after given interval it will be marked as rejected with given error (or generic timeout).
	///
	/// - Parameters:
	///   - context: context queue to reject on
	///   - seconds: timeout interval (after passed interval promise will be rejected)
	///   - error: optional; if non-nil value is passed Promise will be rejected with passed error; otherwise `.timeout` is used instead.
	/// - Returns: Promise
	public func timeout(_ context: Context = .main, interval seconds: TimeInterval, reject error: Error? = nil) -> Promise<R> {
		let timeoutPromise = Promise<R> { (resolve, reject) in
			// listen for promise fullfill or reject of sel in timeoutPromise
			// All events will be forwarded to resolve,reject of timeoutPromise
			// No changes will be applied
			self.registerObserver(in: context, fulfill: resolve, reject: reject)
			
			// In order to support timeout we start an async timer; if fired it will mark
			// promise as rejected and return the error you have passed in signature (if nil
			// a generic `.timeout` is fired instead.
			context.queue.asyncAfter(deadline: (.now() + seconds), execute: {
				let errorToPass = (error ?? PromiseError.timeout)
				reject(errorToPass)
			})
		}
		return timeoutPromise
	}
	
	
}
