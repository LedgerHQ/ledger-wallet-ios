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
    
    func testTransactionInfoP2PKHFromNewData() {
        let pairingKey = BTCDataFromHex("9d64062cb0c910e3b628478af5160c3b")
        let message = [
            "second_factor_data": "d3d21cb90198fc4a2fd6c727f95cc868f1a76be8ef8960041c3b0fc5ce8c1a74",
            "output_data": "d957a9808d0936124cee60deafd7a9f8f451ec996eba6fcbdc2c11521ff0a87b211219ed6f745a4180c01fd145dac88c147062fea8dfcbc9abf2580b307a38b7a7b45298e2bc1808",
            "type": "request"
        ]
        
        guard let info = cryptor.transactionInfoFromRequestMessage(message, pairingKey: pairingKey) else {
            XCTFail("It should be possible to build a transaction info")
            return
        }
        
        XCTAssertEqual(info.pinCode, "1036", "PIN should be equal")
        XCTAssertEqual(info.recipientAddress, "1F5Ehb3Qp3MoRVdgFSXtHyvtdrUAw6BnvU", "Addresses should be equal")
        XCTAssertEqual(info.amount, 1000000, "Outputs should be equal")
    }
    
    func testTransactionInfoP2SHFromNewData() {
        let pairingKey = BTCDataFromHex("d4b4ed4617d3dae723f9fc84e884c1b4")
        let message = [
            "second_factor_data": "d96470a6b0264b7d897b4e45d1a426805fd030a0a9b188c6d8d92bced094fabb",
            "output_data": "84a04cc3f91b55eb0c87cee523c4e294d77b0ea54530f20c1775e66e31f22a70aa7f0bd48cbbb29ec76a6c76df20a071a41a6b6464a217e630268d907563c079dc74ed85443d006c",
            "type": "request"
        ]
        
        guard let info = cryptor.transactionInfoFromRequestMessage(message, pairingKey: pairingKey) else {
            XCTFail("It should be possible to build a transaction info")
            return
        }
        
        XCTAssertEqual(info.pinCode, "3030", "PIN should be equal")
        XCTAssertEqual(info.recipientAddress, "3NukJ6fYZJ5Kk8bPjycAnruZkE5Q7UW7i8", "Addresses should be equal")
        XCTAssertEqual(info.amount, 1000000, "Outputs should be equal")
    }

    
    func testTransactionInfoFromLegacyData() {
        let pairingKey = BTCDataFromHex("4d9aeb634c564f2bf921f3f4b2d3d15f")
        let message = ["second_factor_data": "14505a5a01710ecc7ca862561f9dd2b36a1d9802d0ce116646d8c09c1b088683ff4d701f878b7d3f6df3549d84efca6e43b55d547d394f7ebd27d0b278bff294", "type": "request"]
        
        guard let info = cryptor.transactionInfoFromRequestMessage(message, pairingKey: pairingKey) else {
            XCTFail("It should be possible to build a transaction info")
            return
        }
        
        XCTAssertEqual(info.pinCode, "6259", "PIN should be equal")
        XCTAssertEqual(info.recipientAddress, "19cP5NbLu6Rhvzh2FDvh2jGixS12XGATRo", "Addresses should be equal")
        XCTAssertEqual(info.amount, 1000000, "Outputs should be equal")
    }
    
}