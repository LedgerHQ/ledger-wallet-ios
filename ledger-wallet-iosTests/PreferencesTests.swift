//
//  PreferencesTests.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 25/09/15.
//  Copyright © 2015 Ledger. All rights reserved.
//

import Foundation
import XCTest
@testable import ledger_wallet_ios

class PreferencesTests: XCTestCase {
    
    let preferencesName = "XCTest"
    
    override func setUp() {
        super.setUp()
        
        let preferences = Preferences(storeName: preferencesName)
        preferences.clear()
        print(preferences.dictionaryRepresentation())
        XCTAssertEqual(preferences.dictionaryRepresentation().count, 0, "No keys and values should be present")
    }
    
    func testIsEmpty() {
        let preferences = Preferences(storeName: preferencesName)
        XCTAssertEqual(preferences.dictionaryRepresentation().count, 0, "Preferences should be empty")
    }
    
    func testStoreName() {
        let preferences = Preferences(storeName: preferencesName)
        XCTAssertEqual(preferences.storeName, preferencesName, "Store names should be equal")
    }
    
    func testSetRetreiveInteger() {
        let preferences = Preferences(storeName: preferencesName)
        preferences.setObject(42, forKey: "key")
        XCTAssertNotNil(preferences.objectForKey("key"), "Value should be found")
        XCTAssertEqual((preferences.objectForKey("key")! as! Int), 42, "Value should be equal")
    }
    
    func testSetNotRetreiveInteger() {
        let preferences = Preferences(storeName: preferencesName)
        preferences.setObject(42, forKey: "key")
        XCTAssertNil(preferences.objectForKey("wrongkey"), "Value should be nil")
    }
    
    func testRemove() {
        let preferences = Preferences(storeName: preferencesName)
        preferences.setObject(42, forKey: "key")
        preferences.removeObjectForKey("key")
        XCTAssertNil(preferences.objectForKey("key"), "Value should be nil")
    }
    
    func testReplace() {
        let preferences = Preferences(storeName: preferencesName)
        preferences.setObject(42, forKey: "key")
        preferences.setObject(43, forKey: "key")
        XCTAssertNotNil(preferences.objectForKey("key"), "Value should be found")
        XCTAssertEqual((preferences.objectForKey("key")! as! Int), 43, "Value should be equal")
    }
    
    func testRemoveCount() {
        let preferences = Preferences(storeName: preferencesName)
        preferences.setObject(42, forKey: "key")
        preferences.removeObjectForKey("key")
        XCTAssertEqual(preferences.dictionaryRepresentation().count, 0, "No values should be returned")
    }
    
    func testAddCount() {
        let preferences = Preferences(storeName: preferencesName)
        preferences.setObject(42, forKey: "key1")
        preferences.setObject(43, forKey: "key2")
        XCTAssertEqual(preferences.dictionaryRepresentation().count, 2, "There should be 2 values")
    }
    
    func testClearCount() {
        let preferences = Preferences(storeName: preferencesName)
        preferences.setObject(42, forKey: "key1")
        preferences.setObject(43, forKey: "key2")
        preferences.clear()
        XCTAssertEqual(preferences.dictionaryRepresentation().count, 0, "No values should be returned")
    }
    
    func testDictionaryRepresentation() {
        let preferences = Preferences(storeName: preferencesName)
        preferences.setObject(42, forKey: "key1")
        preferences.setObject(43, forKey: "key2")
        XCTAssertTrue((preferences.dictionaryRepresentation() as NSDictionary).isEqualToDictionary(["\(preferences.storeName).key1": 42, "\(preferences.storeName).key2": 43]), "Values shoule be equal")
    }
    
    func testStoreRetreiveInteger() {
        let preferences = Preferences(storeName: preferencesName)
        preferences.setInteger(42, forKey: "key")
        XCTAssertEqual(preferences.integerForKey("key"), 42, "Integers should be equal")
        XCTAssertEqual(preferences.integerForKey("key1"), 0, "Integers should not equal")

    }
    
    func testStoreRetreiveFloat() {
        let preferences = Preferences(storeName: preferencesName)
        preferences.setFloat(Float(42), forKey: "key")
        XCTAssertEqual(preferences.floatForKey("key"), Float(42), "Floats should be equal")
        XCTAssertEqual(preferences.floatForKey("key1"), Float(0), "Floats should not equal")
    }
    
    func testStoreRetreiveDouble() {
        let preferences = Preferences(storeName: preferencesName)
        preferences.setDouble(42.42, forKey: "key")
        XCTAssertEqual(preferences.doubleForKey("key"), 42.42, "Doubles should be equal")
        XCTAssertEqual(preferences.doubleForKey("key1"), 0.0, "Doubles should not equal")
    }
    
    func testStoreRetreiveBool() {
        let preferences = Preferences(storeName: preferencesName)
        preferences.setBool(true, forKey: "key")
        XCTAssertEqual(preferences.boolForKey("key"), true, "Bools should be equal")
        XCTAssertEqual(preferences.boolForKey("key1"), false, "Bools should not equal")
    }
    
    func testStoreRetreiveURL() {
        let preferences = Preferences(storeName: preferencesName)
        preferences.setURL(NSURL(string: "http://www.google.fr")!, forKey: "key")
        XCTAssertEqual(preferences.URLForKey("key"), NSURL(string: "http://www.google.fr")!, "URLs should be equal")
        XCTAssertEqual(preferences.URLForKey("key1"), nil, "URLs should not equal")
    }
    
    func testStoreRetreiveString() {
        let preferences = Preferences(storeName: preferencesName)
        preferences.setObject("Ledger", forKey: "key")
        XCTAssertEqual(preferences.stringForKey("key"), "Ledger", "Strings should be equal")
        XCTAssertEqual(preferences.stringForKey("key1"), nil, "Strings should not equal")
    }
    
    func testStoreRetreiveArray() {
        let preferences = Preferences(storeName: preferencesName)
        preferences.setObject(["Ledger", "Wallet"], forKey: "key")
        XCTAssertEqual(preferences.arrayForKey("key") as! [String], ["Ledger", "Wallet"], "Arrays should be equal")
        XCTAssertNil(preferences.arrayForKey("key1"), "Array shoudl be nil")
    }
    
    func testStoreRetreiveDictionary() {
        let preferences = Preferences(storeName: preferencesName)
        preferences.setObject(["Ledger": "Wallet"], forKey: "key")
        XCTAssertEqual(preferences.dictionaryForKey("key") as! [String: String], ["Ledger": "Wallet"], "Dictionaries should be equal")
        XCTAssertNil(preferences.dictionaryForKey("key1"), "Dictionaries shoudl be nil")
    }
    
    func testStoreRetreiveData() {
        let preferences = Preferences(storeName: preferencesName)
        preferences.setObject(LedgerDongleAttestationKeyData, forKey: "key")
        XCTAssertEqual(preferences.dataForKey("key"), LedgerDongleAttestationKeyData, "Data should be equal")
        XCTAssertEqual(preferences.dataForKey("key1"), nil, "Data should not equal")
    }
    
    func testBatchUpdate() {
        let preferences = Preferences(storeName: preferencesName)
        preferences.beginBatchUpdate()
        preferences.setInteger(42, forKey: "key")
        preferences.removeObjectForKey("key")
        preferences.endBatchUpdate()
        XCTAssertEqual(preferences.integerForKey("key"), 0, "Integers should be equal")
    }
    
}