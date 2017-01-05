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
	///   - context: dispatch queue to run the handler on
	///   - promises: array of Promises to resolve
	/// - Returns: Promise that resolves to first resolved Promise
	public static func any<L>(context: Context = .main, _ promises: Promise<L>...) -> Promise<L> {
		guard Array(promises).count > 0 else {
			// if number of passed promises is zero a rejected promises is returned
			return Promise<L>(rejected: PromiseError.invalidInput)
		}
		
		let anyPromise = Promise<L> { (resolve, reject) in
			for currentPromise in promises {
				// first promises which resolve is returned
				currentPromise.registerObserver(in: context, fulfill: resolve, reject: reject)
			}
		}
		return anyPromise
	}
	
}
