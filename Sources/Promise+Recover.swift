//
//  Promise+Recover.swift
//  Hydra
//
//  Created by Daniele Margutti on 05/01/2017.
//  Copyright © 2017 Daniele Margutti. All rights reserved.
//

import Foundation

public extension Promise {

	/// Allows Promise recovery by returning another Promise
	///
	/// - Parameters:
	///   - context: context in which recovery handler (`body`) is executed (if not specified `background` context is used instead).
	///   - body: recovery handler which should return a new promise
	/// - Returns: Promise
	public func recover(_ context: Context? = nil, _ body: @escaping (Error) throws -> Promise<R>) -> Promise<R> {
		let ctx = context ?? .background
		return Promise<R>(ctx, { resolve, reject in
			self.then(ctx, resolve).catch(self.context, { error in
				do {
					try body(error).then(self.context, resolve)
				} catch (let error) {
					reject(error)
				}
			})
		})
	}
	
}
