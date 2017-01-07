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
	///   - context: context queue
	///   - predicate: predicate you should use to validation
	/// - Returns: Promise
	public func ensure(_ context: Context = .main, _ predicate: @escaping (R) -> Bool) -> Promise<R> {
		return self.then(in: context, { (value: R) -> R in
			guard predicate(value) else {
				throw PromiseError.rejected
			}
			return value
		})
	}
	
}
