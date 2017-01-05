//
//  Promise+Zip.swift
//  Hydra
//
//  Created by Daniele Margutti on 05/01/2017.
//  Copyright © 2017 Daniele Margutti. All rights reserved.
//

import Foundation

public extension Promise {
	
	public static func zip<A, B>(_ context: Context = .background, _ first: Promise<A>, _ second: Promise<B>) -> Promise<(A,B)> {
		let tuplePromise = Promise<(A,B)>(context) { resolve, reject in
			let onResolve: (Any) -> () = { value in
				if let value_a = first.state.value, let value_b = second.state.value {
					resolve( (value_a,value_b) )
				}
			}
			first.then(.background, onResolve).catch(context: context, reject)
			second.then(.background, onResolve).catch(context: context, reject)
		}
		return tuplePromise
	}
		
}
