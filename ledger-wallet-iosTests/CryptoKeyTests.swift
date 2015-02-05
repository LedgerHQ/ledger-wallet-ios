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
    
    let otherPrivateKey = Crypto.Encode.dataFromBase16String("2107cb67d49337fb9cf5e1585a308a72ba5aa17c6255010a01354f526b4e81cd")
    let otherPublicKey = Crypto.Encode.dataFromBase16String("040d1f94315fd489bbc233b75c69496d8f4aebcedfabb1937c312389750c9f096cd7a8bf42345800beeeb719bfb1c4b96ad57cd20aa22d33dfa59d3b4578aa9da2")
    
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
        XCTAssertEqual(publicKey.length, key.symmetricKey.length, "symmetric key size should be the same")
    }
    
    func testPrivateKeyDataEqual() {
        let key = Crypto.Key(privateKey: privateKey)
        XCTAssertEqual(privateKey, key.privateKey, "private key data should be equal")
        XCTAssertEqual(publicKey, key.publicKey, "public key data should be equal")
        XCTAssertEqual(key.privateKey.length, 32, "private key size should be 32")
    }
    
    func testPublicKeyDataEqual() {
        let key = Crypto.Key(publicKey: publicKey)
        XCTAssertEqual(publicKey, key.publicKey, "public key data should be equal")
        XCTAssertEqual(NSData(), key.privateKey, "private key data should be empty")
        XCTAssertEqual(key.publicKey.length, 65, "private key size should be 65")
    }
    
    func testNewKeyPair() {
        let key = Crypto.Key()
        XCTAssertNotEqual(NSData(), key.publicKey, "private key data should not be empty")
        XCTAssertNotEqual(NSData(), key.privateKey, "private key data should not be empty")
        XCTAssertEqual(key.publicKey.length, 65, "private key size should be 65")
        XCTAssertEqual(key.privateKey.length, 32, "private key size should be 32")
    }
    
    func testGivenPrivateKey1() {
        let key = Crypto.Key(privateKey: privateKey)
        XCTAssertEqual(publicKey, key.publicKey, "public key data should empty equal")
    }
    
    func testGivenPrivateKey2() {
        let key = Crypto.Key(privateKey: otherPrivateKey)
        XCTAssertEqual(otherPublicKey, key.publicKey, "public key data should empty equal")
    }
    
}
