# Architecture of Hydra

<a name="top"/>
## Index
- [Introduction](#introduction)
- [What's a Promise?](#whatspromise)
- [A bit of history](#history)
- [Promise class internals](#internals)
- [Inside (some) operators](#operators)
	- [then](#then)
	- [catch](#catch)
	- [retry](#retry)
	- [all](#all)
	- [map](#map)
	- [await](#await)

<a name="introduction"/>
### Introduction
Asynchronous programming in Objective-C was never been a truly exciting experience.
We have used delegates for years (I can still remember the first time I’ve seen it, it was around 2001 and I was having fun with Cocoa on my Mac OS X) and not so long ago we have also joined the party of completion handlers.
However both of these processes does not scale well and does not provide a solid error handling mechanism, especially due to some limitations of the language itself (yeah you can do practically  anything in C but...).

It’s damn easy to lost yourself in a callback pyramid of doom and generally your code ends up being not so elegant and not so straightforward to read and maintain.

Promises can help us to write better code and, with the help of constructs like `await/async` it's really a joy to deal with asynchronous programming.
Back in November 2016 I've decided to work on a Promise library just to learn more about how this concept is implemented and how can I do it with a modern language like Swift.
In this article I would to give a deeper look inside the architecture of my Promise library: [Hydra](https://github.com/malcommac/Hydra) is currently available on GitHub and it's pretty stable to be used in production (along with Unit Tests).
In this article you will not learn about how to use Hydra in your next killer app but you will learn how it works behind the scenes (by the way a complete documentation for Hydra is available in Github along with the library itself).

[Index](#top)

<a name="whatspromise"/>
## What's a Promise?
A promise is an object that may produce a single value sometime in the future; this value can be the object you are expecting for (ie. a JSON response) or the reason of failure (ie. a networking error).
A promise may be in one of the following states: `resolved` (or fulfilled), `rejected` or `pending`. A promise starts in pending state and can transit to another of the two states; once settled it cannot be resettled.

Promise's users can attach callbacks (or observers) to get notified about any state change. The most common operators for a Promise are `then` or `catch`, used to get the value of a promise or catch any occurred error. However there are several other operators which simplify a lot how networking code is written, but we'll look at them later.

[Index](#top)

<a name="history"/>
## A bit of history
The history of Promise starts a long time ago, in early 1980's; first implementations began to appear in languages such as Prolog and MultiLisp as early as the 1980's. The word "Promise" was conied by Barbara Liskov and Liuba Shrira in an academic paper called ["Promises: linguistic support for efficient asynchronous procedure calls in distributed systems"](http://dl.acm.org/citation.cfm?doid=53990.54016) (1988).

As promise interest grew, a new specification for Promise was redcated by the ECMAScript standard: [Promise/A+](https://promisesaplus.com/implementations) was written to define the boundaries and behaviour of a Promise.

Main rules for a compliant Promise/A+ implementation are:

- A promise or "thenable" is an object that supplies a standard copliant `.then` function.
- A pending promise may transition into a fulfilled or rejected state.
- A fulfilled or rejected is settled, and must not transition into any other state.
- Once a promise is settled, it must have a value. This value must not change.

[Index](#top)

<a name="internals"/>
## Promise class internals
Due to the [type-safe](https://www.quora.com/What-does-it-mean-if-a-language-is-type-safe) nature of Swift, it's easy to think to a promise which can return a well defined type of output; with Generics we can easily specify what kind of object we are expecting on promise's settle.

Promise can be initialized in two different ways:

- in `pending` state along with a `context` and a `body`. The `body` of a promise define the async action you want to accomplish; the `context` allows you to set a Grand Central Dispatch queue in which the body is executed.
- in a settled state (`resolved` or `rejected`) along with a value or an error. Generally you don't need to init a settled promise but it's useful to implements specific behaviour for some custom operators (we'll look at this later).

The first case is fairly more interesting to look. First of all: a pending promise is not resolved immediately just after user initialize a new instance but in a lazy way; it simply retain a reference to the `body` closure and the `context` received.
The `body` closure will be executed only when you attach an operator to the instance (while lots of implementations avoid lazy running Hydra fully supports it).

In its simplest case you may want to get notified when your async operation resolves successfully (with the object instance you are expecting for) or fail with an error.
This can be done attaching `.then` & `.catch` operators:

```swift
Promise<Int>(in: .background, { resolve, reject in
	// your async code
	// to settle the promise and mark it as finished you need
	// to call resolve() or reject() along with the object
}).then { value in
	// we get our expected Int value here
}.catch { error in
  // we get the reason of failure
}
```

This promise is defined with `Int` as expected result. It also execute the body of the promise in `.background` GCD queue. Both `.then` and `.catch` closures are executed in `.main` thread because does not specify a custom context as parameter.

But how it works?
This is a snippet of the Promise class in Hydra:

```swift
public class Promise<Value> {
	internal var state: State<Value> = .pending
	internal let stateQueue = DispatchQueue(label: "com.mokasw.promise")
	private var body: Body?
	private(set) var context: Context = Context.custom(queue: DispatchQueue.global(qos: .background))
	private var observers: [Observer<Value>] = []
	internal var bodyCalled: Bool = false
	
	public init(in context: Context? = nil, _ body: @escaping Body) {
		self.state = .pending
		self.context = context ?? Context.custom(queue: DispatchQueue.global(qos: .background))
		self.body = body
	}
}
```

As you can see we define the following properties:

- `state`: define the current state of the Promise; it's basically an enum with the following cases: `resolved(_: Value)`, `rejected(_: Error)` and `.pending` (the state also encapsulate the result  of the operation).
- `stateQueue`: this is a GCD internal queue used to keep Promise class thread safe: as we said Promise cannot change from a settled state. Any change to `state` property must be done synchronously and this queue is used to ensure this binding.
- `body`: this is a reference to the closure with the async code we want to execute.
- `context`: GCD queue in which the `body` will be executed.
- `observers`: this is an array of registered closures used to receive notifications about any change in Promise's current state. `Observer<Value>` is an enum with two types: first is used to get notification about fulfill events (`.onResolve(ctx: Context, body: (Value -> Void))`); the other is used for rejection (`.onReject(ctx: Context, (Error -> Void))`). Operators register obsever to get notified about promise's events; each observer's body is executed into specified context.
- `bodyCalled`: we need to ensure Promise's `body` is called once and once time only. As with `state`, also this property is set synchronously using `stateQueue`.

The signature of the `body` exposes two input arguments (`... { resolve, reject in `); when async code return a value or throws an error it must be signal it to the parent Promise by calling one of these functions: once done promise did change the internal state and call any related registered observer (ie. if fulfilled only `.onResolve` observer will be called).

This is the snippet of code which is responsible to execute the body of the promise:

```swift
internal func runBody() {
		self.stateQueue.sync {
			if state.isPending == false || bodyCalled == true {
				return
			}
			bodyCalled = true
			
			self.context.queue.async {
				do {
					// body can throws and fail. throwing a promise's body is equal to
					// reject it with the same error.
					try self.body?( { value in
						self.set(state: .resolved(value)) // resolved
					}, { err in
						self.set(state: .rejected(err)) // rejected
					})
				} catch let err {
					self.set(state: .rejected(err)) // rejected (using throw)
				}
			}
		}
	}
```

As we said `runBody()` can be executed one time only (and only if the promise is pending): we can ensure it using the `stateQueue`'s `sync` call.
Just after that we can asynchronously call the `body`; as you can see it's encapsulated in a `do/try` statement: this because the body closure is throwable; this is not required but it's a nice addition used to reject a promise without calling `reject` func but in a more Swifty way.

`body`'s closure ends with a `resolve(value: Value)` or `reject(err: Error)`; based upon the result the Promise itself change its state to `.resolved` or `.rejected` via `self.set(state:)` func.
This is how `self.set(state:)` is implemented:

```swift
private func set(state newState: State<Value>) {
		self.stateQueue.sync {
			guard self.state.isPending else {
				return
			}
			self.state = newState // change state
			
			self.observers.forEach { observer in
				switch (state, observer) {
				case (.resolved(let value), .onResolve(_,_)):
					observer.call(andResolve: value)
				case (.rejected(let error), .onReject(_,_)):
					observer.call(andReject: error)
				default:
					break
				}
			}
		}
	}
```

As we said Promise's state change event must be executed synchronously and only if current state is `pending`.
The next step after setting the `state` is to iterate over all interested observer and notify them about the good news.

The same iteration must be done also after a new observer is added to the queue (it's implemented in the same way so we don't look at it here).
This is the basic architecture of the Promise: in the next chapter we'll look about how some interested operators are implemented.

[Index](#top)

<a name="operators"/>
## Inside (some) operators
It's time to look at how the operators are implemented. For obvious reasons we cannot see all the operators available in Hydra but only a specified interesting subset (you can however get a deep look at the code because it's pretty well documented).

Before starting these are two important definitions:

- `sourcePromise` is the promise on the left of an operator
- `nextPromise` is the promise returned by the operator as the result of its transformation (if any).

[Index](#top)

<a name="then"/>
### `.then()`
In its simplest form `then` is used to resolve a chain and get the value if it fullfill: it simply defines a closure you can execute for this event but not transformations of the Promise's output are allowed.
Get a look at implementation:

```swift
@discardableResult
	public func then(in context: Context? = nil, _ body: @escaping ( (Value) throws -> () ) ) -> Promise<Value> {
		let ctx = context ?? .background
		let nextPromise = Promise<Value>(in: ctx, { resolve, reject in
			let onResolve = Observer<Value>.onResolve(ctx, { value in
				do {
					try body(value)
					resolve(value)
				} catch let error {
					reject(error)
				}
			})
			
			let onReject = Observer<Value>.onReject(ctx, reject)
			self.add(observers: onResolve, onReject)
		})
		nextPromise.runBody()
		self.runBody()
		return nextPromise
	}
```

As you can see the behaviour is pretty straightforward.
`nextPromise` is returned as the output and it has the same type of `sourcePromise`.

First of all we need to watch the result of `sourcePromise` inside `nextPromise`: this is done by calling `nextPromise.runBody()` and adding observers via `self.add(...)`).

The next step is to resolve `sourcePromise` (by calling `self.runBody()`):

- if successful, `body` is executed and it may have the opportunity to reject the chain or accept it (this is the reason for throwable `body`).
- If fail, `body` is skipped and the error is simply forwarded to the `nextPromise`.

`@discardableResult` in signature is necessary to silent the compiler while you can safely ignore `nextPromise` as output of the operator.
`context` parameter is optional and if not specified we'll use the `main thread` to execute the `body`.

[Index](#top)

### `then()` to chain with another promise by passing its first argument

Another use of `then` is to resolve `sourcePromise` with a value, then pass it as first argument of another promise.
Basically it allows you to do:

(`myAsyncFunc1().then(myAsyncFunc2)`).

Implementation is pretty similar to the previous one: the big difference is inside the `onResolve` observer. In this case we expect a Promise as output for `body`; `chainedPromise` must be also resolved by passing the value obtained by `sourcePromise` as argument while the final result will be forwarded to the `nextPromise`.
According to it the output of this operator is Promise which takes the result of `sourcePromise`, (optionally) transform it to another type and execute another promise defined into the `body`.

```swift
let onResolve = Observer<Value>.onResolve(ctx, { value in
	do {
		let chainedPromise = try body(value)
		let pResolve = Observer<N>.onResolve(ctx, resolve)
		let pReject = Observer<N>.onReject(ctx, reject)
		chainedPromise.add(observers: pResolve,pReject)
		chainedPromise.runBody()
	} catch let error {
		reject(error)
	}
})
```

[Index](#top)

<a name="catch"/>
### `catch()`
`catch` is another fundamental operator: it's used to handle the rejection of a `sourcePromise`.
Take a look at the implmentation:

```swift
@discardableResult
public func `catch`(in context: Context? = nil, _ body: @escaping ((Error) throws -> (Void))) -> Promise<Void> {
	let ctx = context ?? .main
	let nextPromise = Promise<Void>(in: ctx) { resolve, reject in
	let onResolve = Observer<Value>.onResolve(ctx, { _ in
		resolve(())
	})
	let onReject = Observer<Value>.onReject(ctx, { error in
		do {
			try body(error)
		} catch let error {
			reject(error)
		}
		resolve(())
	})
	self.add(observers: onResolve,onReject)
}
nextPromise.runBody()
self.runBody()
return nextPromise
}
```

Concept is very similar to `then` but in this case we are interested in in handling the rejected state.
While `onResolve` implementation simply forward the result to the `nextPromise` and along the chain, `onReject` must execute `catch`'s `body`; as like we've seen with `then` even this may reject the chain (in fact it's not a real reject because the chain was already rejected, we can call it a change in output error).

[Index](#top)

<a name="retry"/>
### `retry()`
`retry` allows you to repeat a failed promise for a number of specified attempts; you can, for example, use it to repeat network connection attempts or failable operations.
The implementation of this operator introduce a dirty secret: at the beginning we have said which a settled Promise cannot be unsettled; however, in order to make a coincise implementation we have added an internal method which allows us to reset the state of a Promise and re-execute it.

`resetState()` scope is to set the state to `pending` state and allows `runBody()` to be executed once time again. Both these operation must be done by preserving thread-safe binding, so we will encapsulate it in a sync session of `stateQueue`.

```swift
internal func resetState() {
	self.stateQueue.sync {
		self.bodyCalled = false
		self.state = .pending
	}
}
```

```swift
public func retry(_ attempts: Int = 3) -> Promise<Value> {
	guard attempts >= 1 else {
		return Promise<Value>(rejected: PromiseError.invalidInput)
	}
	var remainingAttempts = attempts
	let nextPromise = Promise<Value>(in: self.context) { (resolve, reject) in
	let onResolve = Observer<Value>.onResolve(self.context, resolve)
	let onReject = Observer<Value>.onReject(self.context, { error in
		remainingAttempts -= 1
		guard remainingAttempts >= 0 else {
			reject(error)
			return
		}
		self.resetState()
		self.runBody()
	})
	self.add(observers: onResolve,onReject)
		self.runBody()
	}
	nextPromise.runBody()
	return nextPromise
}
```

`retry` accepts an `Int` as number of attempts in case `sourcePromise` fails. The key point here is to observe the rejection event; once rejected we need to decrement the number of `remainingAttempts`; if value reaches zero we will forward the rejection along with the last occurred error to `nextPromise` and from that all along the chain.
If another attempt is possible `sourcePromise` will be resetted (`resetState`) and re-executed (`runBody`).

[Index](#top)

<a name="all"/>
### `all()`
Another interesting operator is `all`; using `all` you can execute a sequence of promises and get the final results along with the ordered array of fulfilled values.
All the promises will be executed in parallel and if one of them fails the entire chain also fail.

```swift
func all<L, S: Sequence>(_ promises: S) -> Promise<[L]> where S.Iterator.Element == Promise<L> {
	guard Array(promises).count > 0 else {
		return Promise<[L]>(resolved: []);
	}
	let allPromise = Promise<[L]> { (resolve, reject) in
		var countRemaining = Array(promises).count
		let allPromiseContext = Context.custom(queue: DispatchQueue(label: "com.hydra.queue.all"))
		
		for currentPromise in promises {
			currentPromise.add(in: allPromiseContext, onResolve: { value in
				countRemaining -= 1
				if countRemaining == 0 {
					let allResults = promises.map({ return $0.state.value! })
					resolve(allResults)
				}
			}, onReject: { err in
				reject(err)
			})
			currentPromise.runBody()
		}
	}
	return allPromise
}
```

By default all promises will be executed in a background parallel queue (`allPromiseContext`); output of the operator is a promise - called `allPromise` - which will be resolved when all input promises succeded or at least one fails.
`allPromise` has as output an array which, once resolved, contains a list of resolved values in the same order of the input promises.

The first step is to iterate over all promises and register for each an observer for success and failure (done using `currentPromise.add(in:onResolve:onReject:)`).

If `currentPromise` fail we want to abort the entire chain and forward the error by calling `reject(err)`; thanks to the nature of Promise is sufficient to abort the entire chain (even if, at least for now, we don't support cancel of a running promise).
If `currentPromise` resolves we decrement the number of remaining promises; if all promises are settled we use a simple `map` operator to get the result of all promises and resolve `allPromise` with that array.

[Index](#top)

<a name="map"/>
### `map()`
`map` operator transform an array of objects into Promises and execute them; execution could be parallel or serial; it resolves when all promises resolves, fail if at least one promise fail. As you can easily guess parallel behaviour is pretty similar to `all` and, in fact, I've implemented it with it:

```swift
internal func map_parallel<A, B, S: Sequence>(context: Context, items: S, transform: @escaping (A) throws -> Promise<B>) -> Promise<[B]> where S.Iterator.Element == A {
	let transformPromise = Promise<Void>(resolved: ())
	return transformPromise.then(in: context) { (Void) -> Promise<[B]> in
		do {
			let mappedPromises: [Promise<B>] = try items.map({ item in
				return try transform(item)
			})
			return all(mappedPromises)
		} catch let error {
			return Promise<[B]>(rejected: error)
		}
	}
}
```

First of all, as output of the `map` we return a `transformPromise` which will be resolved when all input promises are fulfilled.

Using standard Swift's `map` function we iterate over all input items and call `transform`; as output from this closure we expect a Promise (which, at least ideally, it's based upon the input item).
At the end of the map we got `mappedPromise`, an array of Promises we can resolve using `all` operator which also resolve the `transformPromise`.

Serial version is easier to implement:

```swift
public func map_series<A, B, S: Sequence>(context: Context, items: S, transform: @escaping (A) throws -> Promise<B>) -> Promise<[B]> where S.Iterator.Element == A {
	let initial = Promise<[B]>(resolved: [])
	
	return items.reduce(initial) { chain, item in
		return chain.then(in: context) { results in
			try transform(item).then(in: context) { results + [$0] }
		}
	}
}
```

...
...
[Index](#top)

<a name="await"/>
## `await`
The last operator which worth to analyze is `await`. Using `await` you can write async code in a sync manner:

```swift
do {
	let result = await { asyncFunc1() }
	let result2 = await { asyncFunc1(result) }
} catch {
	// handle error
}
```

Due to its closer relationship with GCD queue it's natural to express `await` as extension of `Context`.

If we want any execution to wait or pause until a block of code finishes its execution and frees up the resources, the most logical way to do it is using GCD's dispatch semaphores. A dispatch semaphore works same as regular semaphore. Only one exception is, it takes a lesser amount of time to obtain a dispatch semaphore than it takes with traditional system semaphore when resources are available.

A detailed article about this topic can be [found here](http://www.technetexperts.com/mobile/how-to-pause-or-wait-execution-until-block-executes-with-semaphore-in-ios/) (if you are interested in semaphore theory check out [this article](http://greenteapress.com/semaphores/)).

```swift
public extension Context {

	internal func await<T>(_ promise: Promise<T>) throws -> T {
		guard self.queue != DispatchQueue.main else {
			throw PromiseError.invalidContext
		}
		
		var result: T?
		var error: Error?		
		let semaphore = DispatchSemaphore(value: 0)
		
		promise.then(in: self) { value -> Void in
			result = value
			semaphore.signal()
		}.catch(in: self) { err in
			error = err
			semaphore.signal()
		}
	
		_ = semaphore.wait(timeout: DispatchTime(uptimeNanoseconds: UINT64_MAX))
		
		guard let promiseValue = result else {
			throw error!
		}
		return promiseValue
	}
}
```

The flow is:

- create a new semaphore with one resource available
- start resolving the promise
- decrement semaphore via `wait`: with a negative value system block the execution of the queue until `signal`.
- once the promise is settled (in another queue) result or error is saved and a `signal` is sent to the await queue
- await queue resumes and the value is reported as output (if it's an error a throw is sent)

[Index](#top)