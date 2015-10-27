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
        let message = [
            "second_factor_data": "14505a5a01710ecc7ca862561f9dd2b36a1d9802d0ce116646d8c09c1b088683ff4d701f878b7d3f6df3549d84efca6e43b55d547d394f7ebd27d0b278bff294",
            "type": "request"
        ]
        XCTAssertNil(cryptor.transactionInfoFromRequestMessage(message, pairingKey: NSData()), "It should not be possible to build a transaction info")
    }
    
    func testTransactionInfoFromNewData() {
        let pairingKey = BTCDataFromHex("9d64062cb0c910e3b628478af5160c3b")
        let message = [
            "second_factor_data": "d3d21cb90198fc4a2fd6c727f95cc868f1a76be8ef8960041c3b0fc5ce8c1a74",
            "output_data": "d957a9808d0936124cee60deafd7a9f8f451ec996eba6fcbdc2c11521ff0a87b211219ed6f745a4180c01fd145dac88c147062fea8dfcbc9abf2580b307a38b7a7b45298e2bc1808",
            "type": "request"
        ]
        
        guard let info = cryptor.transactionInfoFromRequestMessage(message, pairingKey: pairingKey) else {
            XCTAssertNotNil(cryptor, "It should be possible to build a transaction info")
            return
        }
        
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