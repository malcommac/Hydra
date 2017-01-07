//
//  Promise+Ensure.swift
//  Hydra
//
//  Created by Daniele Margutti on 05/01/2017.
//  Copyright © 2017 Daniele Margutti. All rights reserved.
//

import Foundation

public extension Promise {
	
	/// ensure is a method that takes a predicate, and rejects the promise chain if that predicate fails.
	///
	/// - Parameters:
	///   - context: context queue (if not specified `background` context is used instead)
	///   - condition: predicate you should use to validation. return `false` to reject promise, true to `fulfill` and pass the value forward.
	/// - Returns: Promise
	public func ensure(_ context: Context? = nil, _ condition: @escaping (R) -> Bool) -> Promise<R> {
		let ctx = context ?? .background
		return self.then(ctx, { (value: R) -> R in
			guard condition(value) else {
				throw PromiseError.rejected
			}
			return value
		})
	}
	
}
