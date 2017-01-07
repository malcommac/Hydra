//
//  Promise+All.swift
//  Hydra
//
//  Created by Daniele Margutti on 05/01/2017.
//  Copyright © 2017 Daniele Margutti. All rights reserved.
//

import Foundation


/// Return a Promises that resolved when all input Promises resolves.
/// Promises are resolved in parallel in background QoS queue.
/// It rejects as soon as a promises reject for any reason; result reject with returned error.
///
/// - Parameters:
///   - context: handler queue to run the handler on
///   - promises: list of promises to resolve in parallel
/// - Returns: resolved promise which contains all resolved values from input promises (value are reported in the same order of input promises)
public func all<L>(_ promises: Promise<L>...) -> Promise<[L]> {
	return all(promises)
}

public func all<L, S: Sequence>(_ promises: S) -> Promise<[L]> where S.Iterator.Element == Promise<L> {
	guard Array(promises).count > 0 else {
		// If number of passed promises is zero we want to return a resolved promises with an empty array as result
		return Promise<[L]>(asFulfilled: []);
	}
	
	// We want to create a Promise which groups all input Promises and return only
	// when all input promises fullfill or one of them reject.
	// Promises are resolved in parallel but the array with the results of all promises is reported
	// in the same order of the input promises.
	let allPromise = Promise<[L]> { (resolve, reject) in
		var countRemaining = Array(promises).count
		let allPromiseContext: Context = .custom(queue: DispatchQueue(label: "com.hydra.queue.all"))
		
		for currentPromise in promises {
			// Listen for each promise in list to fulfill or reject
			currentPromise.addObserver(in: allPromiseContext, fulfill: { value in
				// if currentPromise fulfill
				// decrement remaining promise to fulfill
				countRemaining -= 1
				if countRemaining == 0 {
					// if all promises are fullfilled we can resolve our chain Promise
					// with an array of all values results of our input promises (in the same order)
					let allResults = promises.map({ return $0.state.value! })
					resolve(allResults)
				}
				// if currentPromise reject the entire chain is broken and we reject the group Promise itself
			}, reject: reject)
		}
	}
	return allPromise
}

