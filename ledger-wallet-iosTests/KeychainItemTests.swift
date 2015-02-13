//
//  KeychainItemTests.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 26/01/2015.
//  Copyright (c) 2015 Ledger. All rights reserved.
//

import XCTest

class KeychainItemTests: XCTestCase {
    
    let testString = "this is a test"
    var testData: NSData {
        return testString.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)!
    }
    
    override func setUp() {
        super.setUp()

        KeychainItem.testEnvironment = true
        XCTAssertTrue(KeychainItem.destroyAll(), "Unable to remove all keychain items")
    }
    
    func testAddCount() {
        let item = KeychainItem.create()
        XCTAssertEqual(KeychainItem.fetchAll().count, 1, "Keychain items count is not 1")
    }
    
    func testAddValid() {
        let item = KeychainItem.create()
        XCTAssertTrue(item.isValid, "Keychain item is invalid")
    }
    
    func testRemoveCount() {
        let item = KeychainItem.create()
        item.destroy()
        XCTAssertEqual(KeychainItem.fetchAll().count, 0, "Keychain items count is not 0")
    }
    
    func testRemoveInvalid() {
        let item = KeychainItem.create()
        item.destroy()
        XCTAssertTrue(!item.isValid, "Keychain item is valid")
    }
    
    func testFetchAllCount() {
       let count = 5
        for _ in [1...count] {
            KeychainItem.create()
        }
        XCTAssertNotEqual(KeychainItem.fetchAll().count, count, "Wrong fetched keychain items count")
    }
    
    func testRemoveAllCount() {
        let count = 5
        for _ in [1...count] {
            KeychainItem.create()
        }
        KeychainItem.destroyAll()
        XCTAssertEqual(KeychainItem.fetchAll().count, 0, "Wrong fetched keychain items count")
    }
    
    func testNilData() {
        let item = KeychainItem.create()
        XCTAssertNil(item.valueForKey("test"), "Data is not nil")
    }

    func testRealData() {
        let item = KeychainItem.create()
        item.setValue("Hello", forKey: "test")
        XCTAssertNotNil(item.valueForKey("test"), "Data is nil")
        XCTAssertEqual(item.valueForKey("test")!, "Hello", "Data is not equal")
    }
    
    func testSaveThenFetch() {
        let item = KeychainItem.create()
        item.setValue("Hello", forKey: "test")
        let fetchItem = KeychainItem.fetchAll()[0]
        XCTAssertNotNil(fetchItem.valueForKey("test"), "Data is nil")
        XCTAssertEqual(fetchItem.valueForKey("test")!, "Hello", "Data is not equal")
    }
    
    func testRemoveNil() {
        let item = KeychainItem.create()
        item.setValue("Hello", forKey: "test")
        item.setValue(nil, forKey: "test")
        XCTAssertNil(item.valueForKey("test"), "Data is not nil")
    }
    
    func testRemoveData() {
        let item = KeychainItem.create()
        item.setValue("Hello", forKey: "test")
        item.removeValueForKey("test")
        XCTAssertNil(item.valueForKey("test"), "Data is not nil")
    }
    
    func testDataCount() {
        let item = KeychainItem.create()
        item.setValue("Hello", forKey: "test")
        item.setValue("Hello", forKey: "test")
        item.setValue("Hi!", forKey: "test2")
        item.removeValueForKey("test")
        XCTAssertEqual(item.count, 1, "Count is not 1")
    }
    
}