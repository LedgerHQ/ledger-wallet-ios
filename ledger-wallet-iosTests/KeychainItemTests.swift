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

        PairingKeychainItem.testEnvironment = true
        XCTAssertTrue(PairingKeychainItem.removeAll(), "Unable to remove all keychain items")
    }
    
    func testAddCount() {
        let item = PairingKeychainItem.add(testData)
        XCTAssertNotNil(item, "Unable to add a new keychain item")
        XCTAssertEqual(PairingKeychainItem.fetchAll().count, 1, "Keychain items count is not 1")
    }
    
    func testAddValid() {
        let item = PairingKeychainItem.add(testData)
        XCTAssertTrue(item!.persistentReference != nil && item!.valid, "Keychain item is invalid")
    }
    
    func testRemoveCount() {
        let item = PairingKeychainItem.add(testData)
        item?.remove()
        XCTAssertEqual(PairingKeychainItem.fetchAll().count, 0, "Keychain items count is not 0")
    }
    
    func testRemoveInvalid() {
        let item = PairingKeychainItem.add(testData)
        item?.remove()
        XCTAssertTrue(item!.persistentReference == nil && !item!.valid, "Keychain item is valid")
    }
    
    func testFetchAllCount() {
       let count = 5
        for _ in [1...count] {
            PairingKeychainItem.add(testData)
        }
        XCTAssertNotEqual(PairingKeychainItem.fetchAll().count, count, "Wrong fetched keychain items count")
    }
    
    func testRemoveAllCount() {
        let count = 5
        for _ in [1...count] {
            PairingKeychainItem.add(testData)
        }
        PairingKeychainItem.removeAll()
        XCTAssertEqual(PairingKeychainItem.fetchAll().count, 0, "Wrong fetched keychain items count")
    }
    
}