//
//  PairingTransactionsCryptorTests.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 26/10/2015.
//  Copyright © 2015 Ledger. All rights reserved.
//

import Foundation
import XCTest
@testable import ledger_wallet_ios

class PairingTransactionsCryptorTests: XCTestCase {
    
    var cryptor: PairingTransactionsCryptor! = nil
    
    override func setUp() {
        super.setUp()
        
        cryptor = PairingTransactionsCryptor()
    }
    
    func testWrongTransactionMessage() {
        let pairingKey = BTCDataFromHex("4d9aeb634c564f2bf921f3f4b2d3d15f")
        XCTAssertNil(cryptor.transactionInfoFromRequestMessage([:], pairingKey: pairingKey), "It should not be possible to build a transaction info")
    }
    
    func testWrongPairingKey() {
        let message = ["second_factor_data": "14505a5a01710ecc7ca862561f9dd2b36a1d9802d0ce116646d8c09c1b088683ff4d701f878b7d3f6df3549d84efca6e43b55d547d394f7ebd27d0b278bff294", "type": "request"]
        XCTAssertNil(cryptor.transactionInfoFromRequestMessage(message, pairingKey: NSData()), "It should not be possible to build a transaction info")
    }
    
    func testTransactionInfoFromNewData() {
        XCTFail()
    }
    
    func testTransactionInfoFromLegacyData() {
        let pairingKey = BTCDataFromHex("4d9aeb634c564f2bf921f3f4b2d3d15f")
        let message = ["second_factor_data": "14505a5a01710ecc7ca862561f9dd2b36a1d9802d0ce116646d8c09c1b088683ff4d701f878b7d3f6df3549d84efca6e43b55d547d394f7ebd27d0b278bff294", "type": "request"]
        
        guard let info = cryptor.transactionInfoFromRequestMessage(message, pairingKey: pairingKey) else {
            XCTAssertNotNil(cryptor, "It should be possible to build a transaction info")
            return
        }
        XCTAssertEqual(info.pinCode, "6259", "PIN should be equal")
        XCTAssertEqual(info.recipientAddress, "19cP5NbLu6Rhvzh2FDvh2jGixS12XGATRo", "Addresses should be equal")
        XCTAssertEqual(info.outputsAmount, 1000000, "Outputs should be equal")
        XCTAssertEqual(info.changeAmount, 89600, "Changes should be equal")
        XCTAssertEqual(info.feesAmount, 10400, "Fees should be equal")
    }
    
}