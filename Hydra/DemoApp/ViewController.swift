//
//  ViewController.swift
//  DemoApp
//
//  Created by Daniele Margutti on 05/01/2017.
//  Copyright © 2017 Daniele Margutti. All rights reserved.
//

import UIKit
import Hydra

class ViewController: UIViewController {

	override func viewDidLoad() {
		super.viewDidLoad()
		
	
		print("ciao")
		//let r = try! await(self.asyncFunc1())
		
		let w:Int = try! await(.background, { resolve,reject in
			delay(2, context: .background, closure: {
				resolve(5)
			})
		})
		
		let a: [Promise<T>] = [1,2,3].map {
			return self.asyncFunc2(value: $0)
		}
		
		print("")
		
	}
	
	func asyncFunc1() -> Promise<Int> {
		return Promise<Int> { (resolve, reject) in
			delay(2, context: .background, closure: {
				resolve(5)
			})
		}
	}
	
	func asyncFunc2(value: Int) -> Promise<Int> {
		return Promise<Int> { (resolve, reject) in
			delay(2, context: .background, closure: {
				resolve(10*value)
			})
		}
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()

	}


}


func delay(_ delay:Double, context: Context, closure:@escaping ()->()) {
	let when = DispatchTime.now() + delay
	context.queue.asyncAfter(deadline: when, execute: closure)
}
