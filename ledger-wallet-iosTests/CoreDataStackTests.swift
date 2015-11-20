//
//  CoreDataStackTests.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 19/11/2015.
//  Copyright © 2015 Ledger. All rights reserved.
//

import Foundation
import XCTest
@testable import ledger_wallet_ios

class CoreDataStackTests: XCTestCase {
    
    private var coreDataStack: CoreDataStack!
    
    override func setUp() {
        super.setUp()
        let expectation = expectationWithDescription("Waiting for stack to initialize")
        coreDataStack = CoreDataStack(storeType: .Memory, modelName: LedgerCoreDataModelName) { success in
            XCTAssertTrue(success, "Stack should be initialized")
            expectation.fulfill()
        }
        waitForExpectationsWithTimeout(5, handler: nil)
    }
    
    override func tearDown() {
        super.tearDown()
        coreDataStack = nil
    }

    func testPerformBlockNotNil() {
        let expectation = expectationWithDescription("Waiting for block to execute")
        coreDataStack.performBlock() { context in
            expectation.fulfill()
        }
        waitForExpectationsWithTimeout(5, handler: nil)
    }
    
}