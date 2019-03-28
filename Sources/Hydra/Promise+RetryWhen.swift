/*
* Hydra
* Fullfeatured lightweight Promise & Await Library for Swift
*
* Created by:   Hiromi Motodera
* Email:        moai.motodera@gmail.com
* Twitter:      @moaible
*
* Copyright © 2017 Daniele Margutti
*
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in
* all copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
* THE SOFTWARE.
*
*/

import Foundation

public extension Promise {
    
	func retryWhen(_ attempts: Int = 3, _ condition: @escaping ((Int, Error) -> Promise<Bool>) = { _,_ in Promise<Bool>(resolved: true) }) -> Promise<Value> {
        guard attempts >= 1 else {
            // Must be a valid attempts number
            return Promise<Value>(rejected: PromiseError.invalidInput)
        }
        
        var innerPromise: Promise<Value>? = nil
        var remainingAttempts = attempts
        // We'll create a next promise which will be resolved when attempts to resolve self (source promise)
        // is reached (with a fulfill or a rejection).
        let nextPromise = Promise<Value>(in: self.context, token: self.invalidationToken) { (resolve, reject, operation) in
            innerPromise = self.recover(in: self.context) { [unowned self] (error) -> (Promise<Value>) in
                // If promise is rejected we'll decrement the attempts counter
                remainingAttempts -= 1
                guard remainingAttempts >= 1 else {
                    // if the max number of attempts is reached
                    // we will end nextPromise with the last seen error
                    throw error
                }
                return Promise<Value> { resolve, reject, _ in
                    condition (remainingAttempts, error).then(in: self.context) { (shouldRetry) in
                        guard shouldRetry else {
                            reject(error)
                            return
                        }
                        // Reset the state of the promise
                        // (okay it's true, a Promise cannot change state as you know...this
                        // is a bit trick which will remain absolutely internal to the library itself)
                        self.resetState()
                        // Re-execute the body of the source promise to re-execute the async operation
                        self.runBody()
                        self.retryWhen(remainingAttempts, condition).then(in: self.context) { (result) in
                            resolve(result)
                        }.catch { (retriedError) in
                            reject(retriedError)
                        }
                    }.catch { (_) in
                        // reject soruce promise error
                        reject(error)
                    }
                }
            }
            // If promise resolves nothing else to do, resolve the nextPromise!
            let onResolve = Observer.onResolve(self.context, resolve)
            let onReject = Observer.onReject(self.context, reject)
            let onCancel = Observer.onCancel(self.context, operation.cancel)
            
            // Observe changes from source promise
            innerPromise?.add(observers: onResolve, onReject, onCancel)
            innerPromise?.runBody()
        }
        nextPromise.runBody()
        return nextPromise
    }
}
