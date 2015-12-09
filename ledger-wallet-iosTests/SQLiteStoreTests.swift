//
//  SQLiteStoreTests.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 09/12/2015.
//  Copyright © 2015 Ledger. All rights reserved.
//

import Foundation
import XCTest
@testable import ledger_wallet_ios

class SQLiteStoreTests: XCTestCase {
    
    func testNotOpened() {
        let store = SQLiteStore(URL: nil)
        XCTAssertFalse(store.isOpen, "Store should not be open")
    }
    
    func testOpenInMemory() {
        let store = SQLiteStore(URL: nil)
        store.open()
        XCTAssertTrue(store.isOpen, "Store should be open")
    }
    
    func testOpenWithDirectoryURL() {
        let store = SQLiteStore(URL: NSURL(fileURLWithPath: ApplicationManager.sharedInstance.libraryDirectoryPath))
        store.open()
        XCTAssertFalse(store.isOpen, "Store should not be open")
    }
    
    func testOpenWithNotFileURL() {
        let store = SQLiteStore(URL: NSURL(string: "http://www.ledger.co"))
        store.open()
        XCTAssertFalse(store.isOpen, "Store should not be open")
    }
    
    func testOpenWithFileURL() {
        let path = "/" + NSUUID().UUIDString + "/" + NSUUID().UUIDString
        let store = SQLiteStore(URL: NSURL(fileURLWithPath: ApplicationManager.sharedInstance.databasesDirectoryPath + path))
        store.open()
        XCTAssertTrue(store.isOpen, "Store should be open")
    }
    
    func testClose() {
        let store = SQLiteStore(URL: nil)
        store.close()
        XCTAssertFalse(store.isOpen, "Store should be closed")
    }
    
    func testOpenClose() {
        let store = SQLiteStore(URL: nil)
        store.open()
        store.close()
        XCTAssertFalse(store.isOpen, "Store should be closed")
    }
    
    func testPerformBlock() {
        let expectation = expectationWithDescription("Waiting for block to execute")
        let store = SQLiteStore(URL: nil)
        store.open()
        store.performBlock() { context in
            XCTAssertNotNil(context)
            expectation.fulfill()
        }
        waitForExpectationsWithTimeout(3, handler: nil)
    }
    
    func testPerformTransaction() {
        let expectation = expectationWithDescription("Waiting for block to execute")
        let store = SQLiteStore(URL: nil)
        store.open()
        store.performTransaction() { context in
            XCTAssertNotNil(context)
            expectation.fulfill()
            return true
        }
        waitForExpectationsWithTimeout(3, handler: nil)
    }
    
}