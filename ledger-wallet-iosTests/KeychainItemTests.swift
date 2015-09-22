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

        GenericKeychainItem.testEnvironment = true
        XCTAssertTrue(GenericKeychainItem.destroyAll(), "Unable to remove all keychain items")
    }
    
    func testServiceIdentifier() {
        XCTAssertEqual(GenericKeychainItem.serviceIdentifier, "", "Keychain item should have no service identifier")
    }
    
    func testAddCount() {
        let _ = GenericKeychainItem()
        XCTAssertEqual(GenericKeychainItem.fetchAll().count, 1, "Keychain items count is not 1")
    }
    
    func testAddValid() {
        let item = GenericKeychainItem()
        XCTAssertTrue(item.valid, "Keychain item is invalid")
    }
    
    func testRemoveCount() {
        let item = GenericKeychainItem()
        item.destroy()
        XCTAssertEqual(GenericKeychainItem.fetchAll().count, 0, "Keychain items count is not 0")
    }
    
    func testRemoveInvalid() {
        let item = GenericKeychainItem()
        item.destroy()
        XCTAssertTrue(!item.valid, "Keychain item is valid")
    }
    
    func testFetchAllCount() {
       let count = 5
        for _ in [1...count] {
            let _ = GenericKeychainItem()
        }
        XCTAssertNotEqual(GenericKeychainItem.fetchAll().count, count, "Wrong fetched keychain items count")
    }
    
    func testRemoveAllCount() {
        let count = 5
        for _ in [1...count] {
            let _ = GenericKeychainItem()
        }
        GenericKeychainItem.destroyAll()
        XCTAssertEqual(GenericKeychainItem.fetchAll().count, 0, "Wrong fetched keychain items count")
    }
    
    func testNilData() {
        let item = GenericKeychainItem()
        XCTAssertNil(item.valueForKey("test"), "Data is not nil")
    }

    func testRealData() {
        let item = GenericKeychainItem()
        item.setValue("Hello", forKey: "test")
        XCTAssertNotNil(item.valueForKey("test"), "Data is nil")
        XCTAssertEqual(item.valueForKey("test")!, "Hello", "Data is not equal")
    }
    
    func testSaveThenFetch() {
        let item = GenericKeychainItem()
        item.setValue("Hello", forKey: "test")
        let fetchItem = GenericKeychainItem.fetchAll()[0] as! GenericKeychainItem
        XCTAssertNotNil(fetchItem.valueForKey("test"), "Data is nil")
        XCTAssertEqual(fetchItem.valueForKey("test")!, "Hello", "Data is not equal")
    }
    
    func testRemoveNil() {
        let item = GenericKeychainItem()
        item.setValue("Hello", forKey: "test")
        item.setValue(nil, forKey: "test")
        XCTAssertNil(item.valueForKey("test"), "Data is not nil")
    }
    
    func testRemoveData() {
        let item = GenericKeychainItem()
        item.setValue("Hello", forKey: "test")
        item.removeValueForKey("test")
        XCTAssertNil(item.valueForKey("test"), "Data is not nil")
    }
    
    func testDataCount() {
        let item = GenericKeychainItem()
        item.setValue("Hello", forKey: "test")
        item.setValue("Hello", forKey: "test")
        item.setValue("Hi!", forKey: "test2")
        item.removeValueForKey("test")
        XCTAssertEqual(item.count, 1, "Count is not 1")
    }
    
}