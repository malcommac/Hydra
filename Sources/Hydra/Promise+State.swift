//
//  Promise+State.swift
//  Hydra
//
//  Created by Nishinobu.Takahiro on 2017/05/30.
//  Copyright © 2017年 Daniele Margutti. All rights reserved.
//

import Foundation

extension Promise {
	
	//MARK: Promise State
	
	/// This represent the state of a Promise
	///
	/// - pending: pending state. Promise was not evaluated yet.
	/// - fulfilled: final state. Promise was fulfilled with expected value instance.
	/// - rejected: final state. Promise was rejected with given error.
	internal indirect enum State {
		case pending
		case resolved(_: Value)
		case rejected(_: Error)
		
		/// Resolved `value` associated with the state. `nil` if the state is not `resolved`.
		var value: Value? {
			guard case .resolved(let value) = self else { return nil }
			return value
		}
		
		/// Error associated with the state. `nil` if the state is not `rejected`.
		var error: Error? {
			guard case .rejected(let error) = self else { return nil }
			return error
		}
		
		/// Return `true` if the promise is in `pending` state, `false` otherwise.
		var isPending: Bool {
			guard case .pending = self else { return false }
			return true
		}
	}
	
}
