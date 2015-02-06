//
//  WebSocketTests.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 07/01/2015.
//  Copyright (c) 2015 Ledger. All rights reserved.
//

import XCTest

class WebSocketTests: XCTestCase, JFRWebSocketDelegate {
    
    var websocket: JFRWebSocket!
    var connectExpectation: XCTestExpectation!
    var disconnectExpectation: XCTestExpectation!
    
    var message: String!
    var expectation: XCTestExpectation!
    
    override func setUp() {
        super.setUp()
        if let url = NSURL(string: "ws://echo.websocket.org") {
            websocket = JFRWebSocket(URL: url, protocols: nil)
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
    
    func websocketDidConnect(socket: JFRWebSocket!) {
        connectExpectation.fulfill()
    }
    
    func websocketDidDisconnect(socket: JFRWebSocket!, error: NSError!) {
        disconnectExpectation.fulfill()
    }
    
    func websocket(socket: JFRWebSocket!, didReceiveMessage string: String!) {
        XCTAssert(string == message, "echo mismatch")
        expectation.fulfill()
    }

    func testEcho() {
        expectation = expectationWithDescription("test echo")
        message = "this is an echo test"
        websocket.writeString(message)
        waitForExpectationsWithTimeout(10.0, nil)
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
