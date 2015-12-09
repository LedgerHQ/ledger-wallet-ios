//
//  WalletStoreManagerTests.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 09/12/2015.
//  Copyright © 2015 Ledger. All rights reserved.
//

import Foundation
import XCTest
@testable import ledger_wallet_ios

class WalletStoreManagerTests: XCTestCase {
    
    func testAutomanageStore() {
        let expectation = expectationWithDescription("Waiting to fetch schema version")
        let store = WalletStoreManager.managedStoreAtURL(nil, uniqueIdentifier: "unique_identifier")
        store.performBlock() { context in
            let version = WalletStoreExecutor.schemaVersion(context)
            XCTAssertNotNil(version, "Version should not be nil")
            XCTAssertEqual(WalletStoreSchemas.currentVersion, version!, "Version should be equal")
            expectation.fulfill()
        }
        waitForExpectationsWithTimeout(3, handler: nil)
    }
    
    func testInstallEmptyStore() {
        let expectation = expectationWithDescription("Waiting to fetch schema version")
        let store = SQLiteStore(URL: nil)
        let manager = WalletStoreManager(store: store)
        let schema = WalletStoreSchemas.currentSchema
        store.open()
        manager.executePragmaCommands(schema)
        manager.installSchema(schema, uniqueIdentifier: "unique_identifier")
        store.performBlock() { context in
            let version = WalletStoreExecutor.schemaVersion(context)
            XCTAssertNotNil(version, "Version should not be nil")
            XCTAssertEqual(schema.version, version!, "Version should be equal")
            expectation.fulfill()
        }
        waitForExpectationsWithTimeout(3, handler: nil)
    }
    
    func testUselessMigration() {
        let expectation = expectationWithDescription("Waiting to fetch schema version")
        let store = SQLiteStore(URL: nil)
        let manager = WalletStoreManager(store: store)
        let schema = WalletStoreSchemas.currentSchema
        store.open()
        manager.executePragmaCommands(schema)
        manager.installSchema(schema, uniqueIdentifier: "unique_identifier")
        manager.migrateToSchema(schema)
        store.performBlock() { context in
            let version = WalletStoreExecutor.schemaVersion(context)
            XCTAssertNotNil(version, "Version should not be nil")
            XCTAssertEqual(schema.version, version!, "Version should be equal")
            expectation.fulfill()
        }
        waitForExpectationsWithTimeout(3, handler: nil)
    }
    
    func testEmptyMigration() {
        let expectation = expectationWithDescription("Waiting to fetch schema version")
        let store = SQLiteStore(URL: nil)
        let manager = WalletStoreManager(store: store)
        let schema = WalletStoreSchemas.currentSchema
        store.open()
        manager.executePragmaCommands(schema)
        manager.migrateToSchema(schema)
        store.performBlock() { context in
            let version = WalletStoreExecutor.schemaVersion(context)
            XCTAssertNil(version, "Version should be nil")
            expectation.fulfill()
        }
        waitForExpectationsWithTimeout(3, handler: nil)
    }
    
}
