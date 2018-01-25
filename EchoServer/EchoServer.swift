//
//  EchoServer.swift
//  Echo
//
//  Created by Bradley Bell on 1/25/18.
//  Copyright © 2018 bradleyb.org. All rights reserved.
//

import Foundation
import CocoaAsyncSocket

class EchoServer: NSObject, GCDAsyncSocketDelegate {
	let WELCOME_MSG = 0
	let ECHO_MSG = 1
	let WARNING_MSG = 2
	
	let READ_TIMEOUT = 15.0
	let READ_TIMEOUT_EXTENSION = 10.0
	
	let socketQueue = DispatchQueue(label: "socketQueue")

	var listenSocket: GCDAsyncSocket!

	var connectedSockets: [GCDAsyncSocket] = []
	let connectedSocketsSync = DispatchQueue(label: "connectedSocketsSync")
	
	var isRunning: Bool = false
	
	var view: ViewController!

	init(_ view: ViewController) {
		super.init()
		
		self.view = view
		
		listenSocket = GCDAsyncSocket(delegate: self, delegateQueue: socketQueue)

		connectedSocketsSync.sync {
			connectedSockets = []
		}
	}
	
	func startStop() {
		if !isRunning {
			
			let port = UInt16(view.portField.text ?? "0") ?? 0
			if port == 0 {
				view.portField.text = ""
			}

			do {
				try listenSocket.accept(onPort: port)
			} catch {
				view.logError(String(format: "Error starting server: %@", error.localizedDescription))
				return
			}

			view.logInfo(String(format: "Echo server started on port %hu", listenSocket.localPort))
			isRunning = true

			view.portField.isEnabled = false
			view.startStopButton.setTitle("Stop", for: .normal)
			
		} else {
		
			// Stop accepting connections
			listenSocket.disconnect()
			
			// Stop any client connections
			connectedSocketsSync.sync {
				for socket in connectedSockets {
					// Call disconnect on the socket,
					// which will invoke the socketDidDisconnect: method,
					// which will remove the socket from the list.
					socket.disconnect()
				}
			}

			view.logInfo("Stopped Echo server")
			isRunning = false

			view.portField.isEnabled = true
			view.startStopButton.setTitle("Start", for: .normal)
		}
	}

	func socket(_ sock: GCDAsyncSocket, didAcceptNewSocket newSocket: GCDAsyncSocket) {
		// This method is executed on the socketQueue (not the main thread)
		
		connectedSocketsSync.sync {
			connectedSockets.append(newSocket)
		}

		let host = newSocket.connectedHost ?? "<undefined>"
		let port = newSocket.connectedPort
		
		DispatchQueue.main.async {
			self.view.logInfo(String(format: "Accepted client %@:%hu", host, port))
		}
		
		let welcomeMsg = "Welcome to the AsyncSocket Echo Server\r\n"
		let welcomeData = welcomeMsg.data(using: .utf8)!
		
		newSocket.write(welcomeData, withTimeout: -1, tag: WELCOME_MSG)
		
		newSocket.readData(to: GCDAsyncSocket.crlfData(), withTimeout: READ_TIMEOUT, tag: 0)
	}

	func socket(_ sock: GCDAsyncSocket, didWriteDataWithTag tag: Int) {
		// This method is executed on the socketQueue (not the main thread)
		
		if (tag == ECHO_MSG) {
			sock.readData(to: GCDAsyncSocket.crlfData(), withTimeout: READ_TIMEOUT, tag: 0)
		}
	}
	
	func socket(_ sock: GCDAsyncSocket, didRead data: Data, withTag tag: Int) {
		// This method is executed on the socketQueue (not the main thread)

		DispatchQueue.main.async {
			let strData = data[0 ..< data.count - 2]
			let msg = String(data: strData, encoding: .utf8)
			if msg != nil {
				self.view.logMessage(msg!)
			} else {
				self.view.logError("Error converting received data into UTF-8 String")
			}
			
		}
		
		// Echo message back to client
		sock.write(data, withTimeout: -1, tag: ECHO_MSG)
	}
	
	/**
	* This method is called if a read has timed out.
	* It allows us to optionally extend the timeout.
	* We use this method to issue a warning to the user prior to disconnecting them.
	**/
	func socket(_ sock: GCDAsyncSocket, shouldTimeoutReadWithTag tag: Int, elapsed: TimeInterval, bytesDone length: UInt) -> TimeInterval {
		if elapsed <= READ_TIMEOUT {
			let warningMsg = "Are you still there?\r\n"
			let warningData = warningMsg.data(using: .utf8)!
			
			sock.write(warningData, withTimeout: -1, tag: WARNING_MSG)
			
			return READ_TIMEOUT_EXTENSION
		}
		
		return 0.0
	}
	
	func socketDidDisconnect(_ sock: GCDAsyncSocket, withError err: Error?) {
		if sock != listenSocket {
			DispatchQueue.main.async {
				self.view.logInfo("Client Disconnected")
			}
			
			connectedSocketsSync.sync {
				if let index = connectedSockets.index(of: sock) {
					connectedSockets.remove(at: index)
				}
			}
		}
	}
}
