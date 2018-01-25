//
//  ViewController.swift
//  Echo
//
//  Created by Bradley Bell on 1/24/18.
//  Copyright © 2018 bradleyb.org. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

	var echo: EchoServer!
	
	//MARK: Properties
	
	@IBOutlet weak var logView: UITextView!
	@IBOutlet weak var portField: UITextField!
	@IBOutlet weak var startStopButton: UIButton!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view, typically from a nib.

		echo = EchoServer(self)
		logView.becomeFirstResponder()
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}

	func logError(_ msg: String) {
		let paragraph = String(format: "%@\n", msg)
		
		let attributes = [NSAttributedStringKey.foregroundColor: UIColor.red]
		
		let aString = NSAttributedString(string: paragraph, attributes: attributes)
		
		logView.textStorage.append(aString)
		logView.selectedRange = NSMakeRange(logView.text.count, 0) // scroll to bottom
	}
	
	func logInfo(_ msg: String) {
		let paragraph = String(format: "%@\n", msg)
		
		let attributes = [NSAttributedStringKey.foregroundColor: UIColor.purple]
		
		let aString = NSAttributedString(string: paragraph, attributes: attributes)
		
		logView.textStorage.append(aString)
		logView.selectedRange = NSMakeRange(logView.text.count, 0) // scroll to bottom
	}
	
	func logMessage(_ msg: String) {
		let paragraph = String(format: "%@\n", msg)
		
		let attributes = [NSAttributedStringKey.foregroundColor: UIColor.black]
		
		let aString = NSAttributedString(string: paragraph, attributes: attributes)
		
		logView.textStorage.append(aString)
		logView.selectedRange = NSMakeRange(logView.text.count, 0) // scroll to bottom
	}
	
	//MARK: Actions

	@IBAction func startStop(_ sender: UIButton) {
		echo.startStop()
	}
	
}

