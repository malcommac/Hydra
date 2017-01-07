//
//  Promise+Always.swift
//  Hydra
//
//  Created by Daniele Margutti on 05/01/2017.
//  Copyright © 2017 Daniele Margutti. All rights reserved.
//

import Foundation

public extension Promise {
	
	/// If added to the chain this function always run given handler regardless of the wether the chain resolves or rejects.
	///
	/// - Parameters:
	///   - context: handler to run the handler on (if not specified `background` queue is used instead)
	///   - body: handler to run at the end of the promise chain
	/// - Returns: a Promise to chain
	@discardableResult
	public func always(_ context: Context? = nil, _ body: @escaping () throws -> Void) -> Promise<R> {
		let ctx = context ?? .background
		return Promise<R> { resolve, reject in
			let onResolve: (R) -> (Void) = { value in
				do {
					try body()
					resolve(value)
				} catch {
					reject(error)
				}
			}
			let onReject: (Error) -> (Void) = { error in
				do {
					try body()
					reject(error)
				} catch {
					reject(error)
				}
			}
			self.addObserver(in: ctx, fulfill: onResolve, reject: onReject)
		}
	}
	
}
