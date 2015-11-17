//
//  AttestationKeyTests.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 16/11/2015.
//  Copyright © 2015 Ledger. All rights reserved.
//

import Foundation
import XCTest
@testable import ledger_wallet_ios

class AttestationKeyTests: XCTestCase {
    
    func testFetchWrongKey() {
        XCTAssertNil(AttestationKey.fetchFromIDs(batchID: 0x00, derivationID: 0x00), "Attestation key should be nil")
    }
    
    func testFetchRightKey() {
        XCTAssertNotNil(AttestationKey.fetchFromIDs(batchID: 0x00, derivationID: 0x01), "Attestation key shouldn't be nil")
    }
    
    func testCompareKeys() {
        let key1 = AttestationKey.fetchFromIDs(batchID: 0x00, derivationID: 0x01)
        let key2 = AttestationKey.fetchFromIDs(batchID: 0x00, derivationID: 0x01)
        XCTAssertEqual(key1, key2, "Attestation keys should be equal")
    }
    
}
