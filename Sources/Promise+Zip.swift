//
//  Promise+Zip.swift
//  Hydra
//
//  Created by Daniele Margutti on 05/01/2017.
//  Copyright © 2017 Daniele Margutti. All rights reserved.
//

import Foundation


/// Join two promises and return a tuple with the results of both (promises will be resolved in parallel).
/// Rejects as soon one promise reject.
///
/// - Parameters:
///   - context: context queue to run the handler on
///   - a: promise a
///   - b: promise b
/// - Returns: joined promise of type Promise<(A,B)>
public func zip<A, B>(in context: Context = .background, _ a: Promise<A>, _ b: Promise<B>) -> Promise<(A,B)> {
	return all(context, a.voidPromise(),b.voidPromise()).then(in: context, { _ in
		return Promise<(A, B)>(fulfilled: (a.value!, b.value!))
	})
}


/// Join three promises and return a tuple with the results of the three passed promises (promises wil lbe resolved in parallel).
/// Rejects as soon one promise reject.
///
/// - Parameters:
///   - context: context queue to run the handler on
///   - a: promise a
///   - b: promise b
///   - c: promise c
/// - Returns: joined promise of type Promise<(A,B,C)>
public func zip<A,B,C>(in context: Context = .background, a: Promise<A>, b: Promise<B>, c: Promise<C>) -> Promise<(A,B,C)> {
	return all(context, a.voidPromise(),b.voidPromise(),c.voidPromise()).then(in: context, { _ in
		return Promise<(A, B, C)>(fulfilled: (a.value!, b.value!, c.value!))
	})
}


/// Join two promises and return a tuple with the results of the four promises passed (promises will be resolved in parallel).
/// Rejects as soon one promise reject.
///
/// - Parameters:
///   - context: context queue to run the handler on
///   - a: promise a
///   - b: promsie b
///   - c: promise c
///   - d: promise d
/// - Returns: joined promise of type Promise<(A,B,C,D)>
public func zip<A,B,C,D>(in context: Context = .background, a: Promise<A>, b: Promise<B>, c: Promise<C>, d: Promise<D>) -> Promise<(A,B,C,D)> {
	return all(context, a.voidPromise(),b.voidPromise(),c.voidPromise()).then(in: context, { _ in
		return Promise<(A, B, C, D)>(fulfilled: (a.value!, b.value!, c.value!, d.value!))
	})
}
	
