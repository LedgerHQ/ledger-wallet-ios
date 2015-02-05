//
//  CryptoKeyTests.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 05/02/2015.
//  Copyright (c) 2015 Ledger. All rights reserved.
//

import Foundation
import XCTest

class CryptoKeyTests: XCTestCase {
    
    let privateKey = Crypto.Encode.dataFromBase16String("b208b83b23edfff327bb6e0098eeaa0a5c87a599d5d8b24ff2734d2aac8bbdde")
    let publicKey = Crypto.Encode.dataFromBase16String("04ae218d8080c7b9cd141b06f6b9f63ef3adf7aecdf49bb3916ac7f5d887fc4027bea6fd187b9fa810b6d251e1430f6555edd2d5b19828d51908917c03e3f7c436")
    
    func testIsSymmetric() {
        let key = Crypto.Key(symmetricKey: NSData(bytes: "hello", length: 5))
        XCTAssertTrue(key.isSymmetric, "key should be symmetric")
        XCTAssertFalse(key.isAsymmetric, "key should not be asymmetric")
    }
    
    func testIsAsymmetric() {
        let key = Crypto.Key()
        XCTAssertFalse(key.isSymmetric, "key should not be symmetric")
        XCTAssertTrue(key.isAsymmetric, "key should be asymmetric")
    }
    
    func testSymmetricKeyDataEqual() {
        let key = Crypto.Key(symmetricKey: publicKey)
        XCTAssertEqual(publicKey, key.symmetricKey, "symmetric key data should be equal")
    }
    
    func testPrivateKeyDataEqual() {
        let key = Crypto.Key(privateKey: privateKey)
        XCTAssertEqual(privateKey, key.privateKey, "private key data should be equal")
        XCTAssertEqual(publicKey, key.publicKey, "public key data should be equal")
    }
    
    func testPublicKeyDataEqual() {
        let key = Crypto.Key(publicKey: publicKey)
        XCTAssertEqual(publicKey, key.publicKey, "public key data should be equal")
        XCTAssertEqual(NSData(), key.privateKey, "private key data should be empty")
    }
    
    func testPublicPrivateKeyDataEqual() {
        let key = Crypto.Key(publicKey: publicKey, privateKey: privateKey)
        XCTAssertEqual(publicKey, key.publicKey, "public key data should be equal")
        XCTAssertEqual(privateKey, key.privateKey, "private key data should be equal")
    }
    
    func testNewKeyPair() {
        let key = Crypto.Key()
        XCTAssertNotEqual(NSData(), key.publicKey, "private key data should not be empty")
        XCTAssertNotEqual(NSData(), key.privateKey, "private key data should not be empty")
    }
    
}
