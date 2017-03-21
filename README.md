<p align="center" >
  <img src="https://raw.githubusercontent.com/malcommac/Hydra/develop/hydra-logo.png" width=210px height=204px alt="Hydra" title="Hydra">
</p>

[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage) [![CI Status](https://travis-ci.org/malcommac/HydraAsync.svg)](https://travis-ci.org/malcommac/HydraAsync) [![Version](https://img.shields.io/cocoapods/v/HydraAsync.svg?style=flat)](http://cocoadocs.org/docsets/HydraAsync) [![License](https://img.shields.io/cocoapods/l/HydraAsync.svg?style=flat)](http://cocoadocs.org/docsets/HydraAsync) [![Platform](https://img.shields.io/cocoapods/p/HydraAsync.svg?style=flat)](http://cocoadocs.org/docsets/HydraAsync)

<p align="center" >Love your async code again with Hydra <br/>
Made with ♥ in pure Swift 3+, no dependencies, lightweight & fully portable
<p/>
<p align="center" >★★ <b>Star our github repository to help us!</b> ★★</p>
<p align="center" >Created by <a href="http://www.danielemargutti.com">Daniele Margutti</a> (<a href="http://www.twitter.com/danielemargutti">@danielemargutti</a>)</p>

# Hydra
Hydra is full-featured lightweight library which allows you to write better async code in Swift 3+. It's partially based on [JavaScript A+](https://promisesaplus.com) specs and also implements modern construct like `await` (as seen in [Async/Await specification in ES8 (ECMAScript 2017)](https://github.com/tc39/ecmascript-asyncawait) or C#) which allows you to write async code in sync manner.
Hydra supports all sexiest operators like `always`, `validate`, `timeout`, `retry`, `all`, `any`, `pass`, `recover`, `map`, `zip`, `defer` and `retry`.
Starts writing better async code with Hydra!

## Internals
A more detailed look at how Hydra works can be found in [ARCHITECTURE](https://github.com/malcommac/Hydra/blob/master/ARCHITECTURE.md) file or on [Medium](https://medium.com/@danielemargutti/hydra-promises-swift-c6319f6a6209).

## You also may like

Do you like `Hydra`? I'm also working on several other opensource libraries.

Take a look here:

* **[SwiftDate](https://github.com/malcommac/SwiftDate)** - Date & Timezone management in Swift
* **[SwiftLocation](https://github.com/malcommac/SwiftLocation)** - CoreLocation and Beacon Monitoring on steroid!
* **[SwiftRichString](https://github.com/malcommac/SwiftRichString)** - Elegant and painless attributed string in Swift
* **[SwiftScanner](https://github.com/malcommac/SwiftScanner)** - String scanner in pure Swift with full unicode support
* **[SwiftSimplify](https://github.com/malcommac/SwiftSimplify)** - Tiny high-performance Swift Polyline Simplification Library
* **[SwiftMsgPack](https://github.com/malcommac/SwiftMsgPack)** - MsgPack Encoder/Decoder in Swift

## Current Release

Latest release is: 0.9.4 [Download here](https://github.com/malcommac/Hydra/releases/tag/0.9.4).

A complete list of changes for each release is available in the [CHANGELOG](CHANGELOG.md) file.

## Index
* **[What's a Promise](#whatspromise)**
* **[Create a Promise](#createpromise)**
* **[How to use a Promise](#howtousepromise)**
* **[Chaining Multiple Promises](#chaining)**
* **[Await & Async: async code in sync manner](#awaitasync)**
* **[All Features](#allfeatures)**
	* **[always](#always)**
	* **[validate](#validate)**
	* **[timeout](#timeout)**
	* **[all](#all)**
	* **[any](#any)**
	* **[pass](#pass)**
	* **[recover](#recover)**
	* **[map](#map)**
	* **[zip](#zip)**
	* **[defer](#defer)**
	* **[retry](#retry)**
* **[Installation (CocoaPods, SwiftPM and Carthage)](#installation)**
* **[Requirements](#requirements)**
* **[Credits](#credits)**

<a name="whatspromise" />

## What's a Promise?
A Promise is a way to represent a value that will exists, or will fail with an error, at some point in the future. You can think about it as a Swift's `Optional`: it may or may not be a value. A more detailed article which explain how Hydra was implemented can be [found here](https://github.com/malcommac/Hydra/blob/master/ARCHITECTURE.md).

Each Promise is strong-typed: this mean you create it with the value's type you are expecting for and you will be sure to receive it when Promise will be resolved (the exact term is `fulfilled`).

A Promise is, in fact, a proxy object; due to the fact the system knows what success value look like, composing asynchronous operation is a trivial task; with Hydra you can:

- create a chain of dependent async operation with a single completion task and a single error handler.
- resolve many independent async operations simultaneously and get all values at the end
- retry or recover failed async operations
- write async code as you may write standard sync code
- resolve dependent async operations by passing the result of each value to the next operation, then get the final result
- avoid callbacks, pyramid of dooms and make your code cleaner!

<a name="createpromise" />

## Create a Promise
Creating a Promise is trivial; you need to specify the `context` (a GCD Queue) in which your async operations will be executed in and add your own async code as `body` of the Promise.

This is a simple async image downloader:

```swift
func getImage(url: String) -> Promise<UIImage> {
    return Promise<UIImage>(in: .background, { resolve, reject in
        self.dataTask(with: request, completionHandler: { data, response, error in
            if let error = error {
                reject(error)
            } else if let data = data, let response = response as? HTTPURLResponse {
                resolve((data, response))
            } else {
                reject("Image cannot be decoded")
            }
        }).resume()
    })
}
```

You need to remember only few things:

- a Promise is created with a type: this is the object's type you are expecting from it once fulfilled. In our case we are expecting an `UIImage` so our Promise is `Promise<UIImage>` (if a promise fail returned error must be conform to Swift's `Error` protocol)
- your async code (defined into the Promise's `body`) must alert the promise about its completion; if you have the fulfill value you will call `resolve(yourValue)`; if an error has occurred you can call `reject(occurredError)` or throw it using Swift's `throw occurredError`.
- the `context` of a Promise define the Grand Central Dispatch's queue in which the async code will be executed in; you can use one of the defined queues (`.background`,`.userInitiated` etc. [Here you can found](http://www.appcoda.com/grand-central-dispatch/) a nice tutorial about this topic)

<a name="howtousepromise" />

## How to use a Promise
Using a Promise is even easier.  
You can get the result of a promise by using `then` function; it will be called automatically when your Promise fullfill with expected value.
So:

```swift
getImage(url).then(.main, { image in
	myImageView.image = image
})
```

As you can see even `then` may specify a context (by default - if not specified - is the main thread): this represent the GCD queue in which the code of the then's block will be executed (in our case we want to update an UI control so we will need to execute it in `.main` thread).

But what happened if your Promise fail due to a network error or if the image is not decodable? `catch` func allows you to handle Promise's errors (with multiple promises you may also have a single errors entry point and reduce the complexity).

```swift
getImage(url).then(.main, { image in
	myImageView.image = image
}).catch(.main, { error in
	print("Something bad occurred: \(error)")
})
```
<a name="chaining" />

## Chaining Multiple Promises
Chaining Promises is the next step thought mastering Hydra. Suppose you have defined some Promises:

```swift
func loginUser(_ name:String, _ pwd: String)->Promise<User>
func getFollowers(user: User)->Promise<[Follower]>
func unfollow(followers: [Follower])->Promise<Int>
```

Each promise need to use the fulfilled value of the previous; plus an error in one of these should interrupt the entire chain.  
Doing it with Hydra is pretty straightforward:

```swift
loginUser(username,pass).then(getFollowers).then(unfollow).then { count in
	print("Unfollowed \(count) users")
}.catch { err in
	// Something bad occurred during these calls
}
``` 

Easy uh? (Please note: in this example context is not specified so the default `.main` is used instead).

<a name="awaitasync" />

## Await & Async: async code in sync manner
Have you ever dream to write asynchronous code like its synchronous counterpart? Hydra was heavily inspired by [Async/Await specification in ES8 (ECMAScript 2017) ](https://github.com/tc39/ecmascript-asyncawait) which provides a powerful way to write async doe in a sequential manner.

Using `async` and `await` is pretty simple.
For example the code above can be rewritten directly as:

```swift
// With `async` we have just defined a Promise which will be executed in a given
// context (if omitted `background` thread is used) and return an Int value.
let asyncFunc = async({ _ -> Int // you must specify the return of the Promise, here an Int
	// With `await` the async code is resolved in a sync manner
	let loggedUser = try await(loginUser(username,pass))
	// one promise...
	let followersList = try await(getFollowers(loggedUser))
	// after another...
	let countUnfollowed = try await(unfollow(followersList))
	// ... linearly
	// Then our async promise will be resolved with the end value
	return countUnfollowed
}).then({ value in // ... and, like a promise, the value is returned
	print("Unfollowed \(value) users")
})
```

Like magic! Your code will run in `.background` thread and you will get the result of each call only when it will be fulfilled. Async code in sync sauce!

**Important Note**: `await` is a blocking/synchronous function implemented using semaphore. Therefore, it should never be called in main thread; this is the reason we have used `async` to encapsulate it. Doing it in main thread will also block the UI.

`async` func can be used in two different options:
- it can create and return a promise (as you have seen above)
- it can be used to simply execute a block of code (as you will see below)

As we said we can also use `async` with your own block (without using promises); `async` accepts the context (a GCD queue) and optionally a start delay interval.
Below an example of the async function which will be executed without delay in background:

```swift
async({
	print("And now some intensive task...")
	let result = try! await(.background, { resolve,reject in
		delay(10, context: .background, closure: { // jut a trick for our example
			resolve(5)
		})
	})
	print("The result is \(result)")
})
```

There is also an await operator:
* **await with throw**: `..` followed by a Promise instance: this operator must be prefixed by `try` and should use `do/catch` statement in order to handle rejection of the Promise.
* **await without throw**: `..!` followed by a Promise instance: this operator does not throw exceptions; in case of promise's rejection result is nil instead.

Examples:
```swift
async({
	// AWAIT OPERATOR WITH DO/CATCH: `..`
	do {
		let result_1 = try ..asyncOperation1()
		let result_2 = try ..asyncOperation2(result_1) // result_1 is always valid
	} catch {
		// something goes bad with one of these async operations
	}
})

// AWAIT OPERATOR WITH NIL-RESULT: `..!`
async({
	let result_1 = ..!asyncOperation1() // may return nil if promise fail. does not throw!
	let result_2 = ..!asyncOperation2(result_1) // you must handle nil case manually
})
```
When you use these methods and you are doing asynchronous, be careful to do nothing in the main thread, otherwise you risk to enter in a deadlock situation.

<a name="allfeature" />

## All Features
Because promises formalize how success and failure blocks look, it's possible to build behaviors on top of them.
Hydra supports:

- `always`: allows you to specify a block which will be always executed both for `fulfill` and `reject` of the Promise
- `validate`: allows you to specify a predica block; if predicate return `false` the Promise fails.
- `timeout`: add a timeout timer to the Promise; if it does not fulfill or reject after given interval it will be marked as rejected.
- `all`: create a Promise that resolved when the list of passed Promises resolves (promises are resolved in parallel). Promise also reject as soon as a promise reject for any reason.
- `any`: create a Promise that resolves as soon as one passed from list resolves. It also reject as soon as a promise reject for any reason.
- `pass`: Perform an operation in the middle of a chain that does not affect the resolved value but may reject the chain.
- `recover`: Allows recovery of a Promise by returning another Promise if it fails.
- `map`: Transform items to Promises and resolve them (in paralle or in series)
- `zip`: Create a Promise tuple of a two promises
- `defer`: defer the execution of a Promise by a given time interval.

<a name="always" />

### always
`always` func is very useful if you want to execute code when the promise fulfills — regardless of whether it succeeds or fails.

```swift
showLoadingHUD("Logging in...")
loginUser(username,pass).then { user in
	print("Welcome \(user.username)")
}.catch { err in
 	print("Cannot login \(err)")
}.always {
 	hideLoadingHUD()
}
```
<a name="validate" />

### validate
`validate` is a func that takes a predicate, and rejects the promise chain if that predicate fails.

```swift
getAllUsersResponse().validate { httpResponse in
	guard let httpResponse.statusCode == 200 else {
		return false
	}
	return true
}.then { usersList in
	// do something
}.catch { error in
	// request failed, or the status code was != 200
}

```

<a name="timeout" />

### timeout
`timeout` allows you to attach a timeout timer to a Promise; if it does not resolve before elapsed interval it will be rejected with `.timeoutError`.

```swift
loginUser(username,pass).timeout(.main, 10, .MyCustomTimeoutError).then { user in
	// logged in
}.catch { err in
	// an error has occurred, may be `MyCustomTimeoutError
}
```

<a name="all" />

### all
`all` is a static method that waits for all the promises you give it to fulfill, and once they have, it fulfills itself with the array of all fulfilled values (in order).

If one Promise fail the chain fail with the same error.

Execution of all promises is done in parallel.

```swift
let promises = usernameList.map { return getAvatar(username: $0) }
all(promises).then { usersAvatars in
	// you will get an array of UIImage with the avatars of input
	// usernames, all in the same order of the input.
	// Download of the avatar is done in parallel in background!
}.catch { err in
	// something bad has occurred
}
```

If you add promise execution concurrency restriction to `all` operator  to avoid many usage of resource, `concurrency` option is it.

```swift
let promises = usernameList.map { return getAvatar(username: $0) }
all(promises, concurrency: 4).then { usersAvatars in
	// results of usersAvatars is same as `all` without concurrency.
}.catch { err in
	// something bad has occurred
}
```

<a name="any" />

### any
`any` easily handle race conditions: as soon as one Promise of the input list resolves the handler is called and will never be called again.

```swift
let mirror_1 = "https://mirror1.mycompany.com/file"
let mirror_2 = "https://mirror2.mycompany.com/file"

any(getFile(mirror_1), getFile(mirror_2)).then { data in
	// the first fulfilled promise also resolve the any Promise
	// handler is called exactly one time!
}
```

<a name="pass" />

### pass
`pass` is useful for performing an operation in the middle of a promise chain without changing the type of the Promise.
You may also reject the entire chain.
You can also return a Promise from the tap handler and the chain will wait for that promise to resolve (see the second `then` in the example below).

```swift
loginUser(user,pass).pass { userObj in 
	print("Fullname is \(user.fullname)")
}.then { userObj in
	updateLastActivity(userObj)
}.then { userObj in
	print("Login succeded!")
}
```
<a name="recover" />

### recover
`recover` allows you to recover a failed Promise by returning another.

```swift
let promise = Promise<Int>(in: .background, { fulfill, reject in
	reject(AnError)
}).recover({ error in
    return Promise(in: .background, { (fulfill, reject) in
		fulfill(value)
    })
})
```
<a name="map" />

### map
Map is used to transform a list of items into promises and resolve them in parallel or serially.

```swift
[urlString1,urlString2,urlString3].map {
	return self.asyncFunc2(value: $0)
}.then(.main, { dataArray in
	// get the list of all downloaded data from urls
}).catch({
	// something bad has occurred
})
```

<a name="zip" />

### zip
`zip` allows you to join different promises (2,3 or 4) and return a tuple with the result of them. Promises are resolved in parallel.

```swift
Promise<Void>.zip(a: getUserProfile(user), b: getUserAvatar(user), c: getUserFriends(user))
  .then { profile, avatar, friends in
	// ... let's do something
}.catch {
	// something bad as occurred. at least one of given promises failed
}
```

<a name="defer" />

### defer
As name said, `defer` delays the execution of a Promise chain by some number of seconds from current time.

```swift
asyncFunc1().defer(.main, 5).then...
```

### retry
`retry` operator allows you to execute source chained promise if it ends with a rejection.
If reached the attempts the promise still rejected chained promise is also rejected along with the same source error.

```swift
// try to execute myAsyncFunc(); if it fails the operator try two other times
// If there is not luck for you the promise itself fails with the last catched error.
myAsyncFunc(param).retry(3).then { value in
	print("Value \(value) got at attempt #\(currentAttempt)")
}.catch { err in
	print("Failed to get a value after \(currentAttempt) attempts with error: \(err)")
}
```

Conditional retry allows you to control retryable if it ends with a rejection.

```swift
// If myAsyncFunc() fails the operator execute the condition block to check retryable.
// If return false in condition block, promise state rejected with last catched error.
myAsyncFunc(param).retry(3) { (remainAttempts, error) -> Bool in
  return error.isRetryable
}.then { value in
	print("Value \(value) got at attempt #\(currentAttempt)")
}.catch { err in
	print("Failed to get a value after \(currentAttempt) attempts with error: \(err)")
}
```

<a name="installation" />

## Installation
You can install Swiftline using CocoaPods, carthage and Swift package manager

### CocoaPods
    use_frameworks!
    pod 'HydraAsync'

### Carthage
    github 'malcommac/Hydra'

### Swift Package Manager
Add swiftline as dependency in your `Package.swift`

```
  import PackageDescription

  let package = Package(name: "YourPackage",
    dependencies: [
      .Package(url: "https://github.com/malcommac/Hydra.git", majorVersion: 0),
    ]
  )
```

<a name="requirements" />

## Requirements

Current version is compatible with:

* Swift 3.0+
* iOS 8.0 or later
* tvOS 9.0 or later
* macOS 10.10 or later
* watchOS 2.0 or later
* Linux compatible environments

<a name="credits" />

## Credits & License
Hydra is owned and maintained by [Daniele Margutti](http://www.danielemargutti.com/).

As open source creation any help is welcome!

The code of this library is licensed under MIT License; you can use it in commercial products without any limitation.

The only requirement is to add a line in your Credits/About section with the text below:

```
This software uses open source Hydra's library to manage async code.
Web: http://github.com/malcommac/Hydra
Created by Daniele Margutti and licensed under MIT License.
```
