//
//  PreferencesTests.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 25/09/15.
//  Copyright © 2015 Ledger. All rights reserved.
//

import Foundation
import XCTest

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
    
}