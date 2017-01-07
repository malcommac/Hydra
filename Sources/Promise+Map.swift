//
//  Promise+Map.swift
//  Hydra
//
//  Created by Daniele Margutti on 07/01/2017.
//  Copyright © 2017 Daniele Margutti. All rights reserved.
//

import Foundation

/// Promise resolve tryp
///
/// - parallel: resolve all promises in parallel
/// - series: resolve all promises in series, in order
public enum PromiseResolveType {
	case parallel
	case series
}

/// Map an array of items and transform it to Promises.
/// Then promises can be resolved in parallel or serially; rejects as soon as any Promise rejects.
///
/// - Parameters:
///   - context: context to run the handler on (if not specified `background` context is used)
///   - type: type of execution
///   - items: items to transform
///   - transform: transform callback which return the promise
/// - Returns: a Promise which resolve all created promises
public func map<A, B, S: Sequence>(_ context: Context? = nil, type: PromiseResolveType, _ items: S, _ transform: @escaping (A) throws -> Promise<B>) -> Promise<[B]> where S.Iterator.Element == A {

	let ctx = context ?? .background
	switch type {
	case .parallel:
		return map_parallel(context: ctx, items: items, transform: transform)
	default:
		return map_series(context: ctx, items: items, transform: transform)
	}
}

public func map_series<A, B, S: Sequence>(context: Context, items: S, transform: @escaping (A) throws -> Promise<B>) -> Promise<[B]> where S.Iterator.Element == A {
	let initial = Promise<[B]>(asFulfilled: [])
	
	return items.reduce(initial) { chain, item in
		return chain.then(context) { results in
			try transform(item).then(context) { results + [$0] }
		}
	}
}

internal func map_parallel<A, B, S: Sequence>(context: Context, items: S, transform: @escaping (A) throws -> Promise<B>) -> Promise<[B]> where S.Iterator.Element == A {
	
	let transformPromise = Promise<Void>(asFulfilled: ())
	return transformPromise.then(context) { (Void) -> Promise<[B]> in
		do {
			let mappedPromises: [Promise<B>] = try items.map({ item in
				return try transform(item)
			})
			return all(mappedPromises)
		} catch let error {
			return Promise<[B]>(asRejected: error)
		}
	}
}

