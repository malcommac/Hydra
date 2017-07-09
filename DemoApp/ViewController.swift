//
//  ViewController.swift
//  DemoApp
//
//  Created by dan on 07/07/2017.
//  Copyright © 2017 Hydra. All rights reserved.
//

import UIKit
import Hydra

public enum Errors: Error {
	case any
}

class ViewController: UIViewController {

	let invalidator: InvalidationToken = InvalidationToken()
	
	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view, typically from a nib.
		
		DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 6, execute: {
			self.invalidator.isCancelled = true
		})
	
		test_invalidationToken().then { totale in
			print("totale \(totale)")
		}.cancelled {
			print("annullata")
		}
	}
	
	func test_invalidationToken() -> Promise<Int> {
		return Promise<Int>(in: .main, token: self.invalidator, { (resolve, reject, op) in
			var total: Int = 0
			for i in 0..<100 {
				print("\(i)")
				if op.isCancelled == true {
					op.cancel()
					return
				}
				sleep(1)
				total += i
			}
			resolve(total)
		})
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}


}

