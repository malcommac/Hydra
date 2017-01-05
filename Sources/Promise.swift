//
//  Promise.swift
//  Hydra
//
//  Created by Daniele Margutti on 05/01/2017.
//  Copyright © 2017 Daniele Margutti. All rights reserved.
//

import Foundation


public class Promise<R> {
	
	/// This is a typealias which define the body of a promise.
	public typealias Body =  ((_ fulfill: @escaping (R) -> (), _ reject: @escaping (Error) -> () ) throws -> ())
	
	//MARK: Private Variables
	
	/// This define the state of the promise.
	/// A promise can move only from a .pending state to .fulfilled or .rejected
	/// Once modified no other changes are allowed
	private(set) var state: State<R>
	
	/// This is the lock queue used to manage thread-safe access to Promise's state and registered callbacks
	private let lockQueue = DispatchQueue(label: "com.hydra.promiselock.queue", qos: .userInitiated)
	
	/// This is the list of registered observer for this promise.
	/// Observer are fired when Promise state did change from .pending status or if it's already in a final state.
	/// There are two kind of observers; one for fulfill and another for rejections.
	private var observers: [Observer<R>] = []
	
	/// Context in which the promise's body will be resolved
	private(set) var context: Context = .background
	
	//MARK: Initialization functions
	
	/// Initialize a new empty state promise
	/// Each state is always initialized in pending state.
	public init() {
		self.state = .pending
	}
	
	/// Initialize a new Promise and allows you to define the body of the function you want to execute inside it.
	///
	/// - Parameters:
	///   - context: context represent the GCD queue in which the body of the promise is executed. If not specified background queue is used
	///   - body:	this closure represent the container of your Promise's function. Here you will add your code and to mark the promise's
	///				the status as `fullfiled` or `rejected` you will call one of the two functions defined by the closure signature.
	public convenience init(_ context: Context = .background, _ body: @escaping Body) {
		self.init()
		self.context = context
		context.queue.async(execute: {
			// Do/catch statement allows you to reject a promises also using throw function
			// (in addition to the classic reject() call)
			do {
				try body(self.fulfill, self.reject)
			} catch let error {
				// an exception will cause a rejection of the promise
				self.reject(error)
			}
		})
	}
	
	/// Initialize a new Promise without body and already fulfilled with given `value`.
	/// Usually you don't need to use this initializer; it's used as helper function
	/// by several Promise's function like `.then()` or `.catch()`.
	///
	/// - Parameter value: fulfill value of the Promise
	public convenience init(fulfilled value: R) {
		self.init()
		self.state = .fulfilled(value: value)
	}
	
	/// Initialize a new Promise without body and already `rejected` with given `error`.
	/// Usually you don't need to use this initializer; it's used as helper function
	/// by several Promise's function like `.then()` or `.catch()`.
	///
	/// - Parameter value: reject error
	public convenience init(rejected error: Error) {
		self.init()
		self.state = .rejected(error: error)
	}
	
	//MARK: Internal Promise Management
	
	/// This is the function passed as Promise's fulfill value in `body`'s closure function.
	///
	/// - Parameter value: `value` used to set fulfilled state for this Promise
	public func fulfill(_ value: R) {
		self.updateState(.fulfilled(value: value))
	}
	
	
	/// This is the function passed as Promise's reject value in `body`'s closure function
	///
	/// - Parameter error: `error` used to set the rejected state for this Promise
	public func reject(_ error: Error) {
		self.updateState(.rejected(error: error))
	}
	
	
	/// This function change the state of the Promise (it's thread safe).
	/// Any change of the Promise's internal state fire appropriate registered callbacks (based upon the new state).
	///
	/// - Parameter state: new state to set
	private func updateState(_ state: State<R>) {
		guard case .pending = self.state else {
			return
		}
		lockQueue.sync(execute: {
			self.state = state
		})
		self.fireObservers()
	}
	
	
	/// Register a new fullfill and rejected observer for this promise.
	/// While generally callbacks are registered as pair (on fulfill and on reject) you may register only a single event observer.
	///
	/// - Parameters:
	///   - context: context in which registered callbacks are called.
	///   - fHandler: optional fulfill handler to call
	///   - rHandler: optional reject handler to call
	internal func registerObserver(in context: Context, fulfill fHandler: ((R) -> (Void))?, reject rHandler: ((Error) -> (Void))? ) {
		lockQueue.async(execute: {
			if fHandler != nil {
				let fulfillCallback = Observer<R>.whenFulfilled(context: context, handler: fHandler!)
				self.observers.append(fulfillCallback)
			}
			if rHandler != nil {
				let rejectCallback = Observer<R>.whenRejected(context: context, handler: rHandler!)
				self.observers.append(rejectCallback)
			}
		})
		self.fireObservers()
	}
	
	/// Fire callbacks call (in thread safe manner) any registered callback which is compatible
	/// with the current `state` of the Promise. So for example, if your promise is `.fulfilled` only
	/// `.whenFulfilled` callbacks are called.
	private func fireObservers() {
		lockQueue.async(execute: {
			guard !self.state.isPending else { return }
			self.observers.forEach { callback in
				switch self.state {
				case let .fulfilled(result):
					callback.fulfill(value: result)
				case let .rejected(error):
					callback.reject(error: error)
				default:
					break
				}
			}
			self.observers.removeAll()
		})
	}
	
}
