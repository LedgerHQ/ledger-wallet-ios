//
//  CoreDataStackedTestCase.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 26/11/2015.
//  Copyright © 2015 Ledger. All rights reserved.
//

import Foundation
import XCTest
@testable import ledger_wallet_ios

class CoreDataStackedTestCase: XCTestCase {
    
    var coreDataStack: CoreDataStack!
    
    override func setUp() {
        super.setUp()
        let expectation = expectationWithDescription("Waiting for Core Data stack to initialize")
        coreDataStack = CoreDataStack(storeType: .Memory, modelName: LedgerCoreDataModelName) { success in
            XCTAssertTrue(success, "Core Data stack should be initialized")
            expectation.fulfill()
        }
        waitForExpectationsWithTimeout(3, handler: nil)
    }
    
    override func tearDown() {
        super.tearDown()
        coreDataStack = nil
    }
    
}