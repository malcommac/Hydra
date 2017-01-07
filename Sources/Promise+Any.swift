//
//  Promise+Any.swift
//  Hydra
//
//  Created by Daniele Margutti on 05/01/2017.
//  Copyright © 2017 Daniele Margutti. All rights reserved.
//

import Foundation

public extension Promise {
	
	/// Returns a Promise that resolves as soon as one passed in Promise resolves
	///
	/// - Parameters:
	///   - context: dispatch queue to run the handler on (if not specified `background` context is used)
	///   - promises: array of Promises to resolve
	/// - Returns: Promise that resolves to first resolved Promise
	public static func any<L>(_ context: Context? = nil, _ promises: Promise<L>...) -> Promise<L> {
		guard Array(promises).count > 0 else {
			// if number of passed promises is zero a rejected promises is returned
			return Promise<L>(asRejected: PromiseError.invalidInput)
		}
		
		let ctx = context ?? .background
		let anyPromise = Promise<L> { (resolve, reject) in
			for currentPromise in promises {
				// first promises which resolve is returned
				currentPromise.addObserver(in: ctx, fulfill: resolve, reject: reject)
			}
		}
		return anyPromise
	}
	
}
