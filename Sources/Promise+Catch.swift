//
//  Promise+Catch.swift
//  Hydra
//
//  Created by Daniele Margutti on 05/01/2017.
//  Copyright © 2017 Daniele Margutti. All rights reserved.
//

import Foundation

public extension Promise {
	
	/// Catches an error in a Promise chain and allows the chain to recover.
	///
	/// - Parameters:
	///   - context: context to run the handler on
	///   - handler: handler to run when Promise chain rejects
	/// - Returns: a void Promise
	@discardableResult
	public func `catch`(context: Context = .main, _ handler: @escaping (Error) throws -> Void) -> Promise<Void> {
		return Promise<Void> { (resolve, reject) in
			let onResolve: (R) -> (Void) = { value in
				resolve(())
			}
			let onReject: (Error) -> (Void) = { error in
				do {
					try handler(error)
				} catch {
					return reject(error)
				}
				resolve(())
			}
			self.registerObserver(in: context, fulfill: onResolve, reject: onReject)
		}
	}
	
}
