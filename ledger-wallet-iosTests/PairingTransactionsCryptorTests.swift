//
//  PairingTransactionsCryptorTest.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 09/02/2015.
//  Copyright (c) 2015 Ledger. All rights reserved.
//

import Foundation
import XCTest

class PairingTransactionsCryptorTest: XCTestCase {
    
    func testCrypto1() {
        let cryptor = PairingTransactionsCryptor()
        
        // test empty transaction info
        let info = cryptor.transactionInfoFromEncryptedBlob(NSData(), pairingKey: Crypto.Key(symmetricKey: NSData()))
        XCTAssertNil(info, "transaction info should be nil")
    }
    
}