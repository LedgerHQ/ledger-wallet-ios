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
        XCTAssertTrue(KeychainItem.removeAll(), "Unable to remove all keychain items")
    }
    
    func testAddCount() {
        let item = KeychainItem.add(testData)
        XCTAssertNotNil(item, "Unable to add a new keychain item")
        XCTAssertEqual(KeychainItem.fetchAll().count, 1, "Keychain items count is not 1")
    }
    
    func testAddValid() {
        let item = KeychainItem.add(testData)
        XCTAssertTrue(item!.persistentReference != nil && item!.valid, "Keychain item is invalid")
    }
    
    func testRemoveCount() {
        let item = KeychainItem.add(testData)
        item?.remove()
        XCTAssertEqual(KeychainItem.fetchAll().count, 0, "Keychain items count is not 0")
    }
    
    func testRemoveInvalid() {
        let item = KeychainItem.add(testData)
        item?.remove()
        XCTAssertTrue(item!.persistentReference == nil && !item!.valid, "Keychain item is valid")
    }
    
    func testFetchAllCount() {
       let count = 5
        for _ in [1...count] {
            KeychainItem.add(testData)
        }
        XCTAssertNotEqual(KeychainItem.fetchAll().count, count, "Wrong fetched keychain items count")
    }
    
    func testRemoveAllCount() {
        let count = 5
        for _ in [1...count] {
            KeychainItem.add(testData)
        }
        KeychainItem.removeAll()
        XCTAssertEqual(KeychainItem.fetchAll().count, 0, "Wrong fetched keychain items count")
    }
    
    func testSameData() {
        KeychainItem.add(testData)
        let item = KeychainItem.fetchAll()[0]
        XCTAssertEqual(item.data, testData, "Data is not equal")
    }

    
}