//
//  Shared.swift
//  Hydra
//
//  Created by Daniele Margutti on 05/01/2017.
//  Copyright © 2017 Daniele Margutti. All rights reserved.
//

import Foundation

//
//  Commons.swift
//  Hydra
//
//  Created by Daniele Margutti on 22/12/2016.
//  Copyright © 2016 Daniele Margutti. All rights reserved.
//

import Foundation

/// GCD Wrapper
///
/// - background: A system-defined global concurrent queue with a Background quality of service class.
/// - main:  The serial queue associated with the application’s main thread.
/// - userInteractive: A system-defined global concurrent queue with a User Interactive quality of service class
/// - userInitiated:  A system-defined global concurrent queue with a User Initiated quality of service class.
/// - `default`: A system-defined global concurrent queue with a Default quality of service class.
/// - utility: A system-defined global concurrent queue with a Utility quality of service class.
/// - custom: A user-created custom queue. Use DispatchQueue.createSerial() or DispatchQueue.createConcurrent().
public enum Context {
	case background
	case main
	case userInteractive
	case userInitiated
	case `default`
	case utility
	
	case custom(queue: DispatchQueue)
	
	public var queue: DispatchQueue {
		switch self {
		case .background:
			return DispatchQueue.global(qos: .background)
		case .main:
			return DispatchQueue.main
		case .userInteractive:
			return DispatchQueue.global(qos: .userInteractive)
		case .userInitiated:
			return DispatchQueue.global(qos: .userInitiated)
		case .default:
			return DispatchQueue.global(qos: .default)
		case .utility:
			return DispatchQueue.global(qos: .utility)
		case .custom(let queue):
			return queue
		}
	}
}

public enum PromiseError: Error {
	case invalidInput
	case timeoutFired
	case predicateRejected
	case awaitOnMainQueue
}

public enum State<R> {
	case pending
	case fulfilled(value: R)
	case rejected(error: Error)
	
	public var isPending: Bool {
		guard case .pending = self else { return false }
		return true
	}
	
	public var error: Error? {
		guard case .rejected(let err) = self else { return nil }
		return err
	}
	
	public var value: R? {
		guard case .fulfilled(let value) = self else { return nil }
		return value
	}
}

public enum Observer<R> {
	case whenFulfilled(context: Context, handler: (R) -> ())
	case whenRejected(context: Context, handler: (Error) -> ())
	
	func fulfill(value: R) {
		guard case .whenFulfilled(let ctx, let fulfillHandler) = self else {
			return
		}
		ctx.queue.async(execute: {
			fulfillHandler(value)
		})
	}
	
	func reject(error: Error) {
		guard case .whenRejected(let ctx, let errorHandler) = self else {
			return
		}
		ctx.queue.async(execute: {
			errorHandler(error)
		})
	}
}
