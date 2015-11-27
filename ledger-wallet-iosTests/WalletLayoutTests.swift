//
//  WalletLayoutTests.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 26/11/2015.
//  Copyright © 2015 Ledger. All rights reserved.
//

import Foundation
import XCTest
@testable import ledger_wallet_ios

class WalletLayoutTests: CoreDataStackedTestCase {
    
    override func setUp() {
        super.setUp()
        
        coreDataStack.performBlockAndWait() { context in
            // add wallet
            let wallet = WalletEntity.insertInContext(context)
            wallet.identifier = "main-account"
        
            // add accounts
            let account0 = AccountEntity.insertInContext(context)
            account0.wallet = wallet
        
        }
        coreDataStack.saveAndWait(true)
    }
    
    func test() {
        
    }
    
}