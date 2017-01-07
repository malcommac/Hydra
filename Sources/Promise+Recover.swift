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
	/// - Parameter recovery: recovery handler which should return a new promise
	/// - Returns: a new promise to append to the chain
	public func recover(_ recovery: @escaping (Error) throws -> Promise<R>) -> Promise<R> {
		return Promise<R>(self.context, { resolve, reject in
			self.then(in: self.context, resolve).catch(context: self.context, { error in
				do {
					try recovery(error).then(in: self.context, resolve)
				} catch (let error) {
					reject(error)
				}
			})
		})
	}
	
}
