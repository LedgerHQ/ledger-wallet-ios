//
//  KeychainItemTests.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 26/01/2015.
//  Copyright (c) 2015 Ledger. All rights reserved.
//

import XCTest
@testable import ledger_wallet_ios

class KeychainItemTests: XCTestCase {
 
    override func setUp() {
        super.setUp()

        XCTAssertTrue(GenericKeychainItem.destroyAll(), "Unable to remove all keychain items")
    }
    
    func testServiceIdentifier() {
        XCTAssertEqual(GenericKeychainItem.serviceIdentifier, "", "Keychain item should have no service identifier")
        XCTAssertEqual(GenericKeychainItem.persistentServiceIdentifier, ".test", "Persistent service identifiers should be equal")

    }
    
    func testAddCount() {
        let _ = GenericKeychainItem()
        XCTAssertEqual(GenericKeychainItem.fetchAll().count, 1, "Keychain items count is not 1")
    }
    
    func testAddValid() {
        guard let item = GenericKeychainItem() else {
            XCTFail("Unable to create keychain item")
            return
        }
        XCTAssertTrue(item.valid, "Keychain item should be valid")
    }
    
    func testRemoveCount() {
        guard let item = GenericKeychainItem() else {
            XCTFail("Unable to create keychain item")
            return
        }
        XCTAssertTrue(item.destroy(), "Destroy should succeed")
        XCTAssertEqual(GenericKeychainItem.fetchAll().count, 0, "Keychain items count is not 0")
    }
    
    func testRemoveInvalid() {
        guard let item = GenericKeychainItem() else {
            XCTFail("Unable to create keychain item")
            return
        }
        XCTAssertTrue(item.destroy(), "Destroy should succeed")
        XCTAssertTrue(!item.valid, "Keychain item should be invalid")
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
        XCTAssertTrue(GenericKeychainItem.destroyAll(), "Destroy should succeed")
        XCTAssertEqual(GenericKeychainItem.fetchAll().count, 0, "Wrong fetched keychain items count")
    }
    
    func testNilData() {
        guard let item = GenericKeychainItem() else {
            XCTFail("Unable to create keychain item")
            return
        }
        XCTAssertNil(item.valueForKey("test"), "Data is not nil")
    }

    func testRealData() {
        guard let item = GenericKeychainItem() else {
            XCTFail("Unable to create keychain item")
            return
        }
        XCTAssertTrue(item.setValue("Hello", forKey: "test"), "Setting value should succeed")
        XCTAssertNotNil(item.valueForKey("test"), "Data should not be nil")
        XCTAssertEqual(item.valueForKey("test")!, "Hello", "Data is not equal")
    }
    
    func testSaveThenFetch() {
        guard let item = GenericKeychainItem() else {
            XCTFail("Unable to create keychain item")
            return
        }
        XCTAssertTrue(item.setValue("Hello", forKey: "test"), "Setting value should succeed")
        let fetchItem = GenericKeychainItem.fetchAll()[0] as! GenericKeychainItem
        XCTAssertNotNil(fetchItem.valueForKey("test"), "Data should not be nil")
        XCTAssertEqual(fetchItem.valueForKey("test")!, "Hello", "Data is not equal")
    }
    
    func testRemoveNil() {
        guard let item = GenericKeychainItem() else {
            XCTFail("Unable to create keychain item")
            return
        }
        XCTAssertTrue(item.setValue("Hello", forKey: "test"), "Setting value should succeed")
        XCTAssertTrue(item.setValue(nil, forKey: "test"), "Setting value should succeed")
        XCTAssertNil(item.valueForKey("test"), "Data should be nil")
    }
    
    func testRemoveData() {
        guard let item = GenericKeychainItem() else {
            XCTFail("Unable to create keychain item")
            return
        }
        XCTAssertTrue(item.setValue("Hello", forKey: "test"), "Setting value should succeed")
        XCTAssertTrue(item.removeValueForKey("test"), "Removing value should succeed")
        XCTAssertNil(item.valueForKey("test"), "Data should be nil")
    }
    
    func testDataCount() {
        guard let item = GenericKeychainItem() else {
            XCTFail("Unable to create keychain item")
            return
        }
        XCTAssertTrue(item.setValue("Hello", forKey: "test"), "Setting value should succeed")
        XCTAssertTrue(item.setValue("Hello", forKey: "test"), "Setting value should succeed")
        XCTAssertTrue(item.setValue("Hi!", forKey: "test2"), "Setting value should succeed")
        XCTAssertTrue(item.removeValueForKey("test"), "Removing value should succeed")
        XCTAssertEqual(item.count, 1, "Count is not 1")
        XCTAssertTrue(item.removeValueForKey("test2"), "Removing value should succeed")
        XCTAssertEqual(item.count, 0, "Count is not 0")
    }
    
    func testSave() {
        guard let item = GenericKeychainItem() else {
            XCTFail("Unable to create keychain item")
            return
        }
        XCTAssertTrue(item.setValue("Hello", forKey: "test"), "Setting value should succeed")
        XCTAssertTrue(item.save(), "Saving value should succeed")
    }
    
    func testChangeData() {
        guard let item = GenericKeychainItem() else {
            XCTFail("Unable to create keychain item")
            return
        }
        XCTAssertTrue(item.setValue("Hello", forKey: "test"), "Setting value should succeed")
        XCTAssertTrue(item.setValue("Salut", forKey: "test"), "Setting value should succeed")
        XCTAssertEqual(item.valueForKey("test"), "Salut")
    }
    
}