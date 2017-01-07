//
//  Promise+Map.swift
//  Hydra
//
//  Created by Daniele Margutti on 07/01/2017.
//  Copyright © 2017 Daniele Margutti. All rights reserved.
//

import Foundation

public enum MapType {
	case parallel
	case series
}

/// Map an array of items and transform it to Promises.
/// Then promsies can be resolved in parallel or serially; rejects as soon as any Promise rejects.
///
/// - Parameters:
///   - context: context to run the handler on
///   - type: type of execution
///   - items: items to transform
///   - transform: transform callback which return the promise
/// - Returns: a Promise which resolve all created promises
public func map<A, B, S: Sequence>(in context: Context = .main, type: MapType, _ items: S, _ transform: @escaping (A) throws -> Promise<B>) -> Promise<[B]> where S.Iterator.Element == A {

	switch type {
	case .parallel:
		return map_parallel(in: context, items, transform)
	default:
		return map_series(in: context, items, transform)
	}
}

public func map_series<A, B, S: Sequence>(in context: Context = .main, _ items: S, _ transform: @escaping (A) throws -> Promise<B>) -> Promise<[B]> where S.Iterator.Element == A {
	let initial = Promise<[B]>(fulfilled: [])
	
	return items.reduce(initial) { chain, item in
		return chain.then(in: context) { results in
			try transform(item).then(in: context) { results + [$0] }
		}
	}
}

internal func map_parallel<A, B, S: Sequence>(in context: Context = .main, _ items: S, _ transform: @escaping (A) throws -> Promise<B>) -> Promise<[B]> where S.Iterator.Element == A {
	
	let transformPromise = Promise<Void>(fulfilled: ())
	return transformPromise.then(in: context) { (Void) -> Promise<[B]> in
		do {
			let mappedPromises: [Promise<B>] = try items.map({ item in
				return try transform(item)
			})
			return all(in: context, mappedPromises)
		} catch let error {
			return Promise<[B]>(rejected: error)
		}
	}
}

