//
//  WebSocketTests.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 07/01/2015.
//  Copyright (c) 2015 Ledger. All rights reserved.
//

import XCTest
@testable import ledger_wallet_ios

class WebSocketTests: XCTestCase, WebSocketDelegate {
    
    var websocket: WebSocket!
    var connectExpectation: XCTestExpectation!
    var disconnectExpectation: XCTestExpectation!
    
    var message: String!
    var expectation: XCTestExpectation!
    
    override func setUp() {
        super.setUp()
        if let url = NSURL(string: "wss://echo.websocket.org") {
            websocket = WebSocket(url: url)
            websocket.delegate = self
            connectExpectation = expectationWithDescription("websocket connect")
            websocket.connect()
            waitForExpectationsWithTimeout(30.0, handler: { (error) -> Void in
                if (error != nil) {
                    XCTFail("Unable to connect WebSocket url (timeout)")
                }
            })
        } else {
            XCTFail("Unable to create WebSocket url (url)")
        }
    }
    
    func websocketDidConnect(socket: WebSocket) {
        connectExpectation.fulfill()
    }
    
    func websocketDidDisconnect(socket: WebSocket, error: NSError?) {
        disconnectExpectation.fulfill()
    }
    
    func websocketDidReceiveMessage(socket: WebSocket, text: String) {
        XCTAssert(text == message, "echo mismatch")
        expectation.fulfill()
    }
    
    func websocketDidReceiveData(socket: WebSocket, data: NSData) {
        
    }

    func testEcho() {
        expectation = expectationWithDescription("test echo")
        message = "this is an echo test"
        websocket.writeString(message)
        waitForExpectationsWithTimeout(10.0, handler: nil)
    }
    
    override func tearDown() {
        disconnectExpectation = expectationWithDescription("websocket disconnect")
        websocket.disconnect()
        waitForExpectationsWithTimeout(30.0, handler: { (error) -> Void in
            if (error != nil) {
                XCTFail("Unable to disconnect WebSocket url (timeout)")
            }
        })
        super.tearDown()
    }
}
