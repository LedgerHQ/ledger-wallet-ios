//
//  WalletStoreSchemasTests.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 09/12/2015.
//  Copyright © 2015 Ledger. All rights reserved.
//

import Foundation
import XCTest
@testable import ledger_wallet_ios

class WalletStoreSchemasTests: XCTestCase {

    func testCurrentVersion() {
        let schema = WalletStoreSchemas.currentSchema
        let version = WalletStoreSchemas.currentVersion
        XCTAssertEqual(schema.version, version, "Version should be equal")
    }
    
    func testUnknownVersion() {
        let schema = WalletStoreSchemas.schemaWithVersion(0)
        XCTAssertNil(schema, "Schema should not be found")
    }
    
    func testKnownVersion() {
        let schema = WalletStoreSchemas.schemaWithVersion(1)
        XCTAssertNotNil(schema, "Schema should be found")
    }
    
}