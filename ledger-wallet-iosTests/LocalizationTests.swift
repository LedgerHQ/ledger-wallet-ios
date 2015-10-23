//
//  LocalizationTests.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 23/10/2015.
//  Copyright © 2015 Ledger. All rights reserved.
//

import Foundation
import XCTest
@testable import ledger_wallet_ios

class LocalizationTests: XCTestCase {
    
    func testLocalizedString() {
        XCTAssertEqual(localizedString("ledger_wallet"), "Ledger Wallet", "Localized string should be equal")
    }
    
    func testUnderscoreString() {
        XCTAssertEqual(localizedString("_ledger_wallet"), "_ledger_wallet", "Localized string should be equal")
    }
    
    func testUnknownString() {
        XCTAssertEqual(localizedString("this_is_a_test"), "this_is_a_test", "Localized string should be equal")
    }
    
}