//
//  Promise+Zip.swift
//  Hydra
//
//  Created by Daniele Margutti on 05/01/2017.
//  Copyright © 2017 Daniele Margutti. All rights reserved.
//

import Foundation


/// Join two promises and return a tuple with the results of both (promises will be resolved in parallel in `background` QoS queue).
/// Rejects as soon one promise reject.
///
/// - Parameters:
///   - context: context queue to report the result (if not specified `background` queue is used instead)
///   - a: promise a
///   - b: promise b
/// - Returns: joined promise of type Promise<(A,B)>
public func zip<A, B>(_ context: Context? = nil, _ a: Promise<A>, _ b: Promise<B>) -> Promise<(A,B)> {
	let ctx = context ?? .background
	return all(a.voidPromise(),b.voidPromise()).then(ctx, { _ in
		return Promise<(A, B)>(asFulfilled: (a.state.value!, b.state.value!))
	})
}


/// Join three promises and return a tuple with the results of the three passed promises (promises will be resolved in parallel in `background` QoS queue).
/// Rejects as soon one promise reject.
///
/// - Parameters:
///   - context: context queue to report the result (if not specified `background` queue is used instead)
///   - a: promise a
///   - b: promise b
///   - c: promise c
/// - Returns: joined promise of type Promise<(A,B,C)>
public func zip<A,B,C>(_ context: Context? = nil, a: Promise<A>, b: Promise<B>, c: Promise<C>) -> Promise<(A,B,C)> {
	let ctx = context ?? .background
	return all(a.voidPromise(),b.voidPromise(),c.voidPromise()).then(ctx, { _ in
		return Promise<(A, B, C)>(asFulfilled: (a.state.value!, b.state.value!, c.state.value!))
	})
}


/// Join two promises and return a tuple with the results of the four promises passed (promises will be resolved in parallel in `background` QoS queue).
/// Rejects as soon one promise reject.
///
/// - Parameters:
///   - context: context queue to report the result (if not specified `background` queue is used instead)
///   - a: promise a
///   - b: promsie b
///   - c: promise c
///   - d: promise d
/// - Returns: joined promise of type Promise<(A,B,C,D)>
public func zip<A,B,C,D>(_ context: Context? = nil, a: Promise<A>, b: Promise<B>, c: Promise<C>, d: Promise<D>) -> Promise<(A,B,C,D)> {
	let ctx = context ?? .background
	return all(a.voidPromise(),b.voidPromise(),c.voidPromise()).then(ctx, { _ in
		return Promise<(A, B, C, D)>(asFulfilled: (a.state.value!, b.state.value!, c.state.value!, d.state.value!))
	})
}
	
