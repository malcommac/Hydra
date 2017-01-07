//
//  Promise+Delay.swift
//  Hydra
//
//  Created by Daniele Margutti on 05/01/2017.
//  Copyright © 2017 Daniele Margutti. All rights reserved.
//

import Foundation

public extension Promise {
	
	/// Delay the executon of a Promise chain by some number of seconds from current time
	///
	/// - Parameters:
	///   - seconds: delay time in seconds; execution time is `.now()+seconds`
	///   - result: the Promise to resolve to after the delay
	/// - Returns: Promise
	public func delay(_ seconds: TimeInterval) -> Promise<R> {
		return self.then(context, { value in
			return Promise<R> { resolve, _ in
				let fireTime: DispatchTime = .now() + seconds
				Context.background.queue.asyncAfter(deadline: fireTime) {
					resolve(value)
				}
			}
		})
	}
}
