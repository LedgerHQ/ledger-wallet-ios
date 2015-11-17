//
//  PairingProtocolContextTests.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 26/10/2015.
//  Copyright © 2015 Ledger. All rights reserved.
//

import Foundation
import XCTest
@testable import ledger_wallet_ios

class PairingProtocolContextTests: XCTestCase {
    
    let emptyKey = BTCKey()
    
    override func setUp() {
        super.setUp()
        
        XCTAssertTrue(PairingKeychainItem.destroyAll(), "Unable to remove all keychain items")
    }
    
    func testInitContext() {
        let context = PairingProtocolContext(internalKey: emptyKey)
        XCTAssertEqual(context.internalKey, emptyKey, "Internal keys should match")
        XCTAssertEqual(context.externalKey, nil, "External keys should match")
    }
    
    func testCanCreatePairingKeychainItem() {
        XCTAssertTrue(PairingProtocolContext.canCreatePairingKeychainItemNamed("This is a name"), "It should be possible to build a keychain item")
    }
    
    func testCreateItemWithoutData() {
        let context = PairingProtocolContext(internalKey: emptyKey)
        XCTAssertNil(context.createPairingKeychainItemNamed("This is a name"), "It should not be possible to build a keychain item")
    }
    
    func testCreateItemWithData() {
        let context = PairingProtocolContext(internalKey: emptyKey)
        context.pairingId = "pairing id"
        context.pairingKey = NSData()
        XCTAssertNotNil(context.createPairingKeychainItemNamed("This is a name"), "It should be possible to build a keychain item")
    }
    
    func testCannotCreatePairingKeychainItem() {
        let context = PairingProtocolContext(internalKey: emptyKey)
        context.pairingId = "pairing id"
        context.pairingKey = NSData()
        XCTAssertNotNil(context.createPairingKeychainItemNamed("This is a name"), "It should be possible to build a keychain item")
        XCTAssertFalse(PairingProtocolContext.canCreatePairingKeychainItemNamed("This is a name"), "It should not be possible to build a keychain item")
    }
    
}