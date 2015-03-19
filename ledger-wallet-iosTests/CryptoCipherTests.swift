//
//  CryptoCipherTests.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 05/02/2015.
//  Copyright (c) 2015 Ledger. All rights reserved.
//

import Foundation
import XCTest

class CryptoCipherTests: XCTestCase {

    func testTripleDESCBCKeyZero() {
        let key1 = Crypto.Key(symmetricKey: Crypto.Encode.dataFromBase16String("")!)
        let key2 = Crypto.Key(symmetricKey: Crypto.Encode.dataFromBase16String("253a1b793a04e03c")!)
        let key3 = Crypto.Key(symmetricKey: Crypto.Encode.dataFromBase16String("75b8ada16eb5f8ea")!)
        let message = Crypto.Data.dataFromString("what's up")!
        XCTAssertEqual(Crypto.Cipher.tripleDESCBCFromData(message, key1: key1, key2: key2, key3: key3), NSData(), "3DES CDC data should be empty")
    }
    
    func testTripleDESCBCDataZero() {
        let key1 = Crypto.Key(symmetricKey: Crypto.Encode.dataFromBase16String("75b8ada16eb5f8ea")!)
        let key2 = Crypto.Key(symmetricKey: Crypto.Encode.dataFromBase16String("253a1b793a04e03c")!)
        let key3 = Crypto.Key(symmetricKey: Crypto.Encode.dataFromBase16String("75b8ada16eb5f8ea")!)
        let message = Crypto.Data.dataFromString("")!
        XCTAssertEqual(Crypto.Cipher.tripleDESCBCFromData(message, key1: key1, key2: key2, key3: key3), NSData(), "3DES CDC data should be empty")
    }
    
    func testTripleDESCBC() {
        let key1 = Crypto.Key(symmetricKey: Crypto.Encode.dataFromBase16String("75b8ada16eb5f8ea")!)
        let key2 = Crypto.Key(symmetricKey: Crypto.Encode.dataFromBase16String("253a1b793a04e03c")!)
        let key3 = Crypto.Key(symmetricKey: Crypto.Encode.dataFromBase16String("75b8ada16eb5f8ea")!)
        let message = Crypto.Encode.dataFromBase16String("ab5a56a93c1ea864020c000500000000")!
        let expected = Crypto.Encode.dataFromBase16String("844f0cf804cc7a3b8ac235e0872a2779")!
        let crypted = Crypto.Cipher.tripleDESCBCFromData(message, key1: key1, key2: key2, key3: key3)
        XCTAssertEqual(crypted, expected, "3DES CBC crypted data must be equal")
        let decrypted = Crypto.Cipher.dataFromTripleDESCBC(crypted, key1: key1, key2: key2, key3: key3)
        XCTAssertEqual(decrypted, message, "3DES CBC decrypted data must be equal")
    }
    
}