//
//  WalletStoreProxyTests.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 09/12/2015.
//  Copyright © 2015 Ledger. All rights reserved.
//

import Foundation
import XCTest
@testable import ledger_wallet_ios

class WalletStoreProxyTests: XCTestCase {
    
    private var storeProxy: WalletStoreProxy!
    
    override func setUp() {
        super.setUp()
        let store = WalletStoreManager.managedStoreAtURL(nil, uniqueIdentifier: "unique_identifier")
        storeProxy = WalletStoreProxy(store: store)
    }
    
    override func tearDown() {
        super.tearDown()
        storeProxy = nil
    }
    
    // MARK: Accounts tests
    
    func testFetchNoAccountWithIndex() {
        let expectation = expectationWithDescription("Waiting for fetch completion")
        storeProxy.fetchAccountAtIndex(0, queue: NSOperationQueue.mainQueue()) { account in
            XCTAssertNil(account, "No account should be found")
            expectation.fulfill()
        }
        waitForExpectationsWithTimeout(3, handler: nil)
    }
    
    func testAddAccount() {
        let account = WalletAccount(index: 0, extendedPublicKey: "super xpub", nextInternalIndex: 0, nextExternalIndex: 0, name: "this is a name", hidden: false, balance: 0)
        storeProxy.addAccount(account)
        
        let expectation = expectationWithDescription("Waiting for fetch completion")
        storeProxy.fetchAccountAtIndex(account.index, queue: NSOperationQueue.mainQueue()) { account in
            XCTAssertNotNil(account, "Account should be found")
            XCTAssertEqual(account!.index, 0, "Account indexes should match")
            expectation.fulfill()
        }
        waitForExpectationsWithTimeout(3, handler: nil)
    }
    
    func testAddTwiceAccount() {
        let account = WalletAccount(index: 0, extendedPublicKey: "super xpub", nextInternalIndex: 0, nextExternalIndex: 0, name: "this is a name", hidden: false, balance: 0)
        storeProxy.addAccount(account)
        storeProxy.addAccount(account)
        
        let expectation = expectationWithDescription("Waiting for fetch completion")
        storeProxy.fetchAllAccounts(NSOperationQueue.mainQueue()) { accounts in
            XCTAssertNotNil(accounts, "Accounts should be found")
            XCTAssertEqual(accounts!.count, 1, "Only one account should be found")
            expectation.fulfill()
        }
        waitForExpectationsWithTimeout(3, handler: nil)
    }
    
    func testFetchNoAllAccounts() {
        let expectation = expectationWithDescription("Waiting for fetch completion")
        storeProxy.fetchAllAccounts(NSOperationQueue.mainQueue()) { accounts in
            XCTAssertNotNil(accounts, "Accounts should be found")
            XCTAssertEqual(accounts!.count, 0, "No account should be found")
            expectation.fulfill()
        }
        waitForExpectationsWithTimeout(3, handler: nil)
    }
    
    func testFetchAllAccounts() {
        let account1 = WalletAccount(index: 0, extendedPublicKey: "super xpub 1", nextInternalIndex: 0, nextExternalIndex: 0, name: "this is a name", hidden: false, balance: 0)
        storeProxy.addAccount(account1)
        let account2 = WalletAccount(index: 1, extendedPublicKey: "super xpub 2", nextInternalIndex: 0, nextExternalIndex: 0, name: "this is a name", hidden: false, balance: 0)
        storeProxy.addAccount(account2)

        let expectation = expectationWithDescription("Waiting for fetch completion")
        storeProxy.fetchAllAccounts(NSOperationQueue.mainQueue()) { accounts in
            XCTAssertNotNil(accounts, "Accounts should be found")
            XCTAssertEqual(accounts!.count, 2, "Account should be found")
            XCTAssertEqual(accounts![0].index, 0, "Index should be 0")
            XCTAssertEqual(accounts![1].index, 1, "Index should be 1")
            expectation.fulfill()
        }
        waitForExpectationsWithTimeout(3, handler: nil)
    }
    
    func testFetchAccountsAtNoIndexes() {
        let expectation = expectationWithDescription("Waiting for fetch completion")
        storeProxy.fetchAccountsAtIndexes([], queue: NSOperationQueue.mainQueue()) { accounts in
            XCTAssertNotNil(accounts, "Accounts should be found")
            XCTAssertEqual(accounts!.count, 0, "No account should be found")
            expectation.fulfill()
        }
        waitForExpectationsWithTimeout(3, handler: nil)
    }
    
    func testFetchAccountsAtWrongIndexes() {
        let expectation = expectationWithDescription("Waiting for fetch completion")
        storeProxy.fetchAccountsAtIndexes([0, 1], queue: NSOperationQueue.mainQueue()) { accounts in
            XCTAssertNotNil(accounts, "Accounts should be found")
            XCTAssertEqual(accounts!.count, 0, "No account should be found")
            expectation.fulfill()
        }
        waitForExpectationsWithTimeout(3, handler: nil)
    }
    
    func testFetchAccountsAtIndexes() {
        let account1 = WalletAccount(index: 0, extendedPublicKey: "super xpub 1", nextInternalIndex: 0, nextExternalIndex: 0, name: "this is a name", hidden: false, balance: 0)
        storeProxy.addAccount(account1)
        let account2 = WalletAccount(index: 1, extendedPublicKey: "super xpub 2", nextInternalIndex: 0, nextExternalIndex: 0, name: "this is a name", hidden: false, balance: 0)
        storeProxy.addAccount(account2)
        
        let expectation = expectationWithDescription("Waiting for fetch completion")
        storeProxy.fetchAccountsAtIndexes([0, 1], queue: NSOperationQueue.mainQueue()) { accounts in
            XCTAssertNotNil(accounts, "Accounts should be found")
            XCTAssertEqual(accounts!.count, 2, "Account should be found")
            XCTAssertEqual(accounts![0].index, 0, "Index should be 0")
            XCTAssertEqual(accounts![1].index, 1, "Index should be 1")
            expectation.fulfill()
        }
        waitForExpectationsWithTimeout(3, handler: nil)
    }
    
    // MARK: Addresses tests
    
    func testFetchAddressesWithNoPaths() {
        let expectation = expectationWithDescription("Waiting for fetch completion")
        storeProxy.fetchAddressesAtPaths([], queue: NSOperationQueue.mainQueue()) { addresses in
            XCTAssertNotNil(addresses, "Addresses should be found")
            XCTAssertEqual(addresses!.count, 0, "No addresses should be found")
            expectation.fulfill()
        }
        waitForExpectationsWithTimeout(3, handler: nil)
    }

    
    func testFetchAddressesWithWrongPaths() {
        let paths = Array(0..<10).map({ return WalletAddressPath(accountIndex: 0, chainIndex: 0, keyIndex: $0) })
        let expectation = expectationWithDescription("Waiting for fetch completion")
        storeProxy.fetchAddressesAtPaths(paths, queue: NSOperationQueue.mainQueue()) { addresses in
            XCTAssertNotNil(addresses, "Addresses should be found")
            XCTAssertEqual(addresses!.count, 0, "No addresses should be found")
            expectation.fulfill()
        }
        waitForExpectationsWithTimeout(3, handler: nil)
    }
    
    func testAddAddressesWithoutAccount() {
        let paths = Array(0..<10).map({ return WalletAddressPath(accountIndex: 0, chainIndex: 0, keyIndex: $0) })
        let addresses = paths.map({ return WalletAddress(address: NSUUID().UUIDString, path: $0)})
        storeProxy.addAddresses(addresses)
        
        let expectation = expectationWithDescription("Waiting for fetch completion")
        storeProxy.fetchAddressesAtPaths(paths, queue: NSOperationQueue.mainQueue()) { addresses in
            XCTAssertNotNil(addresses, "Addresses should be found")
            XCTAssertEqual(addresses!.count, 0, "No address should be found")
            expectation.fulfill()
        }
        waitForExpectationsWithTimeout(3, handler: nil)
    }
    
    func testAddAddressesWithAccount() {
        let account = WalletAccount(index: 0, extendedPublicKey: "super xpub", nextInternalIndex: 0, nextExternalIndex: 0, name: "this is a name", hidden: false, balance: 0)
        storeProxy.addAccount(account)
        
        let paths = Array(0..<10).map({ return WalletAddressPath(accountIndex: 0, chainIndex: 0, keyIndex: $0) })
        let addresses = paths.map({ return WalletAddress(address: NSUUID().UUIDString, path: $0)})
        storeProxy.addAddresses(addresses)
        
        let expectation = expectationWithDescription("Waiting for fetch completion")
        storeProxy.fetchAddressesAtPaths(paths, queue: NSOperationQueue.mainQueue()) { addresses in
            XCTAssertNotNil(addresses, "Addresses should be found")
            XCTAssertEqual(addresses!.count, paths.count, "Addresses should be found")
            expectation.fulfill()
        }
        waitForExpectationsWithTimeout(3, handler: nil)
    }
    
    func testFetchAddressesWithNoAddresses() {
        let expectation = expectationWithDescription("Waiting for fetch completion")
        storeProxy.fetchAddressesWithAddresses([], queue: NSOperationQueue.mainQueue()) { addresses in
            XCTAssertNotNil(addresses, "Addresses should be found")
            XCTAssertEqual(addresses!.count, 0, "No addresses should be found")
            expectation.fulfill()
        }
        waitForExpectationsWithTimeout(3, handler: nil)
    }
    
    func testFetchAddressesWithWrongAddresses() {
        let expectation = expectationWithDescription("Waiting for fetch completion")
        storeProxy.fetchAddressesWithAddresses(["this is an address", "another address"], queue: NSOperationQueue.mainQueue()) { addresses in
            XCTAssertNotNil(addresses, "Addresses should be found")
            XCTAssertEqual(addresses!.count, 0, "No addresses should be found")
            expectation.fulfill()
        }
        waitForExpectationsWithTimeout(3, handler: nil)
    }
    
    func testFetchAddressesWithAddresses() {
        let account = WalletAccount(index: 0, extendedPublicKey: "super xpub", nextInternalIndex: 0, nextExternalIndex: 0, name: "this is a name", hidden: false, balance: 0)
        storeProxy.addAccount(account)

        let paths = Array(0..<10).map({ return WalletAddressPath(accountIndex: 0, chainIndex: 0, keyIndex: $0) })
        let addresses = paths.map({ return WalletAddress(address: $0.relativePath, path: $0)})
        storeProxy.addAddresses(addresses)
        
        let expectation = expectationWithDescription("Waiting for fetch completion")
        storeProxy.fetchAddressesWithAddresses(paths.map{ $0.relativePath }, queue: NSOperationQueue.mainQueue()) { addresses in
            XCTAssertNotNil(addresses, "Addresses should be found")
            XCTAssertEqual(addresses!.count, paths.count, "Addresses should be found")
            expectation.fulfill()
        }
        waitForExpectationsWithTimeout(3, handler: nil)
    }
    
    func testAddTwiceAddresses() {
        let account = WalletAccount(index: 0, extendedPublicKey: "super xpub", nextInternalIndex: 0, nextExternalIndex: 0, name: "this is a name", hidden: false, balance: 0)
        storeProxy.addAccount(account)

        let paths = Array(0..<10).map({ return WalletAddressPath(accountIndex: 0, chainIndex: 0, keyIndex: $0) })
        let addresses = paths.map({ return WalletAddress(address: "this is an address", path: $0)})
        storeProxy.addAddresses(addresses)
        
        let expectation = expectationWithDescription("Waiting for fetch completion")
        storeProxy.fetchAddressesAtPaths(paths, queue: NSOperationQueue.mainQueue()) { addresses in
            XCTAssertNotNil(addresses, "Addresses should be found")
            XCTAssertEqual(addresses!.count, 1, "Only one address should be found")
            expectation.fulfill()
        }
        waitForExpectationsWithTimeout(3, handler: nil)
    }
    
}