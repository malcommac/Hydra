//
//  Promise+Observer.swift
//  Hydra
//
//  Created by Nishinobu.Takahiro on 2017/05/30.
//  Copyright © 2017年 Daniele Margutti. All rights reserved.
//

import Foundation

extension Promise {
	
	//MARK: Promise Observer
	
	/// This enum represent an observer which receive the state of a promise.
	///
	/// - onResolve: register an handler which is executed only if target promise is fulfilled.
	/// - onReject: register an handler which is executed only if target promise is rejected.
	internal indirect enum Observer {
		typealias ResolveObserver = ((Value) -> (Void))
		typealias RejectObserver = ((Error) -> (Void))
		
		case onResolve(_: Context, _: ResolveObserver)
		case onReject(_: Context, _: RejectObserver)
		
		/// Call the observer by state
		///
		/// - Parameter state: State
		func call(_ state: State) {
			switch (self, state) {
			case (.onResolve(let context, let handler), .resolved(let value)):
				context.queue.async {
					handler(value)
				}
			case (.onReject(let context, let handler), .rejected(let error)):
				context.queue.async {
					handler(error)
				}
			default:
				return
			}
		}
		
	}
	
}
